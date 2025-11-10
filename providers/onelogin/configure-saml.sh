#!/bin/bash

##############################################################################
# OneLogin SAML Configuration Script
##############################################################################

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_header() { echo ""; echo -e "${BLUE}========================================${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}========================================${NC}"; echo ""; }

gather_info() {
    print_header "OneLogin SAML Configuration"
    echo "Please provide the following information:"; echo ""
    read -p "OneLogin Subdomain (e.g., yourcompany.onelogin.com): " subdomain
    read -p "Entity ID (e.g., https://example.com/saml/metadata): " entity_id
    read -p "ACS URL (e.g., https://example.com/saml/acs): " acs_url
    read -p "Single Logout URL (optional): " slo_url
    export SUBDOMAIN="$subdomain"; export ENTITY_ID="$entity_id"; export ACS_URL="$acs_url"; export SLO_URL="$slo_url"
    print_success "Information gathered"
}

generate_sp_metadata() {
    local output_dir=$1
    print_info "Generating Service Provider metadata"
    mkdir -p "$output_dir"
    cat > "$output_dir/sp-metadata.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" entityID="$ENTITY_ID">
    <md:SPSSODescriptor AuthnRequestsSigned="true" WantAssertionsSigned="true" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
        <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
        <md:AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="$ACS_URL" index="0" isDefault="true"/>
$([ -n "$SLO_URL" ] && echo "        <md:SingleLogoutService Binding=\"urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect\" Location=\"$SLO_URL\"/>")
    </md:SPSSODescriptor>
</md:EntityDescriptor>
EOF
    print_success "Service Provider metadata generated: $output_dir/sp-metadata.xml"
}

create_config() {
    local output_dir=$1
    print_info "Creating OneLogin configuration file"
    cat > "$output_dir/onelogin-saml-config.json" <<EOF
{
  "provider": "onelogin",
  "protocol": "saml",
  "subdomain": "$SUBDOMAIN",
  "entity_id": "$ENTITY_ID",
  "acs_url": "$ACS_URL",
  "slo_url": "$SLO_URL",
  "idp_issuer": "https://app.onelogin.com/saml/metadata/YOUR_APP_ID",
  "idp_sso_url": "https://$SUBDOMAIN/trust/saml2/http-post/sso/YOUR_APP_ID",
  "attribute_mapping": {
    "email": "User.email",
    "firstName": "User.FirstName",
    "lastName": "User.LastName"
  }
}
EOF
    print_success "Configuration file created: $output_dir/onelogin-saml-config.json"
}

display_instructions() {
    local output_dir=$1
    print_header "Next Steps: Configure OneLogin"
    cat <<EOF
Follow these steps in OneLogin Admin Portal:

1. Log in to OneLogin Admin Portal
   - Navigate to: https://$SUBDOMAIN/admin

2. Create SAML Application
   - Go to Applications > Applications
   - Click "Add App"
   - Search for "SAML Custom Connector (Advanced)"
   - Select it and click "Save"

3. Configure Application
   - Display Name: Your Application Name
   - Click "Save"

4. Configure SSO Settings
   - Go to "Configuration" tab
   - Audience (EntityID): $ENTITY_ID
   - Recipient: $ACS_URL
   - ACS (Consumer) URL Validator: $ACS_URL
   - ACS (Consumer) URL: $ACS_URL
$([ -n "$SLO_URL" ] && echo "   - Single Logout URL: $SLO_URL")
   - SAML signature element: Response
   - Click "Save"

5. Configure Parameters (Attributes)
   - Go to "Parameters" tab
   - Add field mappings:
     * email -> Email
     * firstName -> First Name
     * lastName -> Last Name
   - Click "Save"

6. Download Metadata
   - Go to "SSO" tab
   - Under "Issuer URL", click "View Details"
   - Download the X.509 certificate or metadata XML
   - Or use: https://app.onelogin.com/saml/metadata/YOUR_APP_ID
   - Save as: $output_dir/idp-metadata.xml

7. Assign Users
   - Go to "Access" tab
   - Add roles or users who should have access
   - Click "Save"

8. Test the Integration
   - Go to "SSO" tab
   - Use the test feature
   - Or run: ./scripts/test-connection.sh --provider onelogin --protocol saml

Generated files:
  - Service Provider Metadata: $output_dir/sp-metadata.xml
  - Configuration: $output_dir/onelogin-saml-config.json

For troubleshooting, see: docs/troubleshooting.md
EOF
}

main() {
    gather_info
    local output_dir="./output/onelogin"
    mkdir -p "$output_dir"
    generate_sp_metadata "$output_dir"
    create_config "$output_dir"
    display_instructions "$output_dir"
    print_header "Configuration Complete"
    print_success "OneLogin SAML configuration files have been generated"
}

main "$@"
