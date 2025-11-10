#!/bin/bash

##############################################################################
# SAML Validation Utility
# 
# This script provides utilities to validate SAML configuration and metadata.
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

validate_metadata() {
    local metadata_file=$1
    
    if [ ! -f "$metadata_file" ]; then
        print_error "Metadata file not found: $metadata_file"
        return 1
    fi
    
    print_info "Validating SAML metadata: $metadata_file"
    
    # Check if file is valid XML
    if ! xmllint --noout "$metadata_file" 2>/dev/null; then
        print_error "Invalid XML format"
        return 1
    fi
    
    # Check for required elements
    local required_elements=(
        "EntityDescriptor"
        "SPSSODescriptor"
        "AssertionConsumerService"
    )
    
    for element in "${required_elements[@]}"; do
        if ! grep -q "<$element" "$metadata_file"; then
            print_error "Missing required element: $element"
            return 1
        fi
    done
    
    print_success "Metadata validation passed"
    
    # Extract and display key information
    print_info "Metadata Information:"
    
    local entity_id=$(xmllint --xpath 'string(//*[local-name()="EntityDescriptor"]/@entityID)' "$metadata_file" 2>/dev/null)
    if [ -n "$entity_id" ]; then
        echo "  Entity ID: $entity_id"
    fi
    
    local acs_url=$(xmllint --xpath 'string(//*[local-name()="AssertionConsumerService"]/@Location)' "$metadata_file" 2>/dev/null)
    if [ -n "$acs_url" ]; then
        echo "  ACS URL: $acs_url"
    fi
    
    return 0
}

validate_certificate() {
    local cert_file=$1
    
    if [ ! -f "$cert_file" ]; then
        print_error "Certificate file not found: $cert_file"
        return 1
    fi
    
    print_info "Validating certificate: $cert_file"
    
    # Check certificate validity
    if ! openssl x509 -in "$cert_file" -noout -checkend 0 2>/dev/null; then
        print_error "Certificate has expired"
        return 1
    fi
    
    # Get certificate details
    local subject=$(openssl x509 -in "$cert_file" -noout -subject 2>/dev/null | sed 's/subject=//')
    local issuer=$(openssl x509 -in "$cert_file" -noout -issuer 2>/dev/null | sed 's/issuer=//')
    local expiry=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | sed 's/notAfter=//')
    
    print_success "Certificate is valid"
    echo "  Subject: $subject"
    echo "  Issuer: $issuer"
    echo "  Expires: $expiry"
    
    # Warn if expiring soon (30 days)
    if ! openssl x509 -in "$cert_file" -noout -checkend 2592000 2>/dev/null; then
        print_warning "Certificate expires within 30 days"
    fi
    
    return 0
}

validate_signature() {
    local xml_file=$1
    local cert_file=$2
    
    print_info "Validating SAML signature"
    
    # This is a simplified check - full validation requires xmlsec1
    if command -v xmlsec1 &> /dev/null; then
        if xmlsec1 --verify --pubkey-cert-pem "$cert_file" "$xml_file" &>/dev/null; then
            print_success "Signature validation passed"
            return 0
        else
            print_error "Signature validation failed"
            return 1
        fi
    else
        print_warning "xmlsec1 not installed - skipping signature verification"
        print_info "Install xmlsec1 for full signature validation"
        return 0
    fi
}

check_attributes() {
    local metadata_file=$1
    
    print_info "Checking SAML attributes"
    
    local common_attrs=(
        "email"
        "firstName"
        "lastName"
        "displayName"
    )
    
    for attr in "${common_attrs[@]}"; do
        if grep -qi "$attr" "$metadata_file"; then
            print_success "Found attribute: $attr"
        else
            print_warning "Attribute not found: $attr"
        fi
    done
    
    return 0
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --metadata FILE     Validate SAML metadata file"
    echo "  --certificate FILE  Validate X.509 certificate"
    echo "  --signature XML CERT Validate SAML signature"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --metadata sp-metadata.xml"
    echo "  $0 --certificate certificate.pem"
    echo "  $0 --signature response.xml idp-cert.pem"
}

main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    case "$1" in
        --metadata)
            validate_metadata "$2"
            ;;
        --certificate)
            validate_certificate "$2"
            ;;
        --signature)
            validate_signature "$2" "$3"
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"
