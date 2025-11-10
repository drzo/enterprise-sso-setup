# Okta SSO Configuration

This directory contains configuration scripts for setting up SSO with Okta.

## Available Scripts

### SAML Configuration
```bash
./configure-saml.sh
```

Guides you through setting up SAML 2.0 SSO with Okta. This script will:
- Collect necessary information (Okta domain, Entity ID, ACS URL)
- Generate Service Provider metadata
- Create configuration file
- Provide step-by-step instructions for Okta setup

### OIDC Configuration
```bash
./configure-oidc.sh
```

Guides you through setting up OpenID Connect SSO with Okta. This script will:
- Collect necessary information (Okta domain, Redirect URI)
- Generate OIDC configuration file
- Provide step-by-step instructions for Okta setup

## Prerequisites

- Admin access to Okta
- Your organization's Okta domain (e.g., dev-123456.okta.com)
- Your application's URLs

## Quick Start

1. Run the appropriate configuration script
2. Follow the prompts to provide information
3. Review the generated files in `output/okta/`
4. Follow the displayed instructions to complete setup in Okta Admin Console
5. Test your configuration using the provided testing utilities

## Output Files

After running the scripts, you'll find:

**For SAML:**
- `output/okta/sp-metadata.xml` - Service Provider metadata
- `output/okta/okta-saml-config.json` - Configuration file

**For OIDC:**
- `output/okta/oidc-config.json` - OIDC configuration

## Documentation

For detailed information:
- [SAML Setup Guide](../../docs/saml-setup.md)
- [OIDC Setup Guide](../../docs/oidc-setup.md)
- [Troubleshooting](../../docs/troubleshooting.md)

## Okta Resources

- [Okta SAML Documentation](https://developer.okta.com/docs/concepts/saml/)
- [Okta OIDC Documentation](https://developer.okta.com/docs/concepts/oauth-openid/)
- [Okta Admin Console](https://developer.okta.com/docs/guides/)
