# Azure AD SSO Configuration

This directory contains configuration scripts for setting up SSO with Azure AD (Microsoft Entra ID).

## Available Scripts

### SAML Configuration
```bash
./configure-saml.sh
```

Guides you through setting up SAML 2.0 SSO with Azure AD. This script will:
- Collect necessary information (Tenant ID, Entity ID, Reply URL)
- Generate Service Provider metadata
- Create configuration file
- Provide step-by-step instructions for Azure Portal setup

### OIDC Configuration
```bash
./configure-oidc.sh
```

Guides you through setting up OpenID Connect SSO with Azure AD. This script will:
- Collect necessary information (Tenant ID, Redirect URI)
- Generate OIDC configuration file
- Provide step-by-step instructions for Azure Portal setup

## Prerequisites

- Admin access to Azure AD
- Your organization's Tenant ID or domain (e.g., contoso.onmicrosoft.com)
- Your application's URLs

## Quick Start

1. Run the appropriate configuration script
2. Follow the prompts to provide information
3. Review the generated files in `output/azure-ad/`
4. Follow the displayed instructions to complete setup in Azure Portal
5. Test your configuration using the provided testing utilities

## Output Files

After running the scripts, you'll find:

**For SAML:**
- `output/azure-ad/sp-metadata.xml` - Service Provider metadata
- `output/azure-ad/azure-saml-config.json` - Configuration file

**For OIDC:**
- `output/azure-ad/oidc-config.json` - OIDC configuration

## Documentation

For detailed information:
- [SAML Setup Guide](../../docs/saml-setup.md)
- [OIDC Setup Guide](../../docs/oidc-setup.md)
- [Troubleshooting](../../docs/troubleshooting.md)

## Azure AD Resources

- [Azure AD SAML Documentation](https://learn.microsoft.com/en-us/azure/active-directory/manage-apps/what-is-single-sign-on)
- [Azure AD OIDC Documentation](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc)
- [Azure Portal](https://portal.azure.com)
