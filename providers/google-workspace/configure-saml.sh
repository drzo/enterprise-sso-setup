#!/bin/bash

##############################################################################
# Google Workspace SAML Configuration Script
##############################################################################

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_header() { echo ""; echo -e "${BLUE}========================================${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}========================================${NC}"; echo ""; }

gather_info() {
    print_header "Google Workspace SAML Configuration"
    echo "Please provide the following information:"; echo ""
    read -p "Google Workspace Domain (e.g., example.com): " domain
    read -p "Entity ID (e.g., https://example.com/saml/metadata): " entity_id
    read -p "ACS URL (e.g., https://example.com/saml/acs): " acs_url
    export DOMAIN="$domain"; export ENTITY_ID="$entity_id"; export ACS_URL="$acs_url"
    print_success "Information gathered"
}

generate_sp_metadata() {
    local output_dir=$1
    print_info "Generating Service Provider metadata"
    mkdir -p "$output_dir"
    cat > "$output_dir/sp-metadata.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" entityID="$ENTITY_ID">
    <md:SPSSODescriptor AuthnRequestsSigned="false" WantAssertionsSigned="true" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
        <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="$ACS_URL" index="0" isDefault="true"/>
    </md:SPSSODescriptor>
</md:EntityDescriptor>
EOF
    print_success "Service Provider metadata generated: $output_dir/sp-metadata.xml"
}

create_config() {
    local output_dir=$1
    print_info "Creating Google Workspace configuration file"
    cat > "$output_dir/google-saml-config.json" <<EOF
{
  "provider": "google-workspace",
  "protocol": "saml",
  "domain": "$DOMAIN",
  "entity_id": "$ENTITY_ID",
  "acs_url": "$ACS_URL",
  "idp_entity_id": "https://accounts.google.com/o/saml2?idpid=YOUR_IDP_ID",
  "idp_sso_url": "https://accounts.google.com/o/saml2/idp?idpid=YOUR_IDP_ID",
  "attribute_mapping": {
    "email": "email",
    "firstName": "firstName",
    "lastName": "lastName"
  }
}
EOF
    print_success "Configuration file created: $output_dir/google-saml-config.json"
}

display_instructions() {
    local output_dir=$1
    print_header "Next Steps: Configure Google Workspace"
    cat <<EOF
Follow these steps in Google Admin Console:

1. Log in to Google Admin Console
   - Navigate to: https://admin.google.com

2. Set up Custom SAML Application
   - Go to Apps > Web and mobile apps
   - Click "Add app" > "Add custom SAML app"
   - App name: Your Application Name
   - Click "Continue"

3. Google Identity Provider Details
   - Download the IDP metadata (click "Download Metadata")
   - Save as: $output_dir/idp-metadata.xml
   - Note the SSO URL and Entity ID
   - Click "Continue"

4. Service Provider Details
   - ACS URL: $ACS_URL
   - Entity ID: $ENTITY_ID
   - Start URL: (Your application's start URL)
   - Name ID format: EMAIL
   - Name ID: Basic Information > Primary email
   - Click "Continue"

5. Attribute Mapping (optional)
   Add these mappings:
   - email -> Primary email
   - firstName -> First name
   - lastName -> Last name
   - Click "Finish"

6. Turn on the App
   - Find your app in the list
   - Click on it
   - Click "User access"
   - Select "ON for everyone" or specific OUs
   - Click "Save"

7. Test the Integration
   - Run: ./scripts/test-connection.sh --provider google-workspace --protocol saml

Generated files:
  - Service Provider Metadata: $output_dir/sp-metadata.xml
  - Configuration: $output_dir/google-saml-config.json

For troubleshooting, see: docs/troubleshooting.md
EOF
}

main() {
    gather_info
    local output_dir="./output/google-workspace"
    mkdir -p "$output_dir"
    generate_sp_metadata "$output_dir"
    create_config "$output_dir"
    display_instructions "$output_dir"
    print_header "Configuration Complete"
    print_success "Google Workspace SAML configuration files have been generated"
}

main "$@"
