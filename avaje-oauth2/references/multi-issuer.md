# Avaje Bundle — Multi-Issuer Migration (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `oauth2/multi-issuer-migration.md`

# Guide: Multi-Issuer Migration (Cognito ⇄ Entra ID)

## Purpose

This guide covers accepting JWT access tokens from **more than one trusted
issuer at once** using `MultiIssuerJwtVerifier` - typically so an API can
accept both old (Cognito) and new (Entra ID) tokens during a phased identity
provider migration, without a hard flag-day cutover.

When asked to *"support both Cognito and Entra during the migration"*, or
*"accept tokens from multiple issuers"*, follow this guide.

---

## Why this exists

A single `JwtVerifier` only trusts one issuer (one JWKS, one optional
audience). Without multi-issuer support, migrating identity providers means
either:
- A hard cutover (every client must switch at the same instant), or
- Running two separate APIs/filters and somehow routing between them

`MultiIssuerJwtVerifier` avoids both - it's a single `JwtVerifier` that
dispatches to the correct per-issuer delegate based on the token's `iss`
claim, so old and new clients can hit the **same** filter/endpoint
simultaneously.

This mirrors the same pattern Spring Security's own documented multi-tenant
`JwtDecoder` example uses (peek at the unverified `iss` claim to select a
decoder, then let that decoder do full verification).

---

## Step 1 - Build a delegate `JwtVerifier` per issuer

Each delegate keeps its own issuer, audience, JWKS/keySource, and clock-skew
settings - configure each exactly as you would for a single-issuer setup
(see [getting-started.md](getting-started.md)):

```java
JwtVerifier cognitoVerifier = JwtVerifier.builder()
    .issuer(cognitoIssuer)
    .build();

JwtVerifier entraVerifier = JwtVerifier.builder()
    .issuer(entraIssuer)
    .audience(entraClientId)   // only Entra needs this
    .build();
```

---

## Step 2 - Compose them into a `MultiIssuerJwtVerifier`

```java
JwtVerifier verifier = MultiIssuerJwtVerifier.builder()
    .addIssuer(cognitoIssuer, cognitoVerifier)
    .addIssuer(entraIssuer, entraVerifier)
    .build();
```

The `issuer` string passed to `addIssuer` must exactly match that delegate's
expected `iss` claim value (the same string passed to `.issuer(...)` when
building it).

---

## Step 3 - Use it exactly like a single-issuer `JwtVerifier`

`MultiIssuerJwtVerifier.builder()...build()` returns a plain `JwtVerifier` -
no filter changes needed:

```java
JwtAuthFilter filter = JwtAuthFilter.builder()
    .permit("/health")
    .verifier(verifier)   // the multi-issuer verifier, drop-in
    .build();
```

---

## How it works (and why it's safe)

1. The composite reads the (**unverified**) `iss` claim from the token
   payload - purely to decide which delegate to try.
2. It dispatches to the matching delegate's `verifyAccessToken(...)`, which
   then performs **full signature verification** against that issuer's own
   registered keys, plus all of its normal claim checks (`exp`, `iat`, `nbf`,
   `iss` re-checked, optional `aud`).
3. A token with a forged/mismatched `iss` claim only ever routes to a
   verifier that will then fail signature verification (the attacker doesn't
   have that issuer's private key) - or isn't registered at all, in which
   case it's rejected immediately as `"Jwt unexpected issuer"`.

Reading `iss` before verification is safe specifically *because* it's only
used for **routing**, never for a trust decision - the actual trust decision
(signature verification) always happens per-delegate afterwards.

---

## Notes

- `MultiIssuerJwtVerifier.Builder.build()` throws `IllegalStateException` if
  no issuers were registered.
- There's no limit to the number of issuers you can register - this also
  works for genuinely multi-tenant setups (different tenants using different
  issuers), not just two-provider migrations.
- Once the migration is complete and all clients have moved to the new
  issuer, simply go back to building a single `JwtVerifier` for the new
  issuer and remove `MultiIssuerJwtVerifier` - no filter changes needed
  either way.

---

## References

- [docs/LIBRARY.md](../LIBRARY.md)
- [entra-vs-cognito-claims.md](entra-vs-cognito-claims.md) - claim
  differences to account for when both issuers are active simultaneously
- `avaje-oauth2-core/README.md`
