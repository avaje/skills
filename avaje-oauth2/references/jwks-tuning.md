# Avaje Bundle — JWKS Tuning (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `oauth2/jwks-tuning.md`

# Guide: JWKS Tuning

## Purpose

This guide covers tuning how `JwtVerifier` fetches and caches its JSON Web
Key Set (JWKS) - the public keys used to verify JWT signatures - and how to
supply a custom or static key source instead of a remote one.

When asked to *"tune JWKS caching"*, *"reduce load on the identity provider"*,
or *"use a static/custom key source for tests"*, follow this guide.

---

## Default behaviour

By default, `.issuer(issuer)` derives a remote JWKS URI and `JwtVerifier`
fetches and caches keys from it:

```java
JwtVerifier jwtVerifier = JwtVerifier.builder()
    .issuer(issuer)
    .build();
```

- Keys are fetched once eagerly on `build()`.
- On a request presenting an **unrecognized `kid`** (e.g. after the IdP
  rotates its signing keys), the verifier triggers a fresh JWKS fetch.
- That fetch is **throttled** - at most once per `jwksMinRefreshInterval`
  (default 60 seconds) - so a bogus/unknown `kid` can't force the API to
  hammer the identity provider's JWKS endpoint on every request.
- Each fetch **fully replaces** the cached key set (not merged) - keys
  rotated out upstream are evicted, not trusted forever.
- Concurrent misses within the throttle window are coalesced into a single
  fetch (via `ReentrantLock`), not one fetch per waiting thread.

---

## Tuning the refresh throttle

```java
JwtVerifier jwtVerifier = JwtVerifier.builder()
    .issuer(issuer)
    .jwksMinRefreshInterval(Duration.ofSeconds(60))   // default shown
    .build();
```

Increase this if your identity provider's JWKS endpoint is rate-limited or
slow; decrease it if you need faster pickup of newly rotated keys (at the
cost of more load on the IdP when an unknown `kid` is presented repeatedly).

---

## Tuning clock skew

Standard time-based claims (`exp`, `iat`, `nbf`) allow a configurable clock
skew (default 60 seconds) to tolerate clock drift between your server and the
identity provider:

```java
JwtVerifier jwtVerifier = JwtVerifier.builder()
    .issuer(issuer)
    .clockSkew(Duration.ofSeconds(60))   // default shown
    .build();
```

---

## Using a custom `Clock` (for tests)

```java
JwtVerifier jwtVerifier = JwtVerifier.builder()
    .issuer(issuer)
    .clock(Clock.fixed(Instant.parse("2024-06-01T00:00:00Z"), ZoneOffset.UTC))
    .build();
```

---

## Using a static/custom `JwtKeySource` (no remote fetch)

For tests, or for an identity provider whose keys you manage yourself
out-of-band, supply a `JwtKeySource` directly instead of a `jwksUri`:

```java
KeySet keySet = ...; // your own KeySet, e.g. from a signed test fixture

JwtVerifier jwtVerifier = JwtVerifier.builder()
    .keySource(JwtKeySource.build(keySet))
    .build();
```

This skips all remote-fetch/throttle behaviour entirely - `JwtKeySource` is a
simple `key(String kid)` lookup interface, so you can also implement your own
(e.g. backed by a local file, a secrets manager, or an in-memory test
keypair).

---

## Notes

- `jwksUri` is auto-derived from `issuer` (`{issuer}/.well-known/jwks.json`
  style) - only set `.jwksUri(...)` explicitly if the JWKS lives somewhere
  non-standard.
- `.httpClient(HttpClient)` lets you supply a pre-configured `HttpClient`
  (e.g. with custom timeouts/proxy settings) instead of the default one.
- None of this tuning affects signature/claim verification correctness -
  it only affects how aggressively the verifier talks to the JWKS endpoint
  and how much clock drift it tolerates.

---

## References

- [docs/LIBRARY.md](../LIBRARY.md)
- `avaje-oauth2-core/README.md`
