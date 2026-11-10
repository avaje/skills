# Avaje Bundle — OIDC Login Flow (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `oauth2/oidc-login-flow.md`

# Guide: OIDC Login Flow (Authorization Code + PKCE)

## Purpose

This guide covers driving the browser-based OAuth2 **Authorization Code**
flow (with PKCE) against AWS Cognito's Hosted UI or Microsoft Entra ID's v2.0
endpoints, using `CognitoOidc` / `EntraOidc`. This is for apps that own the
login redirect themselves (e.g. a BFF/gateway), as opposed to pure resource
servers that only verify already-issued bearer tokens (see
[getting-started.md](getting-started.md) for that case).

---

## Overview

| Step | Method |
|---|---|
| 1. Build the login (authorize) URL, redirect the user's browser to it | `.loginUrl(nonce, state)` or `.loginUrl(nonce, state, codeChallenge)` |
| 2. IdP redirects back with an authorization `code` | (your callback endpoint receives this) |
| 3. Exchange the code for tokens | `.obtainTokens(code)` or `.obtainTokens(code, codeVerifier)` |
| 4. Later, refresh the access token | `.refreshAccessToken(refreshToken)` |

Use the PKCE-enabled overloads (`codeChallenge`/`codeVerifier`) for **public
clients** (no client secret, e.g. an SPA or mobile app going through your
BFF). Generate the PKCE pair with `Pkce`:

```java
Pkce pkce = Pkce.generate();
// store pkce.verifier() server-side (session), keyed by `state`

String loginUrl = cognitoOidc.loginUrl(nonce, state, pkce.challenge());
// redirect the browser to loginUrl

// ... later, in the callback handler ...
OidcTokens tokens = cognitoOidc.obtainTokens(code, pkce.verifier());
```

---

## Step 1 - Add the dependency

```xml
<!-- pick ONE, matching your identity provider -->
<dependency>
    <groupId>io.avaje</groupId>
    <artifactId>avaje-oauth2-oidc-cognito</artifactId>
    <version>${avaje.oauth2.version}</version>
</dependency>
<!-- or -->
<dependency>
    <groupId>io.avaje</groupId>
    <artifactId>avaje-oauth2-oidc-entra</artifactId>
    <version>${avaje.oauth2.version}</version>
</dependency>
```

---

## Step 2 - Build the OIDC client

### Cognito

```java
CognitoOidc cognitoOidc = CognitoOidc.builder()
    .userPoolId(userPoolId)
    .domain(cognitoDomain)          // the Hosted UI domain
    .clientId(clientId)
    .clientSecret(clientSecret)     // omit/null for a public client
    .redirectUri(redirectUri)
    .scope("openid profile email")
    .build();
```

### Entra ID

```java
EntraOidc entraOidc = EntraOidc.builder()
    .tenantId(tenantId)             // derives authorize/token endpoints
    .clientId(clientId)
    .clientSecret(clientSecret)     // omit/null for a public client
    .redirectUri(redirectUri)
    .scope("openid profile api://" + clientId + "/access_as_user")
    .build();
```

> **Entra caveat**: requesting only `openid`/`profile` will **not** yield a
> JWT access token that can be validated against the tenant's JWKS. The app
> registration must expose an API (Application ID URI + custom scope) and the
> requested `scope` must include that resource scope for the resulting access
> token to be a verifiable JWT with `aud` == the client id. See
> [entra-vs-cognito-claims.md](entra-vs-cognito-claims.md).

---

## Step 3 - Redirect to the login URL

```java
String nonce = generateRandomNonce();
String state = generateRandomState();   // store both server-side, keyed to the user's session

String loginUrl = entraOidc.loginUrl(nonce, state);
// respond with a redirect to loginUrl
```

For a public client, generate a `Pkce` first and pass its challenge:

```java
Pkce pkce = Pkce.generate();
String loginUrl = entraOidc.loginUrl(nonce, state, pkce.challenge());
// store pkce.verifier() alongside state/nonce for the callback step
```

---

## Step 4 - Handle the callback and exchange the code

In your redirect-URI callback handler:

```java
String code = ctx.queryParam("code");
String returnedState = ctx.queryParam("state");
// verify returnedState matches the stored state, then:

OidcTokens tokens = entraOidc.obtainTokens(code, storedPkceVerifier);
// or, for a confidential client without PKCE:
// OidcTokens tokens = entraOidc.obtainTokens(code);
```

`OidcTokens` carries the raw `id_token`/`access_token`/`refresh_token`
strings. Verify the access token with a `JwtVerifier` (see
[getting-started.md](getting-started.md)) before trusting its claims.

---

## Step 5 - Refresh when the access token expires

```java
OidcTokens refreshed = entraOidc.refreshAccessToken(storedRefreshToken);
```

---

## Notes

- `nonce`/`state` generation, storage, and validation are the caller's
  responsibility - this library doesn't manage sessions.
- Both `CognitoOidc` and `EntraOidc` expose the same shape of builder/methods;
  only the constructor parameters differ (`userPoolId`/`domain` for Cognito
  vs `tenantId`/`domain` for Entra).
- Always verify the returned `state` matches what you generated before
  exchanging the code - this library does not do that for you.

---

## References

- [docs/LIBRARY.md](../LIBRARY.md)
- RFC 7636 (PKCE): https://www.rfc-editor.org/rfc/rfc7636
- RFC 6749 §4.1 (Authorization Code Grant): https://www.rfc-editor.org/rfc/rfc6749#section-4.1
