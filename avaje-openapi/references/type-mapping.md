# Avaje Bundle — Type Mapping (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `openapi-generators/type-mapping.md`

# Type Mapping

How OpenAPI schema types and formats map to Java types, and how to override the
mapping globally or per property.

## Primitive mapping

A scalar model field that is `required` and **not** `nullable: true` is guaranteed
present and non-null, so the generator emits the Java **primitive** form rather than
the boxed wrapper:

```yaml
Driver:
  required: [id, version, logbookUser]
  properties:
    id:          { type: integer, format: int64 }   # required -> long
    version:     { type: integer }                   # required -> int
    logbookUser: { type: boolean }                   # required -> boolean
    tag:         { type: integer }                   # optional -> Integer
```

```java
public record Driver(
  long id,
  int version,
  boolean logbookUser,
  @Nullable Integer tag
) {}
```

Only the wrapper types `Boolean`, `Integer`, `Long`, `Double` and `Float` are
unboxed. A field that is `required` **and** `nullable: true` stays boxed (it can be
explicitly null). Parameters with a `default` are also unboxed — see
[parameters](parameters.md#parameter-defaults).

This makes generated DTOs match hand-written records that use primitives for
mandatory fields. To get a byte-exact match also consider
`generateValidationAnnotations=false` (see [models](models.md)).

## Date and time types

OpenAPI's `format: date-time` (RFC 3339) carries a timezone offset, so it maps to
`java.time.OffsetDateTime` by default. Set the global `dateTimeType` to change the
type used for **all** `format: date-time` properties:

```xml
<dateTimeType>INSTANT</dateTimeType>
<!-- INSTANT | OFFSET_DATE_TIME (default) | LOCAL_DATE_TIME | ZONED_DATE_TIME -->
```

`format: date` always maps to `java.time.LocalDate`.

### Per-property overrides

Three mechanisms override the global default for an individual property. Precedence,
highest first:

1. **`x-java-type`** vendor extension — keeps the spec standard and accepts any fully
   qualified class name:

   ```yaml
   externalLastModified:
     type: string
     format: date-time
     x-java-type: java.time.OffsetDateTime
   ```

2. **Extended `format` values** — concise shorthand for the common `java.time` types:

   | `format:` value    | Java type                  |
   | ------------------ | -------------------------- |
   | `instant`          | `java.time.Instant`        |
   | `offset-date-time` | `java.time.OffsetDateTime` |
   | `local-date-time`  | `java.time.LocalDateTime`  |
   | `zoned-date-time`  | `java.time.ZonedDateTime`  |

3. **Global `dateTimeType`** — applied to plain `format: date-time`.

## Global type mappings

`typeMappings` overrides the Java type generated for a schema `format` or `type`,
without editing each schema. Keys are a schema `format` (e.g. `uuid`, `date-time`,
`binary`) or a bare `type` (e.g. `string`); values are fully-qualified Java type
names:

```xml
<typeMappings>
  <uuid>com.example.MyUuid</uuid>
  <date-time>java.time.Instant</date-time>
</typeMappings>
```

Precedence, highest first:

1. per-property `x-java-type` vendor extension
2. `typeMappings` entry keyed by `format`
3. `typeMappings` entry keyed by `type`
4. the built-in default type

So given the mappings above, `{ type: string, format: uuid }` becomes
`com.example.MyUuid`, and a plain `{ type: string }` keeps `String` unless a `string`
key is also configured. The import is derived from the fully-qualified value
(`java.lang` and unqualified names are emitted without an import).

## Choosing an override mechanism

- **One property, non-standard type** → `x-java-type` on that property.
- **One property, a `java.time` type** → an extended `format` value (terser).
- **Every property of a given `format`/`type`** → `typeMappings` (one global entry).
- **Every `date-time` to a single type** → `dateTimeType`.
