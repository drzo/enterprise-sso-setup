#!/bin/bash

##############################################################################
# Azure AD SAML Configuration Script
# 
# This script guides users through configuring SAML SSO with Azure AD.
##############################################################################

set -e

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

gather_azure_info() {
    print_header "Azure AD SAML Configuration"
    
    echo "Please provide the following information:"
    echo ""
    
    read -p "Tenant ID or Domain (e.g., contoso.onmicrosoft.com): " tenant_id
    read -p "Entity ID (e.g., https://example.com/saml/metadata): " entity_id
    read -p "Reply URL (ACS) (e.g., https://example.com/saml/acs): " reply_url
    read -p "Logout URL (optional): " logout_url
    
    export TENANT_ID="$tenant_id"
    export ENTITY_ID="$entity_id"
    export REPLY_URL="$reply_url"
    export LOGOUT_URL="$logout_url"
    
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
            Location="$REPLY_URL"
            index="0"
            isDefault="true"/>
EOF

    if [ -n "$LOGOUT_URL" ]; then
        cat >> "$metadata_file" <<EOF
        
        <md:SingleLogoutService
            Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
            Location="$LOGOUT_URL"/>
EOF
    fi

    cat >> "$metadata_file" <<EOF
    </md:SPSSODescriptor>
</md:EntityDescriptor>
EOF

    print_success "Service Provider metadata generated: $metadata_file"
}

create_azure_config() {
    local output_dir=$1
    
    print_info "Creating Azure AD configuration file"
    
    local config_file="$output_dir/azure-saml-config.json"
    
    cat > "$config_file" <<EOF
{
  "provider": "azure-ad",
  "protocol": "saml",
  "tenant_id": "$TENANT_ID",
  "entity_id": "$ENTITY_ID",
  "reply_url": "$REPLY_URL",
  "logout_url": "$LOGOUT_URL",
  "idp_metadata_url": "https://login.microsoftonline.com/$TENANT_ID/federationmetadata/2007-06/federationmetadata.xml",
  "attribute_mapping": {
    "email": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
    "firstName": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname",
    "lastName": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname",
    "displayName": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
  }
}
EOF

    print_success "Configuration file created: $config_file"
}

display_instructions() {
    local output_dir=$1
    
    print_header "Next Steps: Configure Azure AD"
    
    cat <<EOF
Follow these steps in Azure Portal:

1. Log in to Azure Portal
   - Navigate to: https://portal.azure.com

2. Create Enterprise Application
   - Go to Azure Active Directory > Enterprise applications
   - Click "New application"
   - Click "Create your own application"
   - Name: Your Application Name
   - Select "Integrate any other application you don't find in the gallery (Non-gallery)"
   - Click "Create"

3. Set up Single Sign-On
   - In your application, go to "Single sign-on"
   - Select "SAML"

4. Basic SAML Configuration
   - Click "Edit" on Basic SAML Configuration
   - Identifier (Entity ID): $ENTITY_ID
   - Reply URL (Assertion Consumer Service URL): $REPLY_URL
$([ -n "$LOGOUT_URL" ] && echo "   - Logout URL: $LOGOUT_URL")
   - Click "Save"

5. User Attributes & Claims (optional but recommended)
   - Click "Edit" on Attributes & Claims
   - Verify these claims are configured:
     * emailaddress
     * givenname
     * surname
     * name

6. SAML Signing Certificate
   - In SAML Signing Certificate section
   - Download "Federation Metadata XML"
   - Save as: $output_dir/idp-metadata.xml

7. Assign Users and Groups
   - Go to "Users and groups"
   - Click "Add user/group"
   - Select users or groups who should have access
   - Click "Assign"

8. Test Single Sign-On
   - Go back to "Single sign-on"
   - Click "Test" at the bottom
   - Or run: ./scripts/test-connection.sh --provider azure-ad --protocol saml

Generated files:
  - Service Provider Metadata: $output_dir/sp-metadata.xml
  - Configuration: $output_dir/azure-saml-config.json

IdP Metadata URL:
  - https://login.microsoftonline.com/$TENANT_ID/federationmetadata/2007-06/federationmetadata.xml

For troubleshooting, see: docs/troubleshooting.md
EOF
}

main() {
    # Gather information
    gather_azure_info
    
    # Create output directory
    local output_dir="./output/azure-ad"
    mkdir -p "$output_dir"
    
    # Generate files
    generate_sp_metadata "$output_dir"
    create_azure_config "$output_dir"
    
    # Display instructions
    display_instructions "$output_dir"
    
    print_header "Configuration Complete"
    print_success "Azure AD SAML configuration files have been generated"
}

main "$@"
