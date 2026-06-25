# Avaje Bundle — Configuration (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `openapi-generators/configuration.md`

# Configuration Reference

All `avaje-openapi-maven-plugin` configuration options, with defaults.

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

## Options

| Option | Default | Description |
| --- | --- | --- |
| `inputSpec` | *(required)* | Path to the OpenAPI 3 YAML/JSON document. |
| `apiPackage` | *(required)* | Package for generated API interfaces. |
| `modelPackage` | `${apiPackage}.model` | Package for generated DTO records/enums. |
| `outputDirectory` | `target/generated-sources/avaje-openapi` | Output root (added to compile source roots). |
| `mode` | `CONTRACT` | Generation mode. Only `CONTRACT` is implemented. |
| `generateModels` | `true` | Generate DTO records/enums. `false` = API interfaces only (reuse existing models). See [models](models.md). |
| `generateRecordBuilders` | `false` | Emit `@RecordBuilder` + static `builder()` factories on DTO records. See [models](models.md). |
| `generateJsonAnnotations` | `true` | Emit JSON annotations (`@Json`, `readOnly`/`writeOnly`). |
| `jsonStyle` | `AVAJE` | `AVAJE` (Avaje Jsonb) or `JACKSON`. |
| `generateValidationAnnotations` | `true` | Emit Bean Validation constraints. See [validation](validation.md). |
| `validationStyle` | `JAKARTA` | `JAKARTA` or `AVAJE`. |
| `generateClientAnnotations` | `true` | Emit `@Client` on generated interfaces. |
| `generateOverloads` | `false` | Emit convenience `default` overloads. See [parameters](parameters.md#overloads). |
| `overloadPolicy` | `NULLABLE_ONLY` | `EXPLICIT`, `NULLABLE_ONLY`, or `ALL_OPTIONAL`. |
| `dateTimeType` | `OFFSET_DATE_TIME` | Global type for `format: date-time`: `INSTANT`, `OFFSET_DATE_TIME`, `LOCAL_DATE_TIME`, `ZONED_DATE_TIME`. See [type-mapping](type-mapping.md). |
| `nullableAnnotation` | `org.jspecify.annotations.Nullable` | Annotation for optional members; blank disables `@Nullable`. |
| `typeMappings` | *(none)* | Map of schema `format`/`type` to fully-qualified Java type. See [type-mapping](type-mapping.md). |
| `failOnUnsupported` | `true` | Fail the build when an unsupported OpenAPI feature is encountered. |
| `cleanOutput` | `true` | Delete previously generated output before regenerating. |

## Notes on generated parameter names

Location annotations are always generated with an explicit wire name
(`@QueryParam("status")`), so a generated interface consumed via `@Client.Import`
needs no `-parameters` compiler flag. See [parameters](parameters.md) and
[contract-first](contract-first.md).

## Consuming-project processors

The generated source is consumed by the standard Avaje annotation processors, added
to the consuming module's `annotationProcessorPaths` (and/or dependencies):

- `avaje-http-client-generator` — typed HTTP client from the interface
- `avaje-http-helidon-generator` / `-jex-generator` / `-javalin-generator` — server routes
- `avaje-jsonb-generator` — JSON adapters for DTO records
- `avaje-record-builder` — builders when `generateRecordBuilders=true`
- `avaje-validator-generator` — when `validationStyle=AVAJE`
