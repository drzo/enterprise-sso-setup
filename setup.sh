#!/bin/bash

##############################################################################
# Enterprise SSO Setup - Main Interactive Wizard
# 
# This script guides users through the process of configuring SAML/OIDC
# single sign-on for enterprise organizations with common IdPs.
##############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

##############################################################################
# Helper Functions
##############################################################################

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_dependencies() {
    print_header "Checking Dependencies"
    
    local missing_deps=()
    
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing_deps+=("curl or wget")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if ! command -v openssl &> /dev/null; then
        missing_deps+=("openssl")
    fi
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        print_success "All dependencies are installed"
        return 0
    else
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install the missing dependencies:"
        echo ""
        echo "  Ubuntu/Debian: sudo apt-get install curl jq openssl"
        echo "  macOS:         brew install curl jq openssl"
        echo "  RHEL/CentOS:   sudo yum install curl jq openssl"
        echo ""
        return 1
    fi
}

select_provider() {
    print_header "Select Identity Provider"
    
    echo "Which Identity Provider are you using?"
    echo ""
    echo "  1) Okta"
    echo "  2) Azure AD (Microsoft Entra ID)"
    echo "  3) Google Workspace"
    echo "  4) OneLogin"
    echo "  5) Exit"
    echo ""
    
    read -p "Enter your choice (1-5): " provider_choice
    
    case $provider_choice in
        1) echo "okta" ;;
        2) echo "azure-ad" ;;
        3) echo "google-workspace" ;;
        4) echo "onelogin" ;;
        5) exit 0 ;;
        *) echo ""; print_error "Invalid choice"; return 1 ;;
    esac
}

select_protocol() {
    print_header "Select Authentication Protocol"
    
    echo "Which authentication protocol do you want to configure?"
    echo ""
    echo "  1) SAML 2.0"
    echo "  2) OIDC (OpenID Connect)"
    echo "  3) Back to provider selection"
    echo ""
    
    read -p "Enter your choice (1-3): " protocol_choice
    
    case $protocol_choice in
        1) echo "saml" ;;
        2) echo "oidc" ;;
        3) echo "back" ;;
        *) echo ""; print_error "Invalid choice"; return 1 ;;
    esac
}

gather_common_info() {
    print_header "Configuration Information"
    
    echo "Please provide the following information:"
    echo ""
    
    read -p "Organization Name: " org_name
    read -p "Base URL (e.g., https://example.com): " base_url
    read -p "Admin Email: " admin_email
    
    # Validate URL format
    if [[ ! $base_url =~ ^https?:// ]]; then
        print_error "Base URL must start with http:// or https://"
        return 1
    fi
    
    export ORG_NAME="$org_name"
    export BASE_URL="$base_url"
    export ADMIN_EMAIL="$admin_email"
    
    print_success "Configuration information gathered"
}

run_provider_configuration() {
    local provider=$1
    local protocol=$2
    
    local script_path="${SCRIPT_DIR}/providers/${provider}/configure-${protocol}.sh"
    
    if [ ! -f "$script_path" ]; then
        print_error "Configuration script not found: $script_path"
        return 1
    fi
    
    print_header "Running ${provider^^} ${protocol^^} Configuration"
    
    # Make script executable
    chmod +x "$script_path"
    
    # Run the configuration script
    if "$script_path"; then
        print_success "Configuration completed successfully"
        return 0
    else
        print_error "Configuration failed"
        return 1
    fi
}

show_next_steps() {
    print_header "Next Steps"
    
    echo "Your SSO configuration has been generated!"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Review the generated configuration files in the output/ directory"
    echo "  2. Complete the setup in your Identity Provider's admin console"
    echo "  3. Test the SSO connection using: ./scripts/test-connection.sh"
    echo "  4. Create your organization using the SSO configuration"
    echo ""
    echo "For detailed instructions, see:"
    echo "  - docs/saml-setup.md (for SAML configuration)"
    echo "  - docs/oidc-setup.md (for OIDC configuration)"
    echo "  - docs/troubleshooting.md (if you encounter issues)"
    echo ""
}

##############################################################################
# Main Script
##############################################################################

main() {
    print_header "Enterprise SSO Setup Wizard"
    
    echo "This wizard will guide you through configuring single sign-on"
    echo "for your enterprise organization."
    echo ""
    
    # Check dependencies
    if ! check_dependencies; then
        exit 1
    fi
    
    # Create output directory
    mkdir -p "${SCRIPT_DIR}/output"
    
    # Main loop
    while true; do
        # Select provider
        provider=$(select_provider)
        if [ $? -ne 0 ]; then
            continue
        fi
        
        # Select protocol
        protocol=$(select_protocol)
        if [ $? -ne 0 ]; then
            continue
        fi
        
        if [ "$protocol" = "back" ]; then
            continue
        fi
        
        # Gather common information
        if ! gather_common_info; then
            continue
        fi
        
        # Run provider-specific configuration
        if run_provider_configuration "$provider" "$protocol"; then
            show_next_steps
            break
        else
            echo ""
            read -p "Would you like to try again? (y/n): " retry
            if [[ ! $retry =~ ^[Yy] ]]; then
                break
            fi
        fi
    done
    
    print_header "Setup Complete"
    echo "Thank you for using Enterprise SSO Setup!"
    echo ""
}

# Run main function
main "$@"
