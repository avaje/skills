# Avaje Bundle — Role and Scope Authorization (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `oauth2/role-and-scope-authorization.md`

# Guide: Role and Scope Authorization

## Purpose

This guide covers how to make per-route authorization decisions using the
claims exposed by a verified `AccessToken` - required scopes via
`requireScope(...)`, and roles/groups via `AccessToken.hasRole()`/
`hasAnyRole()`.

When asked to *"restrict this endpoint to admins"*, *"require a scope for
this route"*, or *"return 403 instead of 401 for authenticated-but-forbidden
requests"*, follow this guide.

---

## Overview

avaje-oauth2 gives you two levels of authorization support:

1. **Built-in path-prefix scope enforcement** (`requireScope`) - the filter
   itself returns `403` if the token lacks all of the required scopes for a
   path prefix. Coarse-grained (path-prefix only, no HTTP method matching) -
   by design (see [docs/LIBRARY.md](../LIBRARY.md#design-philosophy)).
2. **Claims exposed for your own app-level checks** - `AccessToken.roles()`/
   `hasRole()`/`hasAnyRole()` and `scope()`/`hasScope()`/`hasAnyScope()`, via
   the `security.accessToken` attribute. Use these directly in your
   controllers/handlers for anything more granular than a path prefix (e.g.
   HTTP-method-specific rules, or role-based rather than scope-based checks).

`requireScope` only applies to JWT-authenticated requests - it has no effect
on requests accepted via a `bearerAuthoriser` (e.g. API keys), which carry no
scope claim.

---

## Option A - `requireScope` (path-prefix, scope-based, built into the filter)

```java
JwtAuthFilter filter = JwtAuthFilter.builder()
    .permit("/health")
    .verifier(jwtVerifier)
    .requireScope("/v1/admin", "insight/admin")
    .requireScope("/v1/reports", "insight/read", "insight/admin")
    .build();
```

- Rules are matched in the order added; the **first matching path prefix
  wins** (same semantics as `.permit(...)`).
- A request matching a rule whose token lacks **all** of the listed scopes
  gets `403 Forbidden` with a `WWW-Authenticate: Bearer error="insufficient_scope", scope="..."`
  header (RFC 6750 §3.1) instead of proceeding.
- A request with **no token at all**, or an **invalid** token, still gets
  `401` (RFC 6750 §3) - `requireScope` only changes the outcome for
  *validly authenticated* tokens that are missing the required scope(s).

---

## Option B - App-level role/scope checks

Use this for anything `requireScope`'s path-prefix matching can't express:
HTTP-method-specific rules, role-based (rather than scope-based) checks, or
combining multiple conditions.

### avaje-jex

```java
@Get("/admin/users")
List<User> listUsers(Context ctx) {
    AccessToken token = ctx.attribute("security.accessToken");
    if (!token.hasAnyRole("Admin", "Owner")) {
        throw new HttpResponseException(403, "Forbidden");
    }
    return userService.listAll();
}
```

### Helidon SE

```java
AccessToken token = req.context().get("security.accessToken", AccessToken.class)
    .orElseThrow(() -> new UnauthorizedException("Unauthorized"));

if (!token.hasAnyRole("Admin", "Owner")) {
    throw new ForbiddenException("Forbidden");
}
```

### `AccessToken` helper methods

| Method | Checks |
|---|---|
| `hasScope(String)` / `hasAnyScope(String...)` | The space-delimited `scope`/`scp` claim (delegated permissions) |
| `hasRole(String)` / `hasAnyRole(String...)` | `roles()` - Entra ID's `roles` claim or Cognito's `cognito:groups` claim (assigned app roles / user pool group membership) |

`roles()` is an empty list (never `null`) when neither claim is present -
safe to call `hasAnyRole(...)` unconditionally.

---

## Which one should I use?

| Need | Use |
|---|---|
| A whole path prefix requires one of a fixed set of scopes | `requireScope(pathPrefix, scopes...)` |
| Different rules per HTTP method on the same path | App-level check (Option B) - `requireScope` can't express this |
| Role-based rather than scope-based check | App-level check with `hasRole`/`hasAnyRole` - `requireScope` only checks `scope` |
| Combining a role check with other business logic (e.g. "admin OR resource owner") | App-level check |

---

## Notes

- 401 vs 403 semantics mirror Spring Security's split between
  `AuthenticationException` (401 - no/invalid credentials) and
  `AccessDeniedException` (403 - valid credentials, insufficient
  permission).
- `requireScope`'s path-prefix-only granularity is a deliberate design
  choice: the host application's own router already has full path+method
  visibility, so building a redundant matching engine into this library
  would just be a worse copy of what your framework already does. Use
  Option B for anything requiring finer granularity.

---

## References

- [docs/LIBRARY.md](../LIBRARY.md)
- RFC 6750 §3 / §3.1 (WWW-Authenticate, insufficient_scope): https://www.rfc-editor.org/rfc/rfc6750#section-3
- `avaje-oauth2-jex-jwtfilter/README.md`, `avaje-oauth2-helidon-jwtfilter/README.md`
