#!/bin/bash

##############################################################################
# OneLogin OIDC Configuration Script
##############################################################################

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_header() { echo ""; echo -e "${BLUE}========================================${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}========================================${NC}"; echo ""; }

gather_info() {
    print_header "OneLogin OIDC Configuration"
    echo "Please provide the following information:"; echo ""
    read -p "OneLogin Subdomain (e.g., yourcompany.onelogin.com): " subdomain
    read -p "Redirect URI (e.g., https://example.com/oauth/callback): " redirect_uri
    read -p "Post Logout Redirect URI (optional): " logout_uri
    export SUBDOMAIN="$subdomain"; export REDIRECT_URI="$redirect_uri"; export LOGOUT_URI="$logout_uri"
    print_success "Information gathered"
}

create_config() {
    local output_dir=$1
    print_info "Creating OIDC configuration file"
    mkdir -p "$output_dir"
    cat > "$output_dir/oidc-config.json" <<EOF
{
  "provider": "onelogin",
  "protocol": "oidc",
  "subdomain": "$SUBDOMAIN",
  "issuer": "https://$SUBDOMAIN/oidc/2",
  "authorization_endpoint": "https://$SUBDOMAIN/oidc/2/auth",
  "token_endpoint": "https://$SUBDOMAIN/oidc/2/token",
  "userinfo_endpoint": "https://$SUBDOMAIN/oidc/2/me",
  "jwks_uri": "https://$SUBDOMAIN/oidc/2/certs",
  "end_session_endpoint": "https://$SUBDOMAIN/oidc/2/logout",
  "redirect_uri": "$REDIRECT_URI",
  "post_logout_redirect_uri": "$LOGOUT_URI",
  "scope": "openid profile email",
  "response_type": "code",
  "grant_type": "authorization_code",
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_CLIENT_SECRET"
}
EOF
    print_success "Configuration file created: $output_dir/oidc-config.json"
}

display_instructions() {
    local output_dir=$1
    print_header "Next Steps: Configure OneLogin OIDC"
    cat <<EOF
Follow these steps in OneLogin Admin Portal:

1. Log in to OneLogin Admin Portal
   - Navigate to: https://$SUBDOMAIN/admin

2. Create OIDC Application
   - Go to Applications > Applications
   - Click "Add App"
   - Search for "OpenId Connect (OIDC)"
   - Select "OpenId Connect (OIDC)" connector
   - Click "Save"

3. Configure Application
   - Display Name: Your Application Name
   - Click "Save"

4. Configure SSO Settings
   - Go to "SSO" tab
   - Application Type: Web
   - Token Endpoint: Authentication Method -> POST
   - Redirect URIs: $REDIRECT_URI
$([ -n "$LOGOUT_URI" ] && echo "   - Logout Redirect URIs: $LOGOUT_URI")
   - Click "Save"

5. Get Client Credentials
   - On the "SSO" tab
   - Copy the Client ID
   - Copy the Client Secret
   - Store them securely

6. Update Configuration File
   - Edit: $output_dir/oidc-config.json
   - Replace YOUR_CLIENT_ID with your Client ID
   - Replace YOUR_CLIENT_SECRET with your Client Secret

7. Configure Scopes (if needed)
   - Still on "SSO" tab
   - Verify scopes include: openid, profile, email

8. Assign Users
   - Go to "Access" tab
   - Add roles or users who should have access
   - Click "Save"

9. Test the Integration
   - Use the authorization endpoint to initiate login
   - Run: ./scripts/test-connection.sh --provider onelogin --protocol oidc

Generated files:
  - Configuration: $output_dir/oidc-config.json

OIDC Endpoints:
  - Issuer: https://$SUBDOMAIN/oidc/2
  - Authorization: https://$SUBDOMAIN/oidc/2/auth
  - Token: https://$SUBDOMAIN/oidc/2/token
  - UserInfo: https://$SUBDOMAIN/oidc/2/me
  - JWKS: https://$SUBDOMAIN/oidc/2/certs

Discovery Document:
  - https://$SUBDOMAIN/oidc/2/.well-known/openid-configuration

For troubleshooting, see: docs/troubleshooting.md
EOF
}

main() {
    gather_info
    local output_dir="./output/onelogin"
    mkdir -p "$output_dir"
    create_config "$output_dir"
    display_instructions "$output_dir"
    print_header "Configuration Complete"
    print_success "OneLogin OIDC configuration files have been generated"
    print_warning "Remember to update the client_id and client_secret in the config file!"
}

main "$@"
