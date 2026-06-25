# Avaje Bundle — Getting Started (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `openapi-generators/getting-started.md`

# Getting Started

Generate Avaje HTTP API interfaces and DTO records from an OpenAPI document using
the `avaje-openapi-maven-plugin`.

## What it does

The plugin reads an OpenAPI 3 YAML/JSON file and generates Java source using Avaje
annotations:

- API interfaces using `io.avaje.http.api` annotations (`@Path`, `@Get`, `@Post`,
  `@QueryParam`, `@Header`, ...)
- DTO records and enums
- optional Avaje Jsonb annotations
- optional Jakarta or Avaje validation annotations
- optional Avaje Record Builder support for DTO records

The generated interfaces are then consumed by the existing Avaje annotation
processors:

- `avaje-http-client-generator` generates typed HTTP clients
- server generators (Nima/Helidon, Jex, Javalin) consume the same `avaje-http-api`
  contract
- `avaje-jsonb-generator` generates JSON adapters for generated DTO records
- `avaje-record-builder` generates builders for generated DTO records when enabled

This is the "contract-first" workflow: the OpenAPI document is the single source of
truth, and the same generated interface drives both the HTTP client and the server
controller. See [contract-first](contract-first.md).

## Plugin setup

```xml
<plugin>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-openapi-maven-plugin</artifactId>
  <version>${avaje.openapi.version}</version>
  <executions>
    <execution>
      <goals>
        <goal>generate</goal>
      </goals>
      <configuration>
        <inputSpec>${project.basedir}/src/main/openapi/openapi.yaml</inputSpec>
        <apiPackage>org.example.api</apiPackage>
        <modelPackage>org.example.api.model</modelPackage>
      </configuration>
    </execution>
  </executions>
</plugin>
```

Generated contract source defaults to:

```text
target/generated-sources/avaje-openapi
```

The plugin adds that directory to the Maven compile source roots automatically.

## Interface path (`@Path`)

The class-level `@Path` on each generated interface is derived from two sources,
concatenated:

1. the **path component of the first `servers` URL**, then
2. the longest **literal path prefix** shared by every operation in that interface
   (the leading path segments common to all operations, stopping at the first path
   variable).

```yaml
servers:
  - url: https://api.example.com/v1   # absolute URL, or a relative "/v1"
paths:
  /pets/{id}: { get: { tags: [store], ... } }
  /owners/{id}: { get: { tags: [store], ... } }
```

generates:

```java
@Path("/v1")
public interface StoreApi {
  @Get("/pets/{id}")
  Pet getPet(Long id);

  @Get("/owners/{id}")
  Owner getOwner(Long id);
}
```

The `servers` URL may be absolute (`https://host/v1`) or root-relative (`/v1`); only
its path component is used, a trailing `/` is trimmed, and a bare `/` contributes
nothing. Server URLs containing template variables (`https://{host}/v1`) cannot form
a static prefix and are ignored with a warning. Equivalently you can omit `servers`
and put the version directly in the paths (`/v1/pets/{id}`); the shared `/v1` segment
is then picked up by the common-prefix step.

Operations are grouped into interfaces by their first `tag`.

## Java versions

The generator itself runs on Java 11+ (`avaje-openapi-generator-core`,
`avaje-openapi-maven-plugin`). Generated DTO models use Java records, so a project
that compiles the generated model source needs Java 17+ as a practical baseline.

A common arrangement is to publish the generated API + model module at Java 17 so
that Java 17 consumers can use the generated HTTP client, while the server module
that implements the contract runs on Java 21.

## Current scope

Supported: OpenAPI 3 YAML/JSON; REST paths and common HTTP methods; JSON
request/response bodies; path/query/header/cookie parameters; component object
schemas, enums, arrays, maps, date/time/UUID formats; validation constraints;
`readOnly`/`writeOnly` fields; response headers as `@apiNote`; `allOf` composition;
inline schemas extracted into named nested records; `description`/`summary` as
Javadoc and `deprecated` as `@Deprecated`; `@Nullable` on optional members; global
`dateTimeType`, extended formats, `x-java-type`, and `typeMappings`; convenience
`default` method overloads.

Unsupported features currently produce diagnostics: `oneOf`/`anyOf`/discriminator
polymorphism; multipart upload; callbacks, links, webhooks; multiple request body
content types per operation.
