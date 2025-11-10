#!/bin/bash

##############################################################################
# Okta OIDC Configuration Script
# 
# This script guides users through configuring OIDC SSO with Okta.
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

gather_okta_info() {
    print_header "Okta OIDC Configuration"
    
    echo "Please provide the following information:"
    echo ""
    
    read -p "Okta Domain (e.g., dev-123456.okta.com): " okta_domain
    read -p "Redirect URI (e.g., https://example.com/oauth/callback): " redirect_uri
    read -p "Post Logout Redirect URI (optional): " logout_uri
    
    export OKTA_DOMAIN="$okta_domain"
    export REDIRECT_URI="$redirect_uri"
    export LOGOUT_URI="$logout_uri"
    
    print_success "Information gathered"
}

create_oidc_config() {
    local output_dir=$1
    
    print_info "Creating OIDC configuration file"
    
    mkdir -p "$output_dir"
    
    local config_file="$output_dir/oidc-config.json"
    
    cat > "$config_file" <<EOF
{
  "provider": "okta",
  "protocol": "oidc",
  "issuer": "https://$OKTA_DOMAIN",
  "authorization_endpoint": "https://$OKTA_DOMAIN/oauth2/v1/authorize",
  "token_endpoint": "https://$OKTA_DOMAIN/oauth2/v1/token",
  "userinfo_endpoint": "https://$OKTA_DOMAIN/oauth2/v1/userinfo",
  "jwks_uri": "https://$OKTA_DOMAIN/oauth2/v1/keys",
  "redirect_uri": "$REDIRECT_URI",
  "post_logout_redirect_uri": "$LOGOUT_URI",
  "scope": "openid profile email",
  "response_type": "code",
  "grant_type": "authorization_code",
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_CLIENT_SECRET"
}
EOF

    print_success "Configuration file created: $config_file"
}

display_instructions() {
    local output_dir=$1
    
    print_header "Next Steps: Configure Okta OIDC"
    
    cat <<EOF
Follow these steps in your Okta Admin Console:

1. Log in to Okta Admin Console
   - Navigate to: https://$OKTA_DOMAIN/admin

2. Create OIDC Application
   - Go to Applications > Applications
   - Click "Create App Integration"
   - Select "OIDC - OpenID Connect"
   - Select "Web Application"
   - Click "Next"

3. Configure Application Settings
   - App integration name: Your Application Name
   - Grant type: Authorization Code
   - Sign-in redirect URIs: $REDIRECT_URI
$([ -n "$LOGOUT_URI" ] && echo "   - Sign-out redirect URIs: $LOGOUT_URI")
   - Controlled access: (Choose appropriate option)

4. Save and Get Credentials
   - Click "Save"
   - Copy the Client ID
   - Copy the Client Secret (click to reveal)
   
5. Update Configuration File
   - Edit: $output_dir/oidc-config.json
   - Replace YOUR_CLIENT_ID with your actual Client ID
   - Replace YOUR_CLIENT_SECRET with your actual Client Secret

6. Configure Trusted Origins (if needed)
   - Go to Security > API > Trusted Origins
   - Add your application's origin URL
   - Enable CORS and Redirect

7. Assign Users/Groups
   - Go to your application's "Assignments" tab
   - Assign users or groups who should have access

8. Test the Integration
   - Use the authorization endpoint to initiate login
   - Verify token exchange works correctly
   - Or run: ./scripts/test-connection.sh --provider okta --protocol oidc

Generated files:
  - Configuration: $output_dir/oidc-config.json

OIDC Endpoints:
  - Issuer: https://$OKTA_DOMAIN
  - Authorization: https://$OKTA_DOMAIN/oauth2/v1/authorize
  - Token: https://$OKTA_DOMAIN/oauth2/v1/token
  - UserInfo: https://$OKTA_DOMAIN/oauth2/v1/userinfo
  - JWKS: https://$OKTA_DOMAIN/oauth2/v1/keys

Discovery Document:
  - https://$OKTA_DOMAIN/.well-known/openid-configuration

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
    create_oidc_config "$output_dir"
    
    # Display instructions
    display_instructions "$output_dir"
    
    print_header "Configuration Complete"
    print_success "Okta OIDC configuration files have been generated"
    print_warning "Remember to update the client_id and client_secret in the config file!"
}

main "$@"
