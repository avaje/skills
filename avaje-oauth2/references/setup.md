# Avaje Bundle — Setup (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `oauth2/getting-started.md`

# Guide: Getting Started with avaje-oauth2

## Purpose

This guide covers the minimal setup to verify JWT access tokens (Cognito or
Entra ID) in a resource-server API, and wire that verification into an
`avaje-jex` or Helidon SE HTTP filter so protected endpoints automatically
require a valid bearer token.

When asked to *"add JWT authentication"*, *"verify Cognito/Entra tokens"*, or
*"protect endpoints with a bearer token"*, follow these steps.

---

## Overview

Two things need to exist:

| Component | Purpose |
|---|---|
| `JwtVerifier` | Verifies a token's signature (against a JWKS) and standard claims (`exp`, `iat`, `nbf`, `iss`, optional `aud`) |
| `JwtAuthFilter` | The HTTP filter (avaje-jex or Helidon SE) that extracts the `Authorization: Bearer` header, calls the verifier, and rejects invalid/missing tokens with a `401` |

Add the dependencies:

```xml
<dependency>
    <groupId>io.avaje</groupId>
    <artifactId>avaje-oauth2-core</artifactId>
    <version>${avaje.oauth2.version}</version>
</dependency>

<!-- pick ONE, matching your web framework -->
<dependency>
    <groupId>io.avaje</groupId>
    <artifactId>avaje-oauth2-jex-jwtfilter</artifactId>
    <version>${avaje.oauth2.version}</version>
</dependency>
<!-- or -->
<dependency>
    <groupId>io.avaje</groupId>
    <artifactId>avaje-oauth2-helidon-jwtfilter</artifactId>
    <version>${avaje.oauth2.version}</version>
</dependency>
```

---

## Step 1 - Build a `JwtVerifier` for your issuer

### Cognito

Cognito access tokens don't carry an `aud` claim, so don't call `.audience(...)`.

```java
String issuer = "https://cognito-idp.<region>.amazonaws.com/<region>_<poolId>";

JwtVerifier jwtVerifier = JwtVerifier.builder()
    .issuer(issuer)
    .build();
```

### Entra ID

Entra ID access tokens always carry `aud`. For it to be a **verifiable JWT**
at all (rather than an opaque token), the app registration must expose an API
(an Application ID URI + custom scope, e.g. `api://<clientId>/access_as_user`)
and the client must request that scope - requesting only `openid`/`profile`
is not enough. Set `.audience(...)` to the app's client id / Application ID
URI:

```java
String issuer = "https://login.microsoftonline.com/<tenantId>/v2.0";

JwtVerifier jwtVerifier = JwtVerifier.builder()
    .issuer(issuer)
    .audience(entraClientId)
    .build();
```

See [entra-vs-cognito-claims.md](entra-vs-cognito-claims.md) for the full
claim-by-claim comparison.

---

## Step 2 - Wire the verifier into a filter

### avaje-jex

```java
JwtAuthFilter filter = JwtAuthFilter.builder()
    .permit("/health")
    .verifier(jwtVerifier)
    .build();

Jex.create()
    .filter(filter)
    .port(8080)
    .start();
```

### Helidon SE

```java
JwtAuthFilter filter = JwtAuthFilter.builder()
    .permit("/health")
    .verifier(jwtVerifier)
    .build();

WebServer.builder()
    .routing(routing -> routing.addFilter(filter))
    .port(8080)
    .build()
    .start();
```

`.permit(pathPrefix)` allows requests whose path starts with the given prefix
through without requiring a token at all (e.g. health checks) - rules are
matched in the order added, first match wins.

---

## Step 3 - Use the verified token in downstream handlers

Both filters register the verified `AccessToken` (plus a few individual
convenience attributes) so downstream handlers can make their own
authorization decisions:

| Attribute key | Type | Content |
|---|---|---|
| `security.accessToken` | `AccessToken` | The full verified token |
| `security.principal` | `String` (jex) / `Principal` (Helidon) | The `sub` claim - stable per-user identifier |
| `security.scope` | `String` | The raw `scope`/`scp` claim |
| `security.roles` | `List<String>` | Mapped roles/groups (Helidon only registers this today - see [role-and-scope-authorization.md](role-and-scope-authorization.md)) |

```java
// jex
AccessToken token = ctx.attribute("security.accessToken");

// Helidon
AccessToken token = ctx.context().get("security.accessToken", AccessToken.class).orElseThrow();
```

---

## Step 4 - Verify

```bash
mvn compile
```

Then test with a real (or test-issued) bearer token:

```bash
curl -i http://localhost:8080/api/protected \
  -H "Authorization: Bearer <token>"
```

Expected: `200` for a valid token, `401` with a `WWW-Authenticate` header for
a missing/invalid token.

---

## Notes

- A missing/malformed `Authorization` header, or a token that fails signature
  or claim verification, both result in `401` with an RFC 6750
  `WWW-Authenticate` challenge header - see
  [role-and-scope-authorization.md](role-and-scope-authorization.md) for the
  403 (insufficient-scope) case.
- `JwtVerifier.builder()` derives `jwksUri` from `issuer` automatically
  (`{issuer}/.well-known/jwks.json`-style) - only set `.jwksUri(...)`
  explicitly if the JWKS lives somewhere non-standard.
- For accepting tokens from **more than one issuer** at once (e.g. migrating
  from Cognito to Entra), see
  [multi-issuer-migration.md](multi-issuer-migration.md) instead of building
  two separate filters.

---

## References

- [docs/LIBRARY.md](../LIBRARY.md) - full capability reference
- `avaje-oauth2-core/README.md`, `avaje-oauth2-jex-jwtfilter/README.md`,
  `avaje-oauth2-helidon-jwtfilter/README.md` - per-module reference docs
