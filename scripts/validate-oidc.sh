#!/bin/bash

##############################################################################
# OIDC Validation Utility
# 
# This script provides utilities to validate OIDC configuration.
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

validate_config() {
    local config_file=$1
    
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        return 1
    fi
    
    print_info "Validating OIDC configuration: $config_file"
    
    # Check if file is valid JSON
    if ! jq empty "$config_file" 2>/dev/null; then
        print_error "Invalid JSON format"
        return 1
    fi
    
    # Check for required fields
    local required_fields=(
        "client_id"
        "authorization_endpoint"
        "token_endpoint"
        "redirect_uri"
    )
    
    for field in "${required_fields[@]}"; do
        local value=$(jq -r ".$field // empty" "$config_file")
        if [ -z "$value" ]; then
            print_error "Missing required field: $field"
            return 1
        fi
    done
    
    print_success "Configuration validation passed"
    
    # Display key information
    print_info "Configuration Details:"
    echo "  Client ID: $(jq -r '.client_id' "$config_file")"
    echo "  Authorization Endpoint: $(jq -r '.authorization_endpoint' "$config_file")"
    echo "  Token Endpoint: $(jq -r '.token_endpoint' "$config_file")"
    echo "  Redirect URI: $(jq -r '.redirect_uri' "$config_file")"
    
    return 0
}

validate_endpoints() {
    local issuer_url=$1
    
    print_info "Validating OIDC endpoints for: $issuer_url"
    
    # Discover OIDC configuration
    local discovery_url="${issuer_url}/.well-known/openid-configuration"
    
    print_info "Fetching discovery document: $discovery_url"
    
    local response=$(curl -s "$discovery_url")
    
    if [ -z "$response" ]; then
        print_error "Failed to fetch discovery document"
        return 1
    fi
    
    # Validate JSON response
    if ! echo "$response" | jq empty 2>/dev/null; then
        print_error "Invalid discovery document format"
        return 1
    fi
    
    print_success "Discovery document is valid"
    
    # Check for required endpoints
    local endpoints=(
        "authorization_endpoint"
        "token_endpoint"
        "userinfo_endpoint"
        "jwks_uri"
    )
    
    for endpoint in "${endpoints[@]}"; do
        local url=$(echo "$response" | jq -r ".$endpoint // empty")
        if [ -n "$url" ]; then
            print_success "Found $endpoint: $url"
        else
            print_warning "Missing $endpoint"
        fi
    done
    
    return 0
}

validate_jwks() {
    local jwks_uri=$1
    
    print_info "Validating JWKS endpoint: $jwks_uri"
    
    local response=$(curl -s "$jwks_uri")
    
    if [ -z "$response" ]; then
        print_error "Failed to fetch JWKS"
        return 1
    fi
    
    # Validate JSON response
    if ! echo "$response" | jq empty 2>/dev/null; then
        print_error "Invalid JWKS format"
        return 1
    fi
    
    # Check for keys
    local key_count=$(echo "$response" | jq '.keys | length')
    
    if [ "$key_count" -gt 0 ]; then
        print_success "Found $key_count signing key(s)"
    else
        print_error "No signing keys found"
        return 1
    fi
    
    return 0
}

validate_scopes() {
    local config_file=$1
    
    print_info "Validating OIDC scopes"
    
    local scopes=$(jq -r '.scope // empty' "$config_file")
    
    if [ -z "$scopes" ]; then
        print_warning "No scopes defined"
        return 0
    fi
    
    # Check for required openid scope
    if ! echo "$scopes" | grep -q "openid"; then
        print_error "Missing required 'openid' scope"
        return 1
    fi
    
    print_success "Required scopes are present"
    echo "  Scopes: $scopes"
    
    return 0
}

test_token_validation() {
    local token=$1
    
    print_info "Validating JWT token format"
    
    # Check token format (header.payload.signature)
    local parts=$(echo "$token" | grep -o '\.' | wc -l)
    
    if [ "$parts" -ne 2 ]; then
        print_error "Invalid JWT format (expected 3 parts separated by dots)"
        return 1
    fi
    
    print_success "Token format is valid"
    
    # Decode payload (base64url)
    local payload=$(echo "$token" | cut -d'.' -f2)
    local decoded=$(echo "$payload" | base64 -d 2>/dev/null || echo "$payload" | base64 -D 2>/dev/null)
    
    if [ -n "$decoded" ] && echo "$decoded" | jq empty 2>/dev/null; then
        print_success "Token payload is valid JSON"
        print_info "Token Claims:"
        echo "$decoded" | jq '.'
    else
        print_warning "Could not decode token payload"
    fi
    
    return 0
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --config FILE       Validate OIDC configuration file"
    echo "  --endpoints URL     Validate OIDC endpoints (issuer URL)"
    echo "  --jwks URL         Validate JWKS endpoint"
    echo "  --token TOKEN      Validate JWT token format"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --config oidc-config.json"
    echo "  $0 --endpoints https://accounts.google.com"
    echo "  $0 --jwks https://example.com/.well-known/jwks.json"
}

main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    case "$1" in
        --config)
            validate_config "$2"
            validate_scopes "$2"
            ;;
        --endpoints)
            validate_endpoints "$2"
            ;;
        --jwks)
            validate_jwks "$2"
            ;;
        --token)
            test_token_validation "$2"
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
