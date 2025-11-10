# SAML 2.0 Setup Guide

## Overview

Security Assertion Markup Language (SAML) 2.0 is an open standard for exchanging authentication and authorization data between parties. This guide explains how to set up SAML SSO with your enterprise Identity Provider.

## Prerequisites

- Administrative access to your Identity Provider (IdP)
- Administrative access to your Service Provider (SP) application
- Understanding of your organization's authentication requirements
- SSL/TLS certificates for production environments

## SAML Components

### Service Provider (SP)
The application that users want to access (your application).

**Key elements:**
- **Entity ID**: Unique identifier for your SP
- **ACS URL**: Assertion Consumer Service URL where IdP sends authentication responses
- **SP Metadata**: XML file describing your SP configuration

### Identity Provider (IdP)
The system that authenticates users (Okta, Azure AD, etc.).

**Key elements:**
- **Entity ID**: Unique identifier for the IdP
- **SSO URL**: Single Sign-On endpoint where authentication requests are sent
- **IdP Metadata**: XML file describing the IdP configuration
- **Signing Certificate**: X.509 certificate used to sign SAML assertions

## Setup Steps

### 1. Generate SP Metadata

Create your Service Provider metadata XML file:

```bash
./scripts/generate-certs.sh self-signed --output ./certs --cn yourdomain.com
```

Use the provider-specific scripts to generate metadata:

```bash
./providers/okta/configure-saml.sh
# or
./providers/azure-ad/configure-saml.sh
# or
./providers/google-workspace/configure-saml.sh
# or
./providers/onelogin/configure-saml.sh
```

### 2. Configure Identity Provider

Upload your SP metadata to your IdP:

- **Okta**: Applications > Create App Integration > SAML 2.0
- **Azure AD**: Enterprise Applications > New application > Create your own
- **Google Workspace**: Apps > Web and mobile apps > Add custom SAML app
- **OneLogin**: Applications > Add App > SAML Custom Connector

### 3. Download IdP Metadata

Download the IdP metadata XML file from your provider:

- Contains IdP Entity ID, SSO URL, and signing certificate
- Save as `idp-metadata.xml` in your output directory

### 4. Configure SP Application

In your application, configure SAML settings:

```json
{
  "entity_id": "https://yourdomain.com/saml/metadata",
  "acs_url": "https://yourdomain.com/saml/acs",
  "idp_entity_id": "https://idp.example.com/entity",
  "idp_sso_url": "https://idp.example.com/sso",
  "idp_certificate": "-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"
}
```

### 5. Configure Attribute Mapping

Map IdP attributes to your application's user attributes:

| Application Attribute | IdP Attribute (Okta) | IdP Attribute (Azure AD) |
|----------------------|---------------------|-------------------------|
| email | user.email | http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress |
| firstName | user.firstName | http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname |
| lastName | user.lastName | http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname |
| displayName | user.displayName | http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name |

### 6. Test SSO Flow

Test the SAML authentication flow:

```bash
./scripts/test-connection.sh --provider okta --protocol saml
```

Manual testing:
1. Navigate to your application
2. Click "Sign in with SSO"
3. You should be redirected to IdP login page
4. After authentication, you should be redirected back to your application
5. Verify user attributes are correctly mapped

### 7. Validate Configuration

Use validation tools to check your setup:

```bash
./scripts/validate-saml.sh --metadata output/okta/sp-metadata.xml
./scripts/validate-saml.sh --certificate certs/saml-certificate.crt
```

## SAML Request Flow

1. **User initiates login** → SP generates SAML AuthnRequest
2. **SP redirects to IdP** → User sent to IdP SSO URL with SAMLRequest
3. **IdP authenticates user** → User enters credentials at IdP
4. **IdP generates response** → IdP creates signed SAML assertion
5. **IdP redirects to SP** → User sent to ACS URL with SAMLResponse
6. **SP validates response** → SP verifies signature and extracts user data
7. **User authenticated** → SP creates session for user

## Security Best Practices

### Certificate Management
- Use 2048-bit or higher RSA keys
- Rotate certificates before expiration
- Use SHA-256 or higher for signatures
- Store private keys securely (never commit to version control)

### Signature Validation
- Always validate SAML response signatures
- Verify certificate chain and expiration
- Check assertion timestamps (NotBefore/NotOnOrAfter)
- Validate Audience restriction (must match your Entity ID)

### Network Security
- Use HTTPS for all endpoints (ACS, SLO, metadata URLs)
- Implement CSRF protection for ACS endpoint
- Rate limit authentication endpoints
- Log all authentication attempts

### Additional Security
- Enable MFA at IdP level
- Implement session timeout policies
- Use encrypted assertions when possible
- Monitor for suspicious authentication patterns
- Implement IP whitelisting if applicable

## Common Attributes

Standard SAML attribute names:

```xml
<saml:Attribute Name="email">
  <saml:AttributeValue>user@example.com</saml:AttributeValue>
</saml:Attribute>

<saml:Attribute Name="firstName">
  <saml:AttributeValue>John</saml:AttributeValue>
</saml:Attribute>

<saml:Attribute Name="lastName">
  <saml:AttributeValue>Doe</saml:AttributeValue>
</saml:Attribute>

<saml:Attribute Name="groups">
  <saml:AttributeValue>Administrators</saml:AttributeValue>
  <saml:AttributeValue>Users</saml:AttributeValue>
</saml:Attribute>
```

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for common issues and solutions.

## Advanced Configuration

### Multiple ACS URLs

Support multiple ACS URLs for different environments:

```xml
<md:AssertionConsumerService
    Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
    Location="https://prod.example.com/saml/acs"
    index="0"
    isDefault="true"/>
    
<md:AssertionConsumerService
    Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
    Location="https://staging.example.com/saml/acs"
    index="1"/>
```

### Single Logout (SLO)

Implement single logout for better security:

```xml
<md:SingleLogoutService
    Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
    Location="https://yourdomain.com/saml/slo"/>
```

### Encrypted Assertions

Request encrypted assertions for sensitive data:

```xml
<md:KeyDescriptor use="encryption">
    <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:X509Data>
            <ds:X509Certificate>MIIDXTCCAkWg...</ds:X509Certificate>
        </ds:X509Data>
    </ds:KeyInfo>
</md:KeyDescriptor>
```

## Resources

- [SAML 2.0 Technical Overview](https://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html)
- [SAML 2.0 Specifications](https://docs.oasis-open.org/security/saml/v2.0/)
- [SAML Bindings](https://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf)
- [SAML Profiles](https://docs.oasis-open.org/security/saml/v2.0/saml-profiles-2.0-os.pdf)
