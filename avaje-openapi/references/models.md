# Avaje Bundle — Models (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `openapi-generators/models.md`

# DTO Models

By default the plugin generates Java record DTOs (plus enums) for every component
schema, alongside the API interfaces.

## Record DTOs

```java
@Json
public record Pet(
  @NotNull @Min(1) Long id,
  @NotNull @Size(min = 1, max = 100) String name,
  Instant createdAt
) {}
```

`@Json` (Avaje Jsonb) is emitted when `generateJsonAnnotations` is `true` (the
default). Validation annotations are emitted when `generateValidationAnnotations` is
`true` (the default); see [validation](validation.md).

## Record builders

Enable builder generation:

```xml
<generateRecordBuilders>true</generateRecordBuilders>
```

Each generated record then gains static `builder()` factory methods backed by Avaje
Record Builder:

```java
@RecordBuilder
@Json
public record Pet(@NotNull Long id, @NotNull String name, Instant createdAt) {

  public static PetBuilder builder() {
    return PetBuilder.builder();
  }

  public static PetBuilder builder(Pet from) {
    return PetBuilder.builder(from);
  }
}
```

Add Avaje Record Builder to the consuming project as a `provided` dependency and to
the annotation processor paths:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-record-builder</artifactId>
  <version>${avaje.record.builder.version}</version>
  <scope>provided</scope>
</dependency>
```

```xml
<path>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-record-builder</artifactId>
  <version>${avaje.record.builder.version}</version>
</path>
```

## readOnly and writeOnly fields

Schema properties marked `readOnly: true` or `writeOnly: true` get a JSON annotation
so the serialisation library enforces the constraint (only when
`generateJsonAnnotations` is `true`):

| OpenAPI | Avaje Jsonb (`jsonStyle: AVAJE`, default) | Jackson (`jsonStyle: JACKSON`) |
| --- | --- | --- |
| `readOnly: true` | `@Json.Ignore(deserialize = true)` | `@JsonProperty(access = READ_ONLY)` |
| `writeOnly: true` | `@Json.Ignore(serialize = true)` | `@JsonProperty(access = WRITE_ONLY)` |

```java
@Json
public record UserProfile(
  @Json.Ignore(deserialize = true) Long id,        // readOnly — responses only
  @NotNull String username,
  @Json.Ignore(serialize = true) String password,  // writeOnly — requests only
  @Nullable String email
) {}
```

Set `jsonStyle` to `JACKSON` to target Jackson `@JsonProperty` instead.

## Composition and inline schemas

- `allOf` members are flattened/merged into a single record.
- Inline object/array/map schemas are extracted into named nested records.

`oneOf`/`anyOf`/discriminator polymorphism is not yet supported and produces a
diagnostic.

## API-only generation (reuse existing models)

Set `generateModels=false` to generate **only** the API interfaces. The generated
interfaces still reference `modelPackage` types, which must be provided by an
existing (hand-written) module on the classpath:

```xml
<configuration>
  <inputSpec>${project.basedir}/src/main/openapi/openapi.yaml</inputSpec>
  <apiPackage>org.example.api</apiPackage>
  <modelPackage>org.example.model</modelPackage>
  <generateModels>false</generateModels>
</configuration>
```

This suits adopting contract-first on an existing API where the model records are
already hand-maintained (with their own Javadoc, field types and conventions) and
remain the single source of truth — the OpenAPI spec then defines only the
operations, and the DTO schemas exist purely so the generated interface signatures
resolve to those existing types.

### Matching hand-written records exactly

When the generated models must be byte-for-byte identical to existing hand-written
records, the relevant knobs are:

- `generateValidationAnnotations=false` — drop `@NotNull`/`@Valid` if the hand-written
  records do not use them.
- `dateTimeType` / per-property `x-java-type` / `format` overrides — match the exact
  `java.time` types. See [type-mapping](type-mapping.md).
- `required: true` on scalar properties yields Java **primitives** (`long`, `int`,
  `boolean`), matching hand-written records that use primitives for mandatory fields.
  See [type-mapping](type-mapping.md#primitive-mapping).
