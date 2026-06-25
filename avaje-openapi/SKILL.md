---
name: avaje-openapi
description: Avaje OpenAPI generators — contract-first code generation from an OpenAPI 3 document into Avaje HTTP API interfaces and DTO records. Maven plugin setup, models, parameters, type mapping, validation, and contract-first client+server usage. Use when generating or configuring avaje-openapi (avaje-openapi-maven-plugin) code generation.
---

# Avaje OpenAPI Generators

The `avaje-openapi-maven-plugin` reads an OpenAPI 3 YAML/JSON document and generates
Java source using Avaje annotations: an `avaje-http-api` interface (`@Path`, `@Get`,
`@QueryParam`, ...) plus DTO records and enums. The generated interface is a single
**contract-first** artifact that drives both the typed HTTP client and the server
controller.

## Key Principles

- Contract-first: the OpenAPI document is the single source of truth.
- One generated interface, two consumers — `@Client.Import` client AND a `@Controller`
  that `implements` it; both go through the standard Avaje annotation processors.
- DTOs are Java records (Java 17+ to compile generated models; generator runs on 11+).
- Generated output goes to `target/generated-sources/avaje-openapi` (auto-added to
  compile source roots).
- Location annotations always carry an explicit wire name (`@QueryParam("status")`)
  so an imported client needs no `-parameters` compiler flag.
- `required` + non-nullable scalars generate Java **primitives** (`long`/`int`/`boolean`).

## Task Guides

Load the relevant reference guide for the current task. **Only load what you need.**

| Task | Reference |
|------|-----------|
| Plugin setup, output, `@Path`, scope | [getting-started](references/getting-started.md) |
| Client `@Client.Import` + server controller, gotchas | [contract-first](references/contract-first.md) |
| DTO records, builders, JSON, API-only generation | [models](references/models.md) |
| Query/header/cookie params, defaults, nullable, overloads | [parameters](references/parameters.md) |
| Date-time, primitives, `x-java-type`, `typeMappings` | [type-mapping](references/type-mapping.md) |
| Validation constraints, styles, `@Valid` cascade | [validation](references/validation.md) |
| Full plugin option reference | [configuration](references/configuration.md) |

## Quick Reference

### Plugin

```xml
<plugin>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-openapi-maven-plugin</artifactId>
  <version>${avaje.openapi.version}</version>
  <executions>
    <execution>
      <goals><goal>generate</goal></goals>
      <configuration>
        <inputSpec>${project.basedir}/src/main/openapi/openapi.yaml</inputSpec>
        <apiPackage>org.example.api</apiPackage>
        <modelPackage>org.example.api.model</modelPackage>
      </configuration>
    </execution>
  </executions>
</plugin>
```

### Generated interface (drives client and server)

```java
@Path("/v1")
public interface CentralAccessApi {

  @Get("/devices/{deviceGid}")
  Device findDevice(UUID deviceGid, @QueryParam("useMaster") @Default("false") boolean useMaster);

  @Get("/orgs/{orgGid}/devices/stream")
  Stream<Device> findAllDevices(UUID orgGid, @Nullable @QueryParam("modifiedSince") Instant modifiedSince);
}
```

### Client and server

```java
// client module
@Client.Import(CentralAccessApi.class)
package org.example.client;

// server module
@Controller
public class CentralAccessController implements CentralAccessApi { /* @Override ... */ }
```

## Gotchas

- **Imported client param names** — the generator emits explicit `@QueryParam("name")`,
  so `@Client.Import` works without `-parameters`. Hand-written imported interfaces
  that omit the name still require the producing jar be compiled with `-parameters`.
- **`@Nullable` server routes need avaje-http 3.10+** — JSpecify `@Nullable` is a
  `TYPE_USE` annotation; older avaje-http server generators mismatched the controller
  `@Override` against the interface method and silently dropped the route (404). Use
  avaje-http 3.10+, and add an explicit `avaje-http-helidon-generator` processor path
  if a parent pom (e.g. `avaje-nima`) pins an older version.
- **Exact model match** — to match hand-written records byte-for-byte, combine
  `generateValidationAnnotations=false`, the right `dateTimeType`/`x-java-type`, and
  rely on the `required`-scalar → primitive rule.

## Maintaining this skill

Source guides live in `avaje-openapi-generators/docs/guides/`. After editing them,
regenerate the `references/` bundles:

```bash
AVAJE_DIR=~/github/avaje ~/github/avaje/skills/generate-references.sh
```

Edit `references/*.md` only via the source guides — they are overwritten on
regeneration.
