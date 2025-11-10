#!/bin/bash

##############################################################################
# Azure AD OIDC Configuration Script
# 
# This script guides users through configuring OIDC SSO with Azure AD.
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
    print_header "Azure AD OIDC Configuration"
    
    echo "Please provide the following information:"
    echo ""
    
    read -p "Tenant ID (e.g., xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx): " tenant_id
    read -p "Redirect URI (e.g., https://example.com/oauth/callback): " redirect_uri
    read -p "Post Logout Redirect URI (optional): " logout_uri
    
    export TENANT_ID="$tenant_id"
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
  "provider": "azure-ad",
  "protocol": "oidc",
  "tenant_id": "$TENANT_ID",
  "issuer": "https://login.microsoftonline.com/$TENANT_ID/v2.0",
  "authorization_endpoint": "https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/authorize",
  "token_endpoint": "https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token",
  "userinfo_endpoint": "https://graph.microsoft.com/oidc/userinfo",
  "jwks_uri": "https://login.microsoftonline.com/$TENANT_ID/discovery/v2.0/keys",
  "end_session_endpoint": "https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/logout",
  "redirect_uri": "$REDIRECT_URI",
  "post_logout_redirect_uri": "$LOGOUT_URI",
  "scope": "openid profile email",
  "response_type": "code",
  "response_mode": "query",
  "grant_type": "authorization_code",
  "application_id": "YOUR_APPLICATION_ID",
  "client_secret": "YOUR_CLIENT_SECRET"
}
EOF

    print_success "Configuration file created: $config_file"
}

display_instructions() {
    local output_dir=$1
    
    print_header "Next Steps: Configure Azure AD OIDC"
    
    cat <<EOF
Follow these steps in Azure Portal:

1. Log in to Azure Portal
   - Navigate to: https://portal.azure.com

2. Register Application
   - Go to Azure Active Directory > App registrations
   - Click "New registration"
   - Name: Your Application Name
   - Supported account types: (Choose appropriate option)
   - Redirect URI: 
     * Platform: Web
     * URI: $REDIRECT_URI
   - Click "Register"

3. Note Application Details
   - Copy the Application (client) ID
   - Copy the Directory (tenant) ID
   
4. Create Client Secret
   - Go to "Certificates & secrets"
   - Click "New client secret"
   - Description: Your secret description
   - Expires: (Choose appropriate duration)
   - Click "Add"
   - Copy the secret VALUE (not the ID)
   - Store it securely - you won't be able to see it again!

5. Configure API Permissions
   - Go to "API permissions"
   - Click "Add a permission"
   - Select "Microsoft Graph"
   - Select "Delegated permissions"
   - Add these permissions:
     * openid
     * profile
     * email
     * User.Read
   - Click "Add permissions"
   - (Optional) Click "Grant admin consent" if you have admin rights

6. Configure Authentication
   - Go to "Authentication"
   - Under "Platform configurations" > "Web"
   - Verify Redirect URI: $REDIRECT_URI
$([ -n "$LOGOUT_URI" ] && echo "   - Add Logout URL: $LOGOUT_URI")
   - Under "Implicit grant and hybrid flows"
     * Check "ID tokens" if needed for your flow
   - Click "Save"

7. Update Configuration File
   - Edit: $output_dir/oidc-config.json
   - Replace YOUR_APPLICATION_ID with your Application (client) ID
   - Replace YOUR_CLIENT_SECRET with your client secret

8. Assign Users (if needed)
   - Go to "Enterprise applications"
   - Find your application
   - Go to "Users and groups"
   - Add users or groups who should have access

9. Test the Integration
   - Use the authorization endpoint to initiate login
   - Verify token exchange works correctly
   - Or run: ./scripts/test-connection.sh --provider azure-ad --protocol oidc

Generated files:
  - Configuration: $output_dir/oidc-config.json

OIDC Endpoints:
  - Issuer: https://login.microsoftonline.com/$TENANT_ID/v2.0
  - Authorization: https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/authorize
  - Token: https://login.microsoftonline.com/$TENANT_ID/oauth2/v2.0/token
  - UserInfo: https://graph.microsoft.com/oidc/userinfo
  - JWKS: https://login.microsoftonline.com/$TENANT_ID/discovery/v2.0/keys

Discovery Document:
  - https://login.microsoftonline.com/$TENANT_ID/v2.0/.well-known/openid-configuration

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
    create_oidc_config "$output_dir"
    
    # Display instructions
    display_instructions "$output_dir"
    
    print_header "Configuration Complete"
    print_success "Azure AD OIDC configuration files have been generated"
    print_warning "Remember to update the application_id and client_secret in the config file!"
}

main "$@"
