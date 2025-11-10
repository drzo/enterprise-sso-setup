#!/bin/bash

##############################################################################
# SSO Connection Testing Utility
# 
# This script tests SSO connections for both SAML and OIDC configurations.
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

test_saml_connection() {
    local provider=$1
    local metadata_file=$2
    
    print_info "Testing SAML connection for $provider"
    
    if [ ! -f "$metadata_file" ]; then
        print_error "Metadata file not found: $metadata_file"
        return 1
    fi
    
    # Check metadata validity
    if ! xmllint --noout "$metadata_file" 2>/dev/null; then
        print_error "Invalid metadata XML"
        return 1
    fi
    
    print_success "Metadata is valid"
    
    # Extract ACS URL
    local acs_url=$(xmllint --xpath 'string(//*[local-name()="AssertionConsumerService"]/@Location)' "$metadata_file" 2>/dev/null)
    
    if [ -n "$acs_url" ]; then
        print_info "Testing ACS endpoint: $acs_url"
        
        # Test if endpoint is reachable
        if curl -s -o /dev/null -w "%{http_code}" "$acs_url" | grep -q "200\|405\|302"; then
            print_success "ACS endpoint is reachable"
        else
            print_warning "ACS endpoint may not be configured yet"
        fi
    fi
    
    return 0
}

test_oidc_connection() {
    local provider=$1
    local config_file=$2
    
    print_info "Testing OIDC connection for $provider"
    
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Validate JSON
    if ! jq empty "$config_file" 2>/dev/null; then
        print_error "Invalid configuration JSON"
        return 1
    fi
    
    print_success "Configuration is valid"
    
    # Extract endpoints
    local auth_endpoint=$(jq -r '.authorization_endpoint' "$config_file")
    local token_endpoint=$(jq -r '.token_endpoint' "$config_file")
    
    # Test authorization endpoint
    if [ -n "$auth_endpoint" ]; then
        print_info "Testing authorization endpoint: $auth_endpoint"
        
        local status=$(curl -s -o /dev/null -w "%{http_code}" "$auth_endpoint")
        if [ "$status" = "200" ] || [ "$status" = "302" ] || [ "$status" = "400" ]; then
            print_success "Authorization endpoint is reachable"
        else
            print_warning "Authorization endpoint returned status: $status"
        fi
    fi
    
    # Test token endpoint
    if [ -n "$token_endpoint" ]; then
        print_info "Testing token endpoint: $token_endpoint"
        
        local status=$(curl -s -o /dev/null -w "%{http_code}" "$token_endpoint")
        if [ "$status" = "200" ] || [ "$status" = "400" ] || [ "$status" = "401" ]; then
            print_success "Token endpoint is reachable"
        else
            print_warning "Token endpoint returned status: $status"
        fi
    fi
    
    return 0
}

test_discovery_endpoint() {
    local issuer_url=$1
    
    print_info "Testing OIDC discovery endpoint"
    
    local discovery_url="${issuer_url}/.well-known/openid-configuration"
    
    print_info "Fetching: $discovery_url"
    
    local response=$(curl -s "$discovery_url")
    
    if [ -z "$response" ]; then
        print_error "Failed to fetch discovery document"
        return 1
    fi
    
    if echo "$response" | jq empty 2>/dev/null; then
        print_success "Discovery document is valid"
        
        # Display key endpoints
        print_info "Discovered Endpoints:"
        echo "$response" | jq -r '{
            authorization_endpoint,
            token_endpoint,
            userinfo_endpoint,
            jwks_uri
        }'
        
        return 0
    else
        print_error "Invalid discovery document"
        return 1
    fi
}

test_network_connectivity() {
    local url=$1
    
    print_info "Testing network connectivity to: $url"
    
    # Extract hostname
    local hostname=$(echo "$url" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    
    # Test DNS resolution
    if host "$hostname" &>/dev/null; then
        print_success "DNS resolution successful"
    else
        print_error "DNS resolution failed for $hostname"
        return 1
    fi
    
    # Test HTTP(S) connectivity
    local status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)
    
    if [ -n "$status" ]; then
        print_success "HTTP(S) connection successful (status: $status)"
        return 0
    else
        print_error "HTTP(S) connection failed"
        return 1
    fi
}

run_full_test() {
    local provider=$1
    local protocol=$2
    
    print_info "Running full SSO test for $provider ($protocol)"
    
    local config_dir="./output/${provider}"
    
    if [ ! -d "$config_dir" ]; then
        print_error "Configuration directory not found: $config_dir"
        return 1
    fi
    
    case "$protocol" in
        saml)
            local metadata_file="$config_dir/sp-metadata.xml"
            test_saml_connection "$provider" "$metadata_file"
            ;;
        oidc)
            local config_file="$config_dir/oidc-config.json"
            test_oidc_connection "$provider" "$config_file"
            ;;
        *)
            print_error "Unknown protocol: $protocol"
            return 1
            ;;
    esac
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --provider NAME    Provider name (okta, azure-ad, google-workspace, onelogin)"
    echo "  --protocol TYPE    Protocol type (saml, oidc)"
    echo "  --saml FILE       Test SAML metadata file"
    echo "  --oidc FILE       Test OIDC configuration file"
    echo "  --discovery URL   Test OIDC discovery endpoint"
    echo "  --network URL     Test network connectivity"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --provider okta --protocol saml"
    echo "  $0 --saml sp-metadata.xml"
    echo "  $0 --oidc oidc-config.json"
    echo "  $0 --discovery https://accounts.google.com"
    echo "  $0 --network https://example.com"
}

main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    case "$1" in
        --provider)
            if [ -z "$3" ] || [ "$3" != "--protocol" ]; then
                print_error "Missing --protocol option"
                usage
                exit 1
            fi
            run_full_test "$2" "$4"
            ;;
        --saml)
            test_saml_connection "custom" "$2"
            ;;
        --oidc)
            test_oidc_connection "custom" "$2"
            ;;
        --discovery)
            test_discovery_endpoint "$2"
            ;;
        --network)
            test_network_connectivity "$2"
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
