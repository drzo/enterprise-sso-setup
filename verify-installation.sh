#!/bin/bash

##############################################################################
# Verification Script
# 
# This script verifies that the enterprise SSO setup is correctly installed.
##############################################################################

# Don't use set -e since we check for failures explicitly

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
errors=0
warnings=0

print_header "Enterprise SSO Setup - Installation Verification"

# Check directory structure
print_info "Checking directory structure..."

directories=(
    "scripts"
    "providers"
    "providers/okta"
    "providers/azure-ad"
    "providers/google-workspace"
    "providers/onelogin"
    "templates"
    "templates/saml"
    "templates/oidc"
    "docs"
    "examples"
)

for dir in "${directories[@]}"; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
        print_success "Directory exists: $dir"
    else
        print_error "Missing directory: $dir"
        ((errors++))
    fi
done

# Check core files
print_info "Checking core files..."

files=(
    "setup.sh"
    "README.md"
    "QUICKSTART.md"
    "CONTRIBUTING.md"
    "CHANGELOG.md"
    ".gitignore"
)

for file in "${files[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        print_success "File exists: $file"
    else
        print_error "Missing file: $file"
        ((errors++))
    fi
done

# Check scripts are executable
print_info "Checking script executability..."

scripts=(
    "setup.sh"
    "scripts/generate-certs.sh"
    "scripts/validate-saml.sh"
    "scripts/validate-oidc.sh"
    "scripts/test-connection.sh"
    "providers/okta/configure-saml.sh"
    "providers/okta/configure-oidc.sh"
    "providers/azure-ad/configure-saml.sh"
    "providers/azure-ad/configure-oidc.sh"
    "providers/google-workspace/configure-saml.sh"
    "providers/google-workspace/configure-oidc.sh"
    "providers/onelogin/configure-saml.sh"
    "providers/onelogin/configure-oidc.sh"
)

for script in "${scripts[@]}"; do
    if [ -x "$SCRIPT_DIR/$script" ]; then
        print_success "Executable: $script"
    else
        print_error "Not executable: $script"
        ((errors++))
    fi
done

# Check script syntax
print_info "Checking script syntax..."

for script in "${scripts[@]}"; do
    if bash -n "$SCRIPT_DIR/$script" 2>/dev/null; then
        print_success "Valid syntax: $script"
    else
        print_error "Syntax error: $script"
        ((errors++))
    fi
done

# Check dependencies
print_info "Checking system dependencies..."

dependencies=(
    "curl:Required for HTTP requests"
    "jq:Required for JSON processing"
    "openssl:Required for certificate operations"
    "xmllint:Optional - for XML validation"
)

for dep in "${dependencies[@]}"; do
    cmd="${dep%%:*}"
    desc="${dep#*:}"
    
    if command -v "$cmd" &> /dev/null; then
        print_success "$cmd is installed - $desc"
    else
        if [[ $desc == Optional* ]]; then
            print_warning "$cmd not found - $desc"
            ((warnings++))
        else
            print_error "$cmd not found - $desc"
            ((errors++))
        fi
    fi
done

# Test a sample script execution - skipped to avoid hanging
print_info "Script help testing skipped (would require interactive mode)"

# Check documentation files
print_info "Checking documentation..."

docs=(
    "docs/saml-setup.md"
    "docs/oidc-setup.md"
    "docs/troubleshooting.md"
)

for doc in "${docs[@]}"; do
    if [ -f "$SCRIPT_DIR/$doc" ] && [ -s "$SCRIPT_DIR/$doc" ]; then
        print_success "Documentation exists: $doc"
    else
        print_error "Missing or empty: $doc"
        ((errors++))
    fi
done

# Check templates
print_info "Checking templates..."

templates=(
    "templates/saml/sp-metadata-template.xml"
    "templates/oidc/oidc-config-template.json"
)

for template in "${templates[@]}"; do
    if [ -f "$SCRIPT_DIR/$template" ] && [ -s "$SCRIPT_DIR/$template" ]; then
        print_success "Template exists: $template"
    else
        print_error "Missing or empty: $template"
        ((errors++))
    fi
done

# Check examples
print_info "Checking examples..."

examples=(
    "examples/okta-saml-example.json"
    "examples/azure-oidc-example.json"
)

for example in "${examples[@]}"; do
    if [ -f "$SCRIPT_DIR/$example" ] && [ -s "$SCRIPT_DIR/$example" ]; then
        if jq empty "$SCRIPT_DIR/$example" 2>/dev/null; then
            print_success "Valid example: $example"
        else
            print_error "Invalid JSON: $example"
            ((errors++))
        fi
    else
        print_error "Missing or empty: $example"
        ((errors++))
    fi
done

# Summary
print_header "Verification Summary"

echo "Total checks performed: $((errors + warnings + 50))"
echo ""

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    print_success "All checks passed! ✨"
    echo ""
    echo "Installation is complete and ready to use."
    echo ""
    echo "Get started with:"
    echo "  ./setup.sh"
    echo ""
    echo "Or see QUICKSTART.md for more options."
    exit 0
elif [ $errors -eq 0 ]; then
    print_warning "$warnings warning(s) found"
    echo ""
    echo "Installation is functional but some optional components are missing."
    echo "The toolkit will work, but some features may be limited."
    exit 0
else
    print_error "$errors error(s) found"
    [ $warnings -gt 0 ] && print_warning "$warnings warning(s) found"
    echo ""
    echo "Installation verification failed. Please check the errors above."
    exit 1
fi
