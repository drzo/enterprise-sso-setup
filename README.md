# Enterprise SSO Setup

A comprehensive toolkit for configuring SAML/OIDC single sign-on for enterprise organizations managed through Identity Providers (IdPs).

## Overview

This repository provides automated configuration scripts and step-by-step guides for setting up enterprise SSO with common Identity Providers before creating organizations in your platform.

## Supported Identity Providers

- **Okta** - SAML 2.0 and OIDC
- **Azure AD (Microsoft Entra ID)** - SAML 2.0 and OIDC
- **Google Workspace** - SAML 2.0 and OIDC
- **OneLogin** - SAML 2.0 and OIDC

## Quick Start

### Prerequisites

- Bash shell (Linux, macOS, or WSL on Windows)
- `curl` or `wget` for making API requests
- `jq` for JSON processing
- Admin access to your Identity Provider
- OpenSSL for certificate generation

### Installation

```bash
git clone https://github.com/drzo/enterprise-sso-setup.git
cd enterprise-sso-setup
chmod +x setup.sh
```

### Basic Usage

Run the interactive setup wizard:

```bash
./setup.sh
```

Or configure a specific provider directly:

```bash
# For Okta SAML
./providers/okta/configure-saml.sh

# For Azure AD OIDC
./providers/azure-ad/configure-oidc.sh

# For Google Workspace SAML
./providers/google-workspace/configure-saml.sh

# For OneLogin OIDC
./providers/onelogin/configure-oidc.sh
```

## Directory Structure

```
enterprise-sso-setup/
├── setup.sh                      # Main interactive setup wizard
├── scripts/                      # Shared utility scripts
│   ├── validate-saml.sh         # SAML validation utilities
│   ├── validate-oidc.sh         # OIDC validation utilities
│   ├── generate-certs.sh        # Certificate generation
│   └── test-connection.sh       # Connection testing
├── providers/                    # Provider-specific configuration
│   ├── okta/
│   ├── azure-ad/
│   ├── google-workspace/
│   └── onelogin/
├── templates/                    # Configuration templates
│   ├── saml/
│   └── oidc/
├── docs/                        # Documentation
│   ├── saml-setup.md
│   ├── oidc-setup.md
│   └── troubleshooting.md
└── examples/                    # Example configurations
```

## Configuration Workflows

### SAML 2.0 Configuration

1. **Generate SP Metadata** - Create Service Provider metadata XML
2. **Configure IdP** - Upload metadata to Identity Provider
3. **Download IdP Metadata** - Get Identity Provider metadata
4. **Validate Configuration** - Test SAML assertions
5. **Test SSO Flow** - Verify end-to-end authentication

### OIDC Configuration

1. **Register Application** - Create OIDC app in Identity Provider
2. **Configure Endpoints** - Set authorization and token endpoints
3. **Set Redirect URIs** - Configure callback URLs
4. **Obtain Credentials** - Get client ID and secret
5. **Test Authentication** - Verify OIDC flow

## Features

- **Automated Configuration**: Scripts to automate most setup steps
- **Interactive Wizard**: Guided setup with prompts and validation
- **Template Generation**: Pre-configured templates for common scenarios
- **Validation Tools**: Utilities to verify configuration correctness
- **Testing Utilities**: Tools to test authentication flows
- **Documentation**: Comprehensive guides for each provider
- **Examples**: Sample configurations for reference

## SAML Configuration Details

SAML configuration requires:
- Entity ID (Unique identifier for your service)
- ACS URL (Assertion Consumer Service URL)
- Single Logout URL (Optional)
- X.509 Certificate (For signature verification)
- Attribute Mapping (User attributes to pass)

## OIDC Configuration Details

OIDC configuration requires:
- Client ID
- Client Secret
- Authorization Endpoint
- Token Endpoint
- UserInfo Endpoint
- Redirect URIs
- Scopes (openid, profile, email, etc.)

## Security Best Practices

- Always use HTTPS for all endpoints
- Rotate certificates and secrets regularly
- Implement certificate pinning where possible
- Use strong encryption algorithms (SHA-256, RSA-2048)
- Enable MFA in your Identity Provider
- Monitor authentication logs for anomalies
- Implement session timeout policies
- Use state parameters to prevent CSRF

## Troubleshooting

Common issues and solutions:

1. **SAML Assertion Signature Validation Failed**
   - Verify certificate hasn't expired
   - Check clock synchronization between SP and IdP
   - Ensure correct certificate is configured

2. **OIDC Token Validation Failed**
   - Verify client secret is correct
   - Check token expiration time
   - Ensure issuer URL matches configuration

3. **Redirect URI Mismatch**
   - Verify exact match including protocol and port
   - Check for trailing slashes
   - Ensure all redirect URIs are registered

See [docs/troubleshooting.md](docs/troubleshooting.md) for detailed solutions.

## Testing

Test your configuration:

```bash
# Validate SAML setup
./scripts/validate-saml.sh --metadata sp-metadata.xml

# Validate OIDC setup
./scripts/validate-oidc.sh --config oidc-config.json

# Test SSO connection
./scripts/test-connection.sh --provider okta --protocol saml
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Support

- Documentation: [docs/](docs/)
- Issues: [GitHub Issues](https://github.com/drzo/enterprise-sso-setup/issues)
- Discussions: [GitHub Discussions](https://github.com/drzo/enterprise-sso-setup/discussions)

## License

See [LICENSE](LICENSE) file for details.

## Resources

- [SAML 2.0 Specification](https://docs.oasis-open.org/security/saml/v2.0/)
- [OpenID Connect Specification](https://openid.net/specs/openid-connect-core-1_0.html)
- [OAuth 2.0 RFC](https://tools.ietf.org/html/rfc6749)

## Disclaimer

This toolkit is provided as-is for educational and implementation purposes. Always follow your organization's security policies and consult with security professionals when implementing enterprise authentication systems.