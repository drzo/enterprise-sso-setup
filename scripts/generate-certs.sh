#!/bin/bash

##############################################################################
# Certificate Generation Utility
# 
# This script generates X.509 certificates for SAML configuration.
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

generate_self_signed_cert() {
    local output_dir=$1
    local common_name=$2
    local days_valid=${3:-3650}  # Default 10 years
    
    print_info "Generating self-signed certificate"
    
    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"
    
    local key_file="$output_dir/saml-private.key"
    local cert_file="$output_dir/saml-certificate.crt"
    local pem_file="$output_dir/saml-certificate.pem"
    
    # Generate private key
    print_info "Generating private key..."
    openssl genrsa -out "$key_file" 2048 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Private key generated: $key_file"
    else
        print_error "Failed to generate private key"
        return 1
    fi
    
    # Generate certificate
    print_info "Generating certificate..."
    openssl req -new -x509 -key "$key_file" -out "$cert_file" \
        -days "$days_valid" \
        -subj "/CN=$common_name" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Certificate generated: $cert_file"
    else
        print_error "Failed to generate certificate"
        return 1
    fi
    
    # Create PEM format (certificate + key)
    cat "$cert_file" "$key_file" > "$pem_file"
    print_success "PEM file created: $pem_file"
    
    # Display certificate information
    print_info "Certificate Details:"
    openssl x509 -in "$cert_file" -noout -subject -issuer -dates
    
    # Set secure permissions
    chmod 600 "$key_file" "$pem_file"
    chmod 644 "$cert_file"
    
    print_success "Certificate generation completed"
    echo ""
    echo "Files created:"
    echo "  Private Key: $key_file"
    echo "  Certificate: $cert_file"
    echo "  PEM Bundle:  $pem_file"
    echo ""
    print_warning "Keep the private key secure and never share it!"
    
    return 0
}

generate_csr() {
    local output_dir=$1
    local common_name=$2
    
    print_info "Generating Certificate Signing Request (CSR)"
    
    mkdir -p "$output_dir"
    
    local key_file="$output_dir/saml-private.key"
    local csr_file="$output_dir/saml-request.csr"
    
    # Generate private key
    print_info "Generating private key..."
    openssl genrsa -out "$key_file" 2048 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "Private key generated: $key_file"
    else
        print_error "Failed to generate private key"
        return 1
    fi
    
    # Generate CSR
    print_info "Generating CSR..."
    openssl req -new -key "$key_file" -out "$csr_file" \
        -subj "/CN=$common_name" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "CSR generated: $csr_file"
    else
        print_error "Failed to generate CSR"
        return 1
    fi
    
    # Display CSR information
    print_info "CSR Details:"
    openssl req -in "$csr_file" -noout -subject
    
    # Set secure permissions
    chmod 600 "$key_file"
    chmod 644 "$csr_file"
    
    print_success "CSR generation completed"
    echo ""
    echo "Files created:"
    echo "  Private Key: $key_file"
    echo "  CSR:         $csr_file"
    echo ""
    print_info "Submit the CSR to your Certificate Authority"
    print_warning "Keep the private key secure and never share it!"
    
    return 0
}

extract_public_key() {
    local cert_file=$1
    local output_file=$2
    
    print_info "Extracting public key from certificate"
    
    if [ ! -f "$cert_file" ]; then
        print_error "Certificate file not found: $cert_file"
        return 1
    fi
    
    openssl x509 -in "$cert_file" -pubkey -noout > "$output_file"
    
    if [ $? -eq 0 ]; then
        print_success "Public key extracted: $output_file"
        return 0
    else
        print_error "Failed to extract public key"
        return 1
    fi
}

convert_format() {
    local input_file=$1
    local output_format=$2
    local output_file=$3
    
    print_info "Converting certificate format to $output_format"
    
    case "$output_format" in
        pem)
            openssl x509 -in "$input_file" -out "$output_file" -outform PEM
            ;;
        der)
            openssl x509 -in "$input_file" -out "$output_file" -outform DER
            ;;
        *)
            print_error "Unsupported format: $output_format"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        print_success "Certificate converted: $output_file"
        return 0
    else
        print_error "Failed to convert certificate"
        return 1
    fi
}

usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  self-signed     Generate self-signed certificate"
    echo "  csr            Generate Certificate Signing Request"
    echo "  extract-pubkey Extract public key from certificate"
    echo "  convert        Convert certificate format"
    echo ""
    echo "Self-signed options:"
    echo "  --output DIR       Output directory"
    echo "  --cn NAME         Common Name (domain)"
    echo "  --days NUM        Days valid (default: 3650)"
    echo ""
    echo "CSR options:"
    echo "  --output DIR       Output directory"
    echo "  --cn NAME         Common Name (domain)"
    echo ""
    echo "Extract public key options:"
    echo "  --cert FILE       Certificate file"
    echo "  --output FILE     Output file"
    echo ""
    echo "Convert options:"
    echo "  --input FILE      Input certificate"
    echo "  --format FORMAT   Output format (pem/der)"
    echo "  --output FILE     Output file"
    echo ""
    echo "Examples:"
    echo "  $0 self-signed --output ./certs --cn example.com"
    echo "  $0 csr --output ./certs --cn example.com"
    echo "  $0 extract-pubkey --cert cert.pem --output pubkey.pem"
    echo "  $0 convert --input cert.der --format pem --output cert.pem"
}

main() {
    if [ $# -eq 0 ]; then
        usage
        exit 1
    fi
    
    local command=$1
    shift
    
    case "$command" in
        self-signed)
            local output_dir=""
            local cn=""
            local days=3650
            
            while [ $# -gt 0 ]; do
                case "$1" in
                    --output) output_dir="$2"; shift 2 ;;
                    --cn) cn="$2"; shift 2 ;;
                    --days) days="$2"; shift 2 ;;
                    *) echo "Unknown option: $1"; usage; exit 1 ;;
                esac
            done
            
            if [ -z "$output_dir" ] || [ -z "$cn" ]; then
                print_error "Missing required options"
                usage
                exit 1
            fi
            
            generate_self_signed_cert "$output_dir" "$cn" "$days"
            ;;
            
        csr)
            local output_dir=""
            local cn=""
            
            while [ $# -gt 0 ]; do
                case "$1" in
                    --output) output_dir="$2"; shift 2 ;;
                    --cn) cn="$2"; shift 2 ;;
                    *) echo "Unknown option: $1"; usage; exit 1 ;;
                esac
            done
            
            if [ -z "$output_dir" ] || [ -z "$cn" ]; then
                print_error "Missing required options"
                usage
                exit 1
            fi
            
            generate_csr "$output_dir" "$cn"
            ;;
            
        extract-pubkey)
            local cert_file=""
            local output_file=""
            
            while [ $# -gt 0 ]; do
                case "$1" in
                    --cert) cert_file="$2"; shift 2 ;;
                    --output) output_file="$2"; shift 2 ;;
                    *) echo "Unknown option: $1"; usage; exit 1 ;;
                esac
            done
            
            if [ -z "$cert_file" ] || [ -z "$output_file" ]; then
                print_error "Missing required options"
                usage
                exit 1
            fi
            
            extract_public_key "$cert_file" "$output_file"
            ;;
            
        convert)
            local input_file=""
            local format=""
            local output_file=""
            
            while [ $# -gt 0 ]; do
                case "$1" in
                    --input) input_file="$2"; shift 2 ;;
                    --format) format="$2"; shift 2 ;;
                    --output) output_file="$2"; shift 2 ;;
                    *) echo "Unknown option: $1"; usage; exit 1 ;;
                esac
            done
            
            if [ -z "$input_file" ] || [ -z "$format" ] || [ -z "$output_file" ]; then
                print_error "Missing required options"
                usage
                exit 1
            fi
            
            convert_format "$input_file" "$format" "$output_file"
            ;;
            
        --help)
            usage
            exit 0
            ;;
            
        *)
            echo "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

main "$@"
