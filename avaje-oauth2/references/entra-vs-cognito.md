# Avaje Bundle — Entra vs Cognito Claims (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `oauth2/entra-vs-cognito-claims.md`

# Guide: Entra ID vs Cognito Claims

## Purpose

Cognito and Entra ID structure their access tokens differently. This guide
consolidates the claim-by-claim differences captured in `AccessToken`'s
javadoc, so you don't have to rediscover them by trial and error - especially
important when running both providers at once (see
[multi-issuer-migration.md](multi-issuer-migration.md)).

---

## Claim comparison

| Claim / concept | Cognito | Entra ID |
|---|---|---|
| `aud` (audience) | **Not present at all** - Cognito uses `client_id` for this purpose instead | Always present, single string value - the Application ID URI or client id. Only becomes a real JWT access token (rather than an opaque one) when the app registration exposes an API and the requested scope includes that API's custom scope |
| `email` | Not present by default | Only present when configured as an optional claim; Microsoft documents it as **unverified** - treat as a display label only, not an identity key |
| `upn` (User Principal Name) | `null` - not applicable | Entra's login identifier. Looks like an email but isn't guaranteed to be a deliverable mailbox. Populated from the `upn` claim (v2.0 tokens) or `unique_name` (v1.0's equivalent). **Not the same as `email`** - may be `null` even when `email` is present, and the two aren't guaranteed to match (hybrid AD / guest / B2B accounts) |
| Stable per-user identity | `sub` | `sub` - always use this, never `email`/`upn`, as the stable identity key |
| Roles/groups | `cognito:groups` claim - user pool group membership | `roles` claim - assigned app roles |
| Delegated scopes | `scope` claim (space-delimited) | `scope`/`scp` claim (space-delimited) |
| `nbf` (not-before) | Optional per RFC 7519 §4.1.5 | Optional per RFC 7519 §4.1.5 |
| `client_id` | The app client id | `azp`/`appid` - identifies which app requested the token |

`AccessToken` unifies the roles/groups claims into a single `roles()` field -
see [role-and-scope-authorization.md](role-and-scope-authorization.md). If a
token somehow carried both `roles` and `cognito:groups` (not a realistic
scenario in practice - a token comes from one provider), `roles()` prefers
Entra's `roles` claim.

---

## Practical implications

### Don't validate `aud` for Cognito

```java
// Cognito - do NOT set .audience(...), Cognito tokens have no aud claim
JwtVerifier cognitoVerifier = JwtVerifier.builder()
    .issuer(cognitoIssuer)
    .build();

// Entra - DO set .audience(...)
JwtVerifier entraVerifier = JwtVerifier.builder()
    .issuer(entraIssuer)
    .audience(entraClientId)
    .build();
```

### Don't assume `email`/`upn` are populated

Both are optional/provider-specific. Always key user identity off `sub()`:

```java
String userId = accessToken.sub();          // always safe
String displayLabel = accessToken.email() != null ? accessToken.email() : accessToken.upn();
```

### Entra access tokens require an exposed API + custom scope

Requesting only `openid`/`profile` from Entra ID yields tokens that **cannot
be verified as a JWT** against the tenant's JWKS at all. See
[oidc-login-flow.md](oidc-login-flow.md) for the exact scope format required
(`api://<clientId>/access_as_user` or your app registration's custom scope).

### Roles come from different claims per provider

```java
if (accessToken.hasAnyRole("Admin", "Owner")) {
    // works whether the token came from Cognito (cognito:groups) or Entra (roles)
}
```

---

## Notes

- These differences are exactly why `MultiIssuerJwtVerifier` configures each
  delegate independently (see
  [multi-issuer-migration.md](multi-issuer-migration.md)) - each provider's
  peculiarities (audience requirement, claim names) are isolated to its own
  `JwtVerifier` instance.
- If you're migrating and see tokens unexpectedly missing `aud` or `roles`,
  double check which provider actually issued that specific token - don't
  assume a schema mismatch is a bug.

---

## References

- [docs/LIBRARY.md](../LIBRARY.md)
- `AccessToken` javadoc (`avaje-oauth2-core`) - the canonical source for
  these claim descriptions
- RFC 7519 §4.1.5 (`nbf`): https://www.rfc-editor.org/rfc/rfc7519#section-4.1.5
