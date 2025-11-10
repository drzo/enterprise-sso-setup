# OpenID Connect (OIDC) Setup Guide

## Overview

OpenID Connect (OIDC) is an identity layer built on top of OAuth 2.0. It allows clients to verify the identity of users and obtain basic profile information. This guide explains how to set up OIDC SSO with your enterprise Identity Provider.

## Prerequisites

- Administrative access to your Identity Provider
- Administrative access to your application
- Understanding of OAuth 2.0 flows
- SSL/TLS certificates for production environments

## OIDC Components

### Relying Party (RP)
Your application that relies on the IdP for authentication.

**Key elements:**
- **Client ID**: Unique identifier for your application
- **Client Secret**: Secret credential for confidential clients
- **Redirect URI**: Where IdP sends authentication responses
- **Scopes**: Permissions requested (openid, profile, email)

### OpenID Provider (OP)
The system that authenticates users and issues tokens.

**Key elements:**
- **Issuer URL**: Base URL of the OP
- **Authorization Endpoint**: Where authentication requests are sent
- **Token Endpoint**: Where tokens are exchanged
- **UserInfo Endpoint**: Where user information is retrieved
- **JWKS URI**: Where signing keys are published

## Setup Steps

### 1. Register Application

Register your application with the IdP:

```bash
./providers/okta/configure-oidc.sh
# or
./providers/azure-ad/configure-oidc.sh
# or
./providers/google-workspace/configure-oidc.sh
# or
./providers/onelogin/configure-oidc.sh
```

### 2. Obtain Credentials

After registration, you'll receive:
- **Client ID**: Public identifier for your app
- **Client Secret**: Keep this secure and never expose it

Example:
```
Client ID: 0oa2abc3defg4HIJK5lm
Client Secret: 1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t
```

### 3. Configure Endpoints

Discover or configure OIDC endpoints:

```bash
# Test discovery endpoint
./scripts/validate-oidc.sh --endpoints https://accounts.google.com
```

Standard endpoints structure:
```
https://idp.example.com/.well-known/openid-configuration
https://idp.example.com/oauth2/v1/authorize
https://idp.example.com/oauth2/v1/token
https://idp.example.com/oauth2/v1/userinfo
https://idp.example.com/oauth2/v1/keys
```

### 4. Set Redirect URIs

Configure allowed redirect URIs in your IdP:

- Production: `https://yourdomain.com/oauth/callback`
- Staging: `https://staging.yourdomain.com/oauth/callback`
- Development: `http://localhost:3000/oauth/callback`

**Important**: URIs must match exactly (including protocol, port, and path).

### 5. Configure Application

Create OIDC configuration in your application:

```json
{
  "client_id": "YOUR_CLIENT_ID",
  "client_secret": "YOUR_CLIENT_SECRET",
  "issuer": "https://idp.example.com",
  "redirect_uri": "https://yourdomain.com/oauth/callback",
  "scope": "openid profile email",
  "response_type": "code",
  "grant_type": "authorization_code"
}
```

### 6. Implement Authorization Code Flow

#### Step 1: Generate Authorization URL

```
https://idp.example.com/oauth2/v1/authorize?
  client_id=YOUR_CLIENT_ID&
  response_type=code&
  scope=openid%20profile%20email&
  redirect_uri=https://yourdomain.com/oauth/callback&
  state=RANDOM_STATE_VALUE&
  nonce=RANDOM_NONCE_VALUE
```

#### Step 2: User Authenticates

User is redirected to IdP, logs in, and consents.

#### Step 3: Receive Authorization Code

IdP redirects back to your redirect URI:
```
https://yourdomain.com/oauth/callback?
  code=AUTHORIZATION_CODE&
  state=RANDOM_STATE_VALUE
```

#### Step 4: Exchange Code for Tokens

POST to token endpoint:
```bash
curl -X POST https://idp.example.com/oauth2/v1/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=AUTHORIZATION_CODE" \
  -d "redirect_uri=https://yourdomain.com/oauth/callback" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

Response:
```json
{
  "access_token": "eyJraWQiOiI...",
  "id_token": "eyJraWQiOiJ...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "openid profile email"
}
```

#### Step 5: Validate ID Token

Validate the ID token:
1. Verify signature using JWKS
2. Verify issuer matches expected issuer
3. Verify audience matches your client_id
4. Check expiration time (exp claim)
5. Verify nonce matches the one sent

#### Step 6: Get User Info

Use access token to get user information:
```bash
curl -X GET https://idp.example.com/oauth2/v1/userinfo \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

