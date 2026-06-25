# Avaje Bundle — Parameters (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `openapi-generators/parameters.md`

# Parameters

Path, query, header, and cookie parameters map to method parameters on the generated
interface with the matching `io.avaje.http.api` location annotation. Path parameters
carry no annotation; query/header/cookie carry `@QueryParam` / `@Header` / `@Cookie`.

## Explicit parameter names

Location annotations are always generated with an explicit wire-name value:

```java
List<Pet> listPets(@QueryParam("status") PetStatus status);

Pet getPet(Long id, @Header("X-Request-Id") String xRequestId);
```

The explicit name keeps the generated interface robust as a contract-first artifact.
avaje-http can fall back to the Java parameter name when the annotation value is
blank, but that fallback only works when parameter names are present in the bytecode
— which is **not** the case for an interface consumed from a precompiled jar via
`@Client.Import` unless that jar was compiled with `-parameters`. Emitting the name
explicitly removes that requirement, so consumers need no special compiler
configuration. See [contract-first](contract-first.md).

## Parameter defaults

When a parameter schema declares a `default`, the generator emits an `@Default`
annotation alongside the location annotation and uses the **primitive** form of the
type (a default guarantees a value):

```yaml
parameters:
  - name: useMaster
    in: query
    schema:
      type: boolean
      default: false
```

```java
Pet getPet(Long id, @QueryParam("useMaster") @Default("false") boolean useMaster);
```

Wrapper types `Boolean`, `Integer`, `Long`, `Double` and `Float` are unboxed to
their primitive form when a default is present. Other types keep their declared type
and simply gain the `@Default("...")` annotation.

## Nullable parameters

Optional parameters (`required: false`, without a `default`) are annotated
`@Nullable`. The default annotation is JSpecify:

```java
import org.jspecify.annotations.Nullable;

List<Pet> listPets(@Nullable @QueryParam("status") PetStatus status);
```

JSpecify is already a transitive dependency of `avaje-http-client`. If you only
depend on `avaje-http-api`, add `org.jspecify:jspecify` to the consuming project.
Point `nullableAnnotation` at a different annotation (e.g.
`jakarta.annotation.Nullable`), or set it blank to disable `@Nullable` generation.

> JSpecify `@Nullable` is a `TYPE_USE` annotation. For server controllers this
> interacts with how avaje-http matches an `@Override` back to the interface method —
> requires avaje-http 3.10+. See [contract-first](contract-first.md).

## Overloads

Set `generateOverloads=true` to emit convenience `default` method overloads that omit
a trailing run of **omittable** parameters and delegate to the full method. The
overloads carry no HTTP annotation, so the server and client generators ignore them —
they exist purely for caller ergonomics and are inherited by both the controller and
the generated client.

```xml
<generateOverloads>true</generateOverloads>
<overloadPolicy>NULLABLE_ONLY</overloadPolicy>
<!-- EXPLICIT | NULLABLE_ONLY (default) | ALL_OPTIONAL -->
```

Only a contiguous run of omittable parameters at the **end** of the signature can be
dropped. Path parameters and request bodies are never omittable. The `overloadPolicy`
decides which parameters are omittable by default:

| Policy          | Omittable parameters                                  | Value passed when omitted |
| --------------- | ----------------------------------------------------- | ------------------------- |
| `EXPLICIT`      | only those marked `x-overload: true`                  | default, or `null`        |
| `NULLABLE_ONLY` | optional parameters **without** a `default` (default) | `null`                    |
| `ALL_OPTIONAL`  | every optional parameter (including defaulted ones)   | its `default` literal     |

A per-parameter `x-overload` vendor extension overrides the policy for that parameter
(`true` forces omittable, `false` forces required).

```java
FleetDetail findFleet(UUID fleetGid, @QueryParam("useMaster") @Default("false") boolean useMaster,
    @QueryParam("withMachines") @Default("false") boolean withMachines,
    @QueryParam("withDrivers") @Default("false") boolean withDrivers);

default FleetDetail findFleet(UUID fleetGid, boolean useMaster, boolean withMachines) {
  return findFleet(fleetGid, useMaster, withMachines, false);
}

default FleetDetail findFleet(UUID fleetGid, boolean useMaster) {
  return findFleet(fleetGid, useMaster, false, false);
}
```

## Response header documentation

avaje-http has no response-header annotation, so OpenAPI response headers are
surfaced as an `@apiNote` Javadoc tag on the generated method (2xx response only):

```java
/**
 * @apiNote Response headers: X-Rate-Limit (integer — Request limit per hour), X-Rate-Limit-Reset (string)
 */
@Get
List<Item> listItems();
```
