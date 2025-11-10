# Quick Start Guide

Get your enterprise SSO up and running in minutes!

## Prerequisites Check

Before you begin, ensure you have:

```bash
# Check if dependencies are installed
command -v curl >/dev/null 2>&1 && echo "✓ curl" || echo "✗ curl"
command -v jq >/dev/null 2>&1 && echo "✓ jq" || echo "✗ jq"
command -v openssl >/dev/null 2>&1 && echo "✓ openssl" || echo "✗ openssl"
```

Install missing dependencies:

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install curl jq openssl
```

**macOS:**
```bash
brew install curl jq openssl
```

**RHEL/CentOS:**
```bash
sudo yum install curl jq openssl
```

## 5-Minute Setup

### Option 1: Interactive Wizard (Recommended)

The easiest way to get started:

```bash
# Clone the repository
git clone https://github.com/drzo/enterprise-sso-setup.git
cd enterprise-sso-setup

# Make setup script executable
chmod +x setup.sh

# Run the interactive wizard
./setup.sh
```

The wizard will:
1. Check your dependencies
2. Guide you through provider selection
3. Collect necessary information
4. Generate configuration files
5. Provide step-by-step instructions

### Option 2: Direct Configuration

If you know which provider and protocol you want:

**For Okta SAML:**
```bash
./providers/okta/configure-saml.sh
```

**For Azure AD OIDC:**
```bash
./providers/azure-ad/configure-oidc.sh
```

**For Google Workspace SAML:**
```bash
./providers/google-workspace/configure-saml.sh
```

**For OneLogin OIDC:**
```bash
./providers/onelogin/configure-oidc.sh
```

## Step-by-Step Example: Okta SAML

Here's a complete example for setting up Okta SAML:

### Step 1: Generate Configuration

```bash
./providers/okta/configure-saml.sh
```

Provide when prompted:
- Okta Domain: `dev-123456.okta.com`
- Entity ID: `https://myapp.example.com/saml/metadata`
- ACS URL: `https://myapp.example.com/saml/acs`
- Single Logout URL: (optional) `https://myapp.example.com/saml/slo`

### Step 2: Review Generated Files

```bash
ls -la output/okta/
# sp-metadata.xml
# okta-saml-config.json
```

### Step 3: Configure Okta

1. Log in to [Okta Admin Console](https://your-domain.okta.com/admin)
2. Go to **Applications** > **Applications**
3. Click **Create App Integration**
4. Select **SAML 2.0**
5. Enter application details:
   - Single Sign On URL: `https://myapp.example.com/saml/acs`
   - Audience URI: `https://myapp.example.com/saml/metadata`
6. Click **Next** and **Finish**

### Step 4: Download IdP Metadata

1. In your Okta application, go to **Sign On** tab
2. Under **SAML Signing Certificates**, click **Actions** > **View IdP metadata**
3. Save the XML as `output/okta/idp-metadata.xml`

### Step 5: Test Configuration

```bash
# Validate your metadata
./scripts/validate-saml.sh --metadata output/okta/sp-metadata.xml

# Test connection
./scripts/test-connection.sh --provider okta --protocol saml
```

### Step 6: Integrate with Your Application

Use the configuration file in your application:

```javascript
// Example: Node.js with passport-saml
const samlConfig = require('./output/okta/okta-saml-config.json');

passport.use(new SamlStrategy({
  entryPoint: samlConfig.idp_sso_url,
  issuer: samlConfig.entity_id,
  callbackUrl: samlConfig.acs_url,
  cert: fs.readFileSync('output/okta/idp-metadata.xml', 'utf8')
}));
```

## Common Workflows

### Scenario 1: New Organization Setup

```bash
# 1. Run setup wizard
./setup.sh

# 2. Choose your IdP and protocol
# 3. Follow the prompts
# 4. Configure your IdP per instructions
# 5. Test the configuration
./scripts/test-connection.sh --provider YOUR_PROVIDER --protocol YOUR_PROTOCOL
```

### Scenario 2: Certificate Rotation

```bash
# Generate new certificate
./scripts/generate-certs.sh self-signed --output ./certs --cn yourdomain.com

# Validate it
./scripts/validate-saml.sh --certificate ./certs/saml-certificate.crt

# Update your IdP with the new certificate
# Re-test connection
```

### Scenario 3: Multi-Environment Setup

```bash
# Development
./providers/okta/configure-saml.sh
# Use: https://dev.example.com/saml/acs

# Staging
./providers/okta/configure-saml.sh
# Use: https://staging.example.com/saml/acs

# Production
./providers/okta/configure-saml.sh
# Use: https://example.com/saml/acs
```

## Troubleshooting Quick Fixes

### Issue: "Invalid Signature"
```bash
# Check certificate validity
./scripts/validate-saml.sh --certificate path/to/cert.pem

# Verify clock synchronization
date
```

### Issue: "Redirect URI Mismatch"
```bash
# Verify your configuration
cat output/YOUR_PROVIDER/oidc-config.json | jq '.redirect_uri'

# Ensure it exactly matches IdP configuration (including trailing slash)
```

### Issue: "Connection Timeout"
```bash
# Test network connectivity
./scripts/test-connection.sh --network https://your-idp.com

# Check DNS resolution
nslookup your-idp.com
```

## Next Steps

After successful setup:

1. **Review Security Settings**: See [Security Best Practices](README.md#security-best-practices)
2. **Set Up Monitoring**: Monitor authentication logs for anomalies
3. **Document Your Configuration**: Keep track of your setup for team reference
4. **Test Recovery Procedures**: Test what happens if SSO is unavailable
5. **Train Your Team**: Ensure your team knows how to troubleshoot

## Need Help?

- **Documentation**: Check [docs/](docs/) for detailed guides
- **Examples**: See [examples/](examples/) for reference configurations
- **Troubleshooting**: Refer to [docs/troubleshooting.md](docs/troubleshooting.md)
- **Issues**: Open an issue on [GitHub](https://github.com/drzo/enterprise-sso-setup/issues)

## Security Checklist

Before going to production:

- [ ] Use HTTPS for all endpoints
- [ ] Implement proper certificate management
- [ ] Enable MFA in your IdP
- [ ] Set up session timeout policies
- [ ] Implement proper error handling
- [ ] Monitor authentication logs
- [ ] Test logout functionality
- [ ] Document emergency procedures
- [ ] Set up certificate expiration alerts
- [ ] Review and restrict user permissions

## Success!

Once everything is working:

```bash
# Celebrate! 🎉
echo "SSO is configured and working!"
```

Your users can now authenticate using their enterprise credentials!
