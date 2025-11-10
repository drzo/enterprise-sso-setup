#!/bin/bash

##############################################################################
# Okta SAML Configuration Script
# 
# This script guides users through configuring SAML SSO with Okta.
##############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/common.sh" 2>/dev/null || true

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

gather_okta_info() {
    print_header "Okta SAML Configuration"
    
    echo "Please provide the following information:"
    echo ""
    
    read -p "Okta Domain (e.g., dev-123456.okta.com): " okta_domain
    read -p "Entity ID (e.g., https://example.com/saml/metadata): " entity_id
    read -p "ACS URL (e.g., https://example.com/saml/acs): " acs_url
    read -p "Single Logout URL (optional): " slo_url
    
    export OKTA_DOMAIN="$okta_domain"
    export ENTITY_ID="$entity_id"
    export ACS_URL="$acs_url"
    export SLO_URL="$slo_url"
    
    print_success "Information gathered"
}

generate_sp_metadata() {
    local output_dir=$1
    
    print_info "Generating Service Provider metadata"
    
    mkdir -p "$output_dir"
    
    local metadata_file="$output_dir/sp-metadata.xml"
    
    cat > "$metadata_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
                     entityID="$ENTITY_ID">
    <md:SPSSODescriptor
        AuthnRequestsSigned="true"
        WantAssertionsSigned="true"
        protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        
        <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
        
        <md:AssertionConsumerService
            Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
            Location="$ACS_URL"
            index="0"
            isDefault="true"/>
EOF

    if [ -n "$SLO_URL" ]; then
        cat >> "$metadata_file" <<EOF
        
        <md:SingleLogoutService
            Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
            Location="$SLO_URL"/>
EOF
    fi

    cat >> "$metadata_file" <<EOF
    </md:SPSSODescriptor>
</md:EntityDescriptor>
EOF

    print_success "Service Provider metadata generated: $metadata_file"
}

create_okta_config() {
    local output_dir=$1
    
    print_info "Creating Okta configuration file"
    
    local config_file="$output_dir/okta-saml-config.json"
    
    cat > "$config_file" <<EOF
{
  "provider": "okta",
  "protocol": "saml",
  "okta_domain": "$OKTA_DOMAIN",
  "entity_id": "$ENTITY_ID",
  "acs_url": "$ACS_URL",
  "slo_url": "$SLO_URL",
  "idp_metadata_url": "https://$OKTA_DOMAIN/app/exk.../sso/saml/metadata",
  "attribute_mapping": {
    "email": "user.email",
    "firstName": "user.firstName",
    "lastName": "user.lastName",
    "displayName": "user.displayName"
  }
}
EOF

    print_success "Configuration file created: $config_file"
}

display_instructions() {
    local output_dir=$1
    
    print_header "Next Steps: Configure Okta"
    
    cat <<EOF
Follow these steps in your Okta Admin Console:

1. Log in to Okta Admin Console
   - Navigate to: https://$OKTA_DOMAIN/admin

2. Create SAML Application
   - Go to Applications > Applications
   - Click "Create App Integration"
   - Select "SAML 2.0"
   - Click "Next"

3. Configure General Settings
   - App Name: Your Application Name
   - App Logo: (optional)
   - Click "Next"

4. Configure SAML Settings
   - Single Sign On URL: $ACS_URL
   - Audience URI (SP Entity ID): $ENTITY_ID
   - Name ID format: EmailAddress
   - Application username: Email
$([ -n "$SLO_URL" ] && echo "   - Single Logout URL: $SLO_URL")

5. Attribute Statements (optional but recommended)
   Add these attribute mappings:
   - email -> user.email
   - firstName -> user.firstName
   - lastName -> user.lastName
   - displayName -> user.displayName

6. Click "Next" and then "Finish"

7. Download IdP Metadata
   - On the application settings page, go to "Sign On" tab
   - Under "SAML Signing Certificates", click "Actions" > "View IdP metadata"
   - Save the XML metadata file as: $output_dir/idp-metadata.xml

8. Assign Users/Groups
   - Go to "Assignments" tab
   - Assign users or groups who should have access

9. Test the Integration
   - Use the test user feature in Okta
   - Or run: ./scripts/test-connection.sh --provider okta --protocol saml

Generated files:
  - Service Provider Metadata: $output_dir/sp-metadata.xml
  - Configuration: $output_dir/okta-saml-config.json

For troubleshooting, see: docs/troubleshooting.md
EOF
}

main() {
    # Gather information
    gather_okta_info
    
    # Create output directory
    local output_dir="./output/okta"
    mkdir -p "$output_dir"
    
    # Generate files
    generate_sp_metadata "$output_dir"
    create_okta_config "$output_dir"
    
    # Display instructions
    display_instructions "$output_dir"
    
    print_header "Configuration Complete"
    print_success "Okta SAML configuration files have been generated"
}

main "$@"
