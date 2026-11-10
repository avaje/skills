---
name: avaje-oauth2
description: Avaje OAuth2 JWT verification and OIDC login (Cognito, Entra ID). JwtVerifier, MultiIssuerJwtVerifier, AccessToken, jex/Helidon JwtAuthFilter, role/scope authorization, PKCE login flow, JWKS tuning. Use when working with avaje-oauth2 for resource-server JWT verification or OAuth2 Authorization Code + PKCE login.
---

# Avaje OAuth2

Avaje OAuth2 provides JWT access-token verification (`JwtVerifier`) for any
standards-based OIDC issuer (AWS Cognito, Microsoft Entra ID, or a generic
issuer + JWKS), plus ready-made HTTP filters for `avaje-jex` and Helidon SE,
and OAuth2 Authorization Code + PKCE login clients for Cognito and Entra ID.

It is a JWT verification + claims-exposure library, **not** a full
authorization/RBAC framework — no `@RolesAllowed`, no request-matcher DSL, no
HTTP-method-specific rules. Scope/role checks are path-prefix only
(`requireScope`); anything more granular is the host app's own router's job.

## Key Principles

- `JwtVerifier` verifies signature (JWKS), `exp`/`iat`/`nbf`, issuer, and
  optionally `aud` — returns an `AccessToken` with claim accessors
- `JwtAuthFilter` (jex/Helidon) wires a `JwtVerifier` into HTTP request
  handling: `permit(...)` for public paths, `requireScope(...)` for
  scope-gated paths, exposes `security.accessToken`/`security.principal`/
  `security.scope`/`security.roles` request attributes
- `MultiIssuerJwtVerifier` composes several single-issuer `JwtVerifier`s for
  phased identity-provider migrations (e.g. Cognito → Entra) — routes on the
  unverified `iss` claim, then the delegate does full verification
- `CognitoOidc`/`EntraOidc` + `Pkce` drive the browser-based Authorization
  Code + PKCE login flow (CLI or BFF/gateway use case)
- Entra ID requires an exposed API + custom scope for a verifiable JWT access
  token (unlike Cognito) — see the entra-vs-cognito reference

## Task Guides

Load the relevant reference guide for the current task. **Only load what you need.**

| Task | Reference |
|------|-----------|
| Build a `JwtVerifier`, wire into jex/Helidon filter, context attributes | [setup](references/setup.md) |
| Authorization Code + PKCE login flow (Cognito/Entra + `Pkce`) | [oidc-login](references/oidc-login.md) |
| `requireScope`, `hasScope`/`hasRole` app-level checks | [authorization](references/authorization.md) |
| Accepting tokens from multiple issuers (migration/multi-tenant) | [multi-issuer](references/multi-issuer.md) |
| JWKS refresh throttling, clock skew, custom `JwtKeySource` | [jwks-tuning](references/jwks-tuning.md) |
| Claim differences between Cognito and Entra ID | [entra-vs-cognito](references/entra-vs-cognito.md) |

## Quick Reference

### Dependency

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-oauth2-core</artifactId>
</dependency>
<!-- plus one filter module: -->
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-oauth2-jex-jwtfilter</artifactId>
  <!-- or avaje-oauth2-helidon-jwtfilter -->
</dependency>
```

### Build a verifier and filter

```java
JwtVerifier jwtVerifier = JwtVerifier.builder()
    .issuer(issuer)          // JWKS uri defaults to {issuer}/.well-known/jwks.json
    .audience(clientId)      // optional (required for Entra)
    .build();

JwtAuthFilter filter = JwtAuthFilter.builder()
    .permit("/health")
    .requireScope("/admin", "admin")
    .verifier(jwtVerifier)
    .build();
```

### Multi-issuer (migration)

```java
JwtVerifier verifier = MultiIssuerJwtVerifier.builder()
    .addIssuer(cognitoIssuer, cognitoVerifier)
    .addIssuer(entraIssuer, entraVerifier)
    .build();
```

### Role/scope checks

```java
AccessToken token = (AccessToken) ctx.attribute("security.accessToken");
if (token.hasAnyRole("Admin", "Owner") || token.hasScope("read:reports")) { ... }
```

## Regenerating References

```bash
cd /path/to/avaje/skills && ./generate-references.sh
```
