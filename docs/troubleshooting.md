# Troubleshooting Guide

This guide covers common issues encountered when setting up enterprise SSO and their solutions.

## Table of Contents

- [SAML Issues](#saml-issues)
- [OIDC Issues](#oidc-issues)
- [Certificate Issues](#certificate-issues)
- [Network Issues](#network-issues)
- [Configuration Issues](#configuration-issues)
- [Testing Issues](#testing-issues)

## SAML Issues

### Issue: SAML Assertion Signature Validation Failed

**Symptoms:**
- Error message about invalid signature
- Authentication fails after IdP redirect
- Logs show signature verification errors

**Possible Causes & Solutions:**

1. **Certificate Mismatch**
   ```bash
   # Verify certificate from IdP metadata
   ./scripts/validate-saml.sh --certificate idp-certificate.pem
   
   # Check certificate expiration
   openssl x509 -in idp-certificate.pem -noout -dates
   ```
   
   Solution: Download the latest certificate from your IdP

2. **Clock Synchronization**
   ```bash
   # Check system time
   date
   
   # Sync time (Linux)
   sudo ntpdate -s time.nist.gov
   
   # Sync time (macOS)
   sudo sntp -sS time.apple.com
   ```
   
   Solution: Ensure SP and IdP clocks are synchronized (within 5 minutes)

3. **Incorrect Certificate Format**
   ```bash
   # Convert DER to PEM if needed
   openssl x509 -inform der -in cert.der -out cert.pem
   ```

4. **XML Canonicalization Issues**
   - Verify XML is well-formed
   - Check for extra whitespace or line endings
   - Validate with: `xmllint --noout metadata.xml`

### Issue: Invalid Audience Restriction

**Symptoms:**
- Error: "Audience restriction validation failed"
- SAML response received but user not authenticated

**Solution:**
1. Check Entity ID in SP metadata matches AudienceRestriction in SAML response
2. Verify Entity ID configuration in IdP
3. Entity IDs are case-sensitive and must match exactly

```bash
# Extract audience from SAML response
xmllint --xpath '//*[local-name()="Audience"]/text()' saml-response.xml

# Compare with your Entity ID
grep entityID sp-metadata.xml
```

### Issue: SAML Response Timeout

**Symptoms:**
- Error: "SAML response is too old"
- Authentication fails intermittently

**Solution:**
1. Check NotBefore and NotOnOrAfter times in assertion
2. Verify clock synchronization between SP and IdP
3. Increase assertion validity window if too short

```xml
<saml:Conditions
    NotBefore="2024-01-01T12:00:00Z"
    NotOnOrAfter="2024-01-01T12:05:00Z">
```

### Issue: Missing or Incorrect Attributes

**Symptoms:**
- User authenticated but profile incomplete
- Missing email, name, or other attributes

**Solution:**
1. Check attribute mapping in IdP configuration
2. Verify attribute statements in SAML response
3. Update attribute mapping in SP configuration

```bash
# Extract attributes from SAML response
xmllint --xpath '//*[local-name()="Attribute"]' saml-response.xml
```

## OIDC Issues

### Issue: Invalid Client Credentials

**Symptoms:**
- Error: "invalid_client"
- Token exchange fails
- 401 Unauthorized response

**Solution:**
1. Verify Client ID is correct
2. Verify Client Secret is correct (no extra spaces)
3. Check if secret has expired
4. Regenerate credentials if necessary

```bash
# Test credentials
curl -X POST https://idp.example.com/oauth2/v1/token \
  -u "CLIENT_ID:CLIENT_SECRET" \
  -d "grant_type=client_credentials"
```

### Issue: Redirect URI Mismatch

**Symptoms:**
- Error: "redirect_uri_mismatch"
- Authorization fails immediately

**Solution:**
1. Ensure redirect URI in request exactly matches registered URI
2. Check protocol (http vs https)
3. Check port number
4. Check trailing slashes
5. URIs are case-sensitive

```javascript
// Correct
redirect_uri: "https://example.com/oauth/callback"

// Incorrect (missing trailing slash if registered with it)
redirect_uri: "https://example.com/oauth/callback/"

// Incorrect (wrong protocol)
redirect_uri: "http://example.com/oauth/callback"
```

### Issue: Invalid Token Signature

**Symptoms:**
- Token validation fails
- Error: "invalid signature"

**Solution:**
1. Verify you're using correct JWKS endpoint
2. Check token algorithm matches expected algorithm
3. Ensure kid (key ID) in token header exists in JWKS

```bash
# Fetch and verify JWKS
curl https://idp.example.com/.well-known/jwks.json | jq

# Decode token header to check kid and alg
echo "TOKEN_HEADER" | base64 -d | jq
```

### Issue: Token Expired

**Symptoms:**
- Error: "token expired"
- Valid tokens suddenly fail

**Solution:**
1. Check exp claim in token
2. Implement token refresh logic
3. Request new tokens before expiration

```javascript
// Check token expiration
const payload = JSON.parse(atob(token.split('.')[1]));
const expirationTime = payload.exp * 1000;
const currentTime = Date.now();

if (currentTime >= expirationTime) {
  // Token expired, refresh it
  refreshToken();
}
```

### Issue: Scope Permission Denied

**Symptoms:**
- Error: "insufficient_scope"
- Unable to access certain resources

**Solution:**
1. Request appropriate scopes during authorization
2. Verify scopes in access token
3. Check IdP configuration for scope availability

```bash
# Decode access token to check scopes
echo "ACCESS_TOKEN_PAYLOAD" | base64 -d | jq '.scope'
```

## Certificate Issues

### Issue: Certificate Expired

**Symptoms:**
- SSL/TLS errors
- Certificate validation failures

**Solution:**
```bash
# Check certificate expiration
openssl x509 -in certificate.pem -noout -enddate

# Generate new certificate
./scripts/generate-certs.sh self-signed --output ./certs --cn yourdomain.com
```

### Issue: Certificate Chain Incomplete

**Symptoms:**
- Error: "unable to get local issuer certificate"
- Certificate validation fails

**Solution:**
1. Include intermediate certificates in chain
2. Download full certificate chain from IdP
3. Concatenate certificates in correct order (leaf → intermediate → root)

```bash
# Create certificate bundle
cat server-cert.pem intermediate-cert.pem root-cert.pem > fullchain.pem
```

### Issue: Self-Signed Certificate Not Trusted

**Symptoms:**
- SSL verification errors in development
- Certificate not trusted by browsers

**Solution:**
1. Add certificate to trusted store (development only)
2. Use proper CA-signed certificate in production

```bash
# Add to trusted store (Ubuntu)
sudo cp certificate.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Add to trusted store (macOS)
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certificate.crt
```

## Network Issues

### Issue: Unable to Reach IdP Endpoints

**Symptoms:**
- Connection timeout
- DNS resolution failures
- Network errors

**Solution:**
```bash
# Test DNS resolution
nslookup idp.example.com

# Test connectivity
curl -v https://idp.example.com/.well-known/openid-configuration

# Check firewall rules
./scripts/test-connection.sh --network https://idp.example.com
```

### Issue: SSL/TLS Handshake Failed

**Symptoms:**
- Error: "SSL handshake failed"
- Connection refused

**Solution:**
1. Verify SSL certificate is valid
2. Check TLS version compatibility
3. Verify cipher suite support

```bash
# Test SSL connection
openssl s_client -connect idp.example.com:443 -tls1_2

# Check supported ciphers
nmap --script ssl-enum-ciphers -p 443 idp.example.com
```

### Issue: CORS Errors (OIDC)

**Symptoms:**
- Browser console: "CORS policy blocked"
- Cannot fetch from IdP in browser

**Solution:**
1. Add your domain to IdP's trusted origins
2. Configure CORS headers properly
3. Use backend proxy for token exchange (recommended)

## Configuration Issues

### Issue: Wrong Endpoint URLs

**Symptoms:**
- 404 Not Found errors
- Incorrect redirects

**Solution:**
```bash
# Verify discovery document
curl https://idp.example.com/.well-known/openid-configuration | jq

# Test each endpoint
./scripts/validate-oidc.sh --endpoints https://idp.example.com
```

### Issue: Missing Required Parameters

**Symptoms:**
- Error: "invalid_request"
- Missing parameter errors

**Solution:**
1. Review IdP documentation for required parameters
2. Check request payload completeness
3. Validate configuration file

```bash
# Validate SAML metadata
./scripts/validate-saml.sh --metadata sp-metadata.xml

# Validate OIDC config
./scripts/validate-oidc.sh --config oidc-config.json
```

### Issue: Incorrect Attribute Mapping

**Symptoms:**
- User profile incomplete
- Wrong data in user attributes

**Solution:**
1. Check attribute names in IdP
2. Verify mapping configuration
3. Review SAML assertion or ID token claims

## Testing Issues

### Issue: Test User Cannot Authenticate

**Symptoms:**
- Authentication fails for test users
- Production users work fine

**Solution:**
1. Verify test user is assigned to application in IdP
2. Check user's group membership
3. Verify user account is active
4. Check for conditional access policies

### Issue: Inconsistent Behavior Between Environments

**Symptoms:**
- Works in staging but not production
- Works in production but not development

**Solution:**
1. Compare configurations across environments
2. Verify redirect URIs are registered for each environment
3. Check certificate differences
4. Review environment-specific settings

```bash
# Compare configurations
diff staging-config.json production-config.json
```

## Debugging Tips

### Enable Debug Logging

1. **SAML debugging:**
   - Enable verbose logging in your SAML library
   - Log full SAML requests and responses
   - Use browser developer tools to inspect redirects

2. **OIDC debugging:**
   - Log authorization URLs
   - Log token responses (mask sensitive data)
   - Use jwt.io to decode tokens

### Use Online Tools

- **SAML Tracer** (Browser extension): Capture SAML messages
- **jwt.io**: Decode and verify JWT tokens
- **SAML Response Decoder**: Decode base64-encoded SAML responses
- **Postman**: Test OIDC token endpoints

### Common Commands

```bash
# Decode base64-encoded SAML response
echo "SAML_RESPONSE" | base64 -d | xmllint --format -

# Decode JWT token
echo "JWT_TOKEN" | cut -d'.' -f2 | base64 -d | jq

# Test IdP metadata accessibility
curl -v https://idp.example.com/metadata.xml

# Verify SSL certificate
echo | openssl s_client -connect idp.example.com:443 2>/dev/null | openssl x509 -noout -dates
```

## Getting Help

If you're still experiencing issues:

1. Check IdP documentation for provider-specific issues
2. Review application logs for detailed error messages
3. Enable debug logging for more information
4. Contact IdP support with specific error messages
5. Open an issue in this repository with:
   - Provider name and version
   - Error messages (sanitized)
   - Steps to reproduce
   - Configuration (with secrets removed)

## Additional Resources

- [SAML 2.0 Technical Overview](https://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html)
- [OpenID Connect Debugging](https://openid.net/specs/openid-connect-core-1_0.html#AuthError)
- [OAuth 2.0 Error Codes](https://tools.ietf.org/html/rfc6749#section-4.1.2.1)
