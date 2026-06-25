# Avaje Bundle — Contract First (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `openapi-generators/contract-first.md`

# Contract-First Client and Server

The generated `avaje-http-api` interface is a single contract that drives **both**
the HTTP client and the server controller. The OpenAPI document is the source of
truth; the interface and DTOs are generated; the client is generated; the server
controller implements the interface.

## The shared interface

The plugin generates an interface annotated with `io.avaje.http.api` annotations:

```java
@Path("/v1")
public interface CentralAccessApi {

  @Get("/devices/{deviceGid}")
  Device findDevice(UUID deviceGid, @QueryParam("useMaster") @Default("false") boolean useMaster);

  @Get("/orgs/{orgGid}/devices/stream")
  Stream<Device> findAllDevices(UUID orgGid, @Nullable @QueryParam("modifiedSince") Instant modifiedSince);
}
```

## Generating an HTTP client

Import the generated interface into a module that has the avaje-http client
generator. The client generator produces a typed `HttpClient`-backed implementation:

```java
@Client.Import(CentralAccessApi.class)
package org.example.client;
```

Add the client generator to the annotation processor path of the consuming module:

```xml
<path>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-http-client-generator</artifactId>
  <version>${avaje.http.version}</version>
</path>
```

### Parameter names and `@Client.Import` (important)

`@Client.Import` reads the **precompiled** interface from a jar on the classpath. It
needs the wire names of query/header/cookie parameters. The generator always emits
those names explicitly (`@QueryParam("modifiedSince")`), so the imported client
resolves them with no extra configuration.

If you ever hand-write an imported interface (or use an older generator that omitted
the name and relied on the avaje-http parameter-name fallback), the consuming jar
must be compiled with `-parameters` so the names survive in bytecode. With the
explicit-name generation this is **not** required.

## Implementing the server

The same interface is implemented by a `@Controller`. The avaje-http server
generator (Nima/Helidon, Jex, or Javalin) reads the controller, matches each
`@Override` back to the interface method to recover its `@Get`/`@Post` mapping, and
registers the route:

```java
@Controller
public class CentralAccessController implements CentralAccessApi {

  @Override
  public Device findDevice(UUID deviceGid, boolean useMaster) {
    ...
  }

  @Override
  public Stream<Device> findAllDevices(UUID orgGid, Instant modifiedSince) {
    ...
  }
}
```

| Server target | Consuming processor            |
|---|--------------------------------|
| Avaje Nima / Helidon | `avaje-http-helidon-generator` |
| Avaje Jex | `avaje-http-jex-generator`     |
| Javalin | `avaje-http-javalin-generator` |

Switching server targets is purely a dependency / annotation-processor choice; the
generated interface and DTOs are unchanged.

### `@Nullable` on parameters needs avaje-http 3.10+

Optional parameters are generated with a JSpecify `@Nullable`
(`@Nullable @QueryParam("modifiedSince") Instant modifiedSince`). JSpecify
`@Nullable` is a `TYPE_USE` annotation with `RUNTIME` retention, so it becomes part
of the interface method's parameter-type signature, while the controller `@Override`
(which usually omits it) does not carry it.

avaje-http server generators **before 3.10** matched the controller override to the
interface method using a raw signature-string comparison, so the mismatch caused the
`@Get`/`@Post` mapping to be silently dropped and the route to 404. avaje-http 3.10+
matches per-parameter by type (ignoring `TYPE_USE` annotations), which fixes this.

If `/stream`-style optional-parameter routes 404 under a server target, confirm the
server generator is 3.10 or newer. (The `avaje-nima` parent may pin an older
`avaje.http.version`; add an explicit `avaje-http-helidon-generator` processor path
at the desired version to override it.)

## API-only generation (reuse hand-written models)

When adopting contract-first on an existing API whose DTO records are already
hand-maintained, set `generateModels=false`. The plugin then generates **only** the
API interfaces, which reference the existing `modelPackage` types on the classpath.
See [models](models.md).
