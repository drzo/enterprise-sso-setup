#!/bin/bash

##############################################################################
# Google Workspace OIDC Configuration Script
##############################################################################

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_header() { echo ""; echo -e "${BLUE}========================================${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}========================================${NC}"; echo ""; }

gather_info() {
    print_header "Google Workspace OIDC Configuration"
    echo "Please provide the following information:"; echo ""
    read -p "Redirect URI (e.g., https://example.com/oauth/callback): " redirect_uri
    read -p "Post Logout Redirect URI (optional): " logout_uri
    export REDIRECT_URI="$redirect_uri"; export LOGOUT_URI="$logout_uri"
    print_success "Information gathered"
}

create_config() {
    local output_dir=$1
    print_info "Creating OIDC configuration file"
    mkdir -p "$output_dir"
    cat > "$output_dir/oidc-config.json" <<EOF
{
  "provider": "google-workspace",
  "protocol": "oidc",
  "issuer": "https://accounts.google.com",
  "authorization_endpoint": "https://accounts.google.com/o/oauth2/v2/auth",
  "token_endpoint": "https://oauth2.googleapis.com/token",
  "userinfo_endpoint": "https://openidconnect.googleapis.com/v1/userinfo",
  "jwks_uri": "https://www.googleapis.com/oauth2/v3/certs",
  "redirect_uri": "$REDIRECT_URI",
  "post_logout_redirect_uri": "$LOGOUT_URI",
  "scope": "openid profile email",
  "response_type": "code",
  "grant_type": "authorization_code",
  "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
  "client_secret": "YOUR_CLIENT_SECRET",
  "hosted_domain": "YOUR_DOMAIN.com"
}
EOF
    print_success "Configuration file created: $output_dir/oidc-config.json"
}

display_instructions() {
    local output_dir=$1
    print_header "Next Steps: Configure Google OIDC"
    cat <<EOF
Follow these steps in Google Cloud Console:

1. Log in to Google Cloud Console
   - Navigate to: https://console.cloud.google.com

2. Create or Select Project
   - Create a new project or select existing one
   - Enable Google+ API or Identity Platform

3. Configure OAuth Consent Screen
   - Go to APIs & Services > OAuth consent screen
   - User Type: Internal (for workspace) or External
   - Fill in application information
   - Add scopes: openid, profile, email
   - Save and continue

4. Create OAuth 2.0 Credentials
   - Go to APIs & Services > Credentials
   - Click "Create Credentials" > "OAuth client ID"
   - Application type: Web application
   - Name: Your Application Name
   - Authorized redirect URIs: $REDIRECT_URI
   - Click "Create"

5. Save Credentials
   - Copy the Client ID
   - Copy the Client Secret
   - Store them securely

6. Update Configuration File
   - Edit: $output_dir/oidc-config.json
   - Replace YOUR_CLIENT_ID with your Client ID
   - Replace YOUR_CLIENT_SECRET with your Client Secret
   - Replace YOUR_DOMAIN.com with your workspace domain (optional)

7. Configure Domain Restriction (optional)
   - In your OAuth consent screen settings
   - Add authorized domains
   - Or use hosted_domain parameter in config

8. Test the Integration
   - Use the authorization endpoint to initiate login
   - Run: ./scripts/test-connection.sh --provider google-workspace --protocol oidc

Generated files:
  - Configuration: $output_dir/oidc-config.json

OIDC Endpoints:
  - Issuer: https://accounts.google.com
  - Authorization: https://accounts.google.com/o/oauth2/v2/auth
  - Token: https://oauth2.googleapis.com/token
  - UserInfo: https://openidconnect.googleapis.com/v1/userinfo
  - JWKS: https://www.googleapis.com/oauth2/v3/certs

Discovery Document:
  - https://accounts.google.com/.well-known/openid-configuration

For troubleshooting, see: docs/troubleshooting.md
EOF
}

main() {
    gather_info
    local output_dir="./output/google-workspace"
    mkdir -p "$output_dir"
    create_config "$output_dir"
    display_instructions "$output_dir"
    print_header "Configuration Complete"
    print_success "Google Workspace OIDC configuration files have been generated"
    print_warning "Remember to update the client_id and client_secret in the config file!"
}

main "$@"