Response:
```json
{
  "sub": "00uid4BxXw6I6TV4m0g3",
  "name": "John Doe",
  "email": "john.doe@example.com",
  "email_verified": true,
  "given_name": "John",
  "family_name": "Doe"
}
```

### 7. Test Configuration

```bash
./scripts/test-connection.sh --provider okta --protocol oidc
./scripts/validate-oidc.sh --config output/okta/oidc-config.json
```

## OIDC Scopes

### Standard Scopes

| Scope | Description | Claims Included |
|-------|-------------|----------------|
| openid | Required for OIDC | sub |
| profile | User profile info | name, family_name, given_name, picture, etc. |
| email | Email address | email, email_verified |
| address | Postal address | address |
| phone | Phone number | phone_number, phone_number_verified |
| offline_access | Refresh token | N/A |

### Custom Scopes

Define custom scopes for your application:
```json
{
  "scope": "openid profile email custom:groups custom:roles"
}
```

## Token Types

### ID Token

JWT containing user identity information:
```json
{
  "iss": "https://idp.example.com",
  "sub": "00uid4BxXw6I6TV4m0g3",
  "aud": "YOUR_CLIENT_ID",
  "exp": 1690000000,
  "iat": 1689996400,
  "nonce": "RANDOM_NONCE_VALUE",
  "email": "john.doe@example.com",
  "name": "John Doe"
}
```

### Access Token

Opaque or JWT token for accessing protected resources:
```
eyJraWQiOiJyc2ExIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiIw...
```

### Refresh Token

Long-lived token for obtaining new access tokens:
```
FGL8xjf3lKOi9G5zq2xR3v7B4pN8wH6sT9mY0kL1cD2eA3fU4g
```

## Security Best Practices

### State Parameter
Always use state parameter to prevent CSRF:
```javascript
const state = crypto.randomBytes(16).toString('hex');
// Store state in session
// Verify state when receiving callback
```

### Nonce Parameter
Use nonce to prevent replay attacks:
```javascript
const nonce = crypto.randomBytes(16).toString('hex');
// Store nonce in session
// Verify nonce in ID token
```

### PKCE (Proof Key for Code Exchange)
Implement PKCE for additional security:
```javascript
const codeVerifier = crypto.randomBytes(32).toString('base64url');
const codeChallenge = crypto.createHash('sha256')
  .update(codeVerifier)
  .digest('base64url');
```

### Token Validation
Always validate tokens:
- Verify signature using JWKS
- Check issuer (iss claim)
- Verify audience (aud claim)
- Check expiration (exp claim)
- Verify issued-at time (iat claim)

### Client Secret Protection
- Never expose client secret in client-side code
- Use environment variables
- Rotate secrets regularly
- Use different secrets for different environments

### HTTPS Only
- Always use HTTPS in production
- Never send tokens over HTTP
- Implement HSTS headers

## Common Claims

Standard OIDC claims in ID token:

| Claim | Description | Example |
|-------|-------------|---------|
| sub | Subject identifier | "00uid4BxXw6I6TV4m0g3" |
| iss | Issuer | "https://idp.example.com" |
| aud | Audience | "YOUR_CLIENT_ID" |
| exp | Expiration time | 1690000000 |
| iat | Issued at time | 1689996400 |
| auth_time | Authentication time | 1689996390 |
| nonce | Nonce value | "abc123" |
| email | Email address | "john.doe@example.com" |
| email_verified | Email verified | true |
| name | Full name | "John Doe" |
| given_name | First name | "John" |
| family_name | Last name | "Doe" |
| picture | Profile picture URL | "https://..." |

## Troubleshooting

See [troubleshooting.md](troubleshooting.md) for common issues and solutions.

## Advanced Configuration

### Refresh Tokens

Request offline_access scope for refresh tokens:
```json
{
  "scope": "openid profile email offline_access"
}
```

Use refresh token to get new access token:
```bash
curl -X POST https://idp.example.com/oauth2/v1/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=REFRESH_TOKEN" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

### Token Revocation

Revoke tokens when user logs out:
```bash
curl -X POST https://idp.example.com/oauth2/v1/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=ACCESS_TOKEN" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"
```

### Logout

Implement proper logout:
```
https://idp.example.com/oauth2/v1/logout?
  id_token_hint=ID_TOKEN&
  post_logout_redirect_uri=https://yourdomain.com/logged-out
```

## Resources

- [OpenID Connect Core Specification](https://openid.net/specs/openid-connect-core-1_0.html)
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [JWT RFC 7519](https://tools.ietf.org/html/rfc7519)
- [PKCE RFC 7636](https://tools.ietf.org/html/rfc7636)
- [OpenID Connect Discovery](https://openid.net/specs/openid-connect-discovery-1_0.html)
