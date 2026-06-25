# Avaje Bundle — Validation (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `openapi-generators/validation.md`

# Validation

Validation annotations are emitted on generated record components and method
parameters by default. Disable them with `generateValidationAnnotations=false`.

## Validation style

The default style is Jakarta Bean Validation:

```xml
<validationStyle>JAKARTA</validationStyle>
```

```java
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
```

To use Avaje Validator constraint annotations instead:

```xml
<validationStyle>AVAJE</validationStyle>
```

```java
import io.avaje.validation.constraints.NotNull;
import io.avaje.validation.constraints.Size;
```

Add the Avaje Validator constraints dependency to the consuming project:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-validator-constraints</artifactId>
  <version>${avaje.validator.version}</version>
</dependency>
```

## Supported constraints

Schema keywords map to constraint annotations on the generated record components:

| Schema keyword | Annotation |
| --- | --- |
| `required` | `@NotNull` |
| `minLength` / `maxLength` | `@Size(min, max)` |
| `minItems` / `maxItems` (arrays) | `@Size(min, max)` |
| `minimum` / `maximum` (whole, inclusive) | `@Min` / `@Max` |
| `minimum` / `maximum` (decimal) | `@DecimalMin` / `@DecimalMax` |
| `exclusiveMinimum` / `exclusiveMaximum` | `@DecimalMin` / `@DecimalMax` with `inclusive = false` |
| `pattern` | `@Pattern(regexp = ...)` |
| `format: email` | `@Email` |
| object / array-of / map-of a generated model | `@Valid` |

Both OpenAPI 3.0 (`exclusiveMinimum: true`) and 3.1 (`exclusiveMinimum: <number>`)
exclusive-bound forms are honoured. `multipleOf` has no Bean Validation equivalent
and is not mapped.

`@NotNull` is **not** emitted for a component that is generated as a primitive (a
`required`, non-nullable scalar — see [type-mapping](type-mapping.md#primitive-mapping)),
since a primitive is intrinsically non-null. A field that is both `required` and
`nullable: true` is annotated `@Nullable` (not `@NotNull`).

## Nested validation

Record components whose type is a generated model — directly, or as the element of a
`List`/`Map` — are annotated `@Valid` so Bean Validation cascades into them:

```java
public record Order(
  @NotNull @Valid Customer customer,
  @Valid List<Item> items,
  @Valid Map<String, Item> attachments,
  List<String> labels,
  OrderStatus status
) {}
```

References to enums and scalar types are not cascaded. Jakarta places `@Valid` in the
root `jakarta.validation` package; the Avaje style uses
`io.avaje.validation.constraints.Valid`.

## Disabling validation

```xml
<generateValidationAnnotations>false</generateValidationAnnotations>
```

Use this when the generated DTOs must match hand-written records that do not carry
validation annotations, or when validation is enforced elsewhere. See
[models](models.md).
