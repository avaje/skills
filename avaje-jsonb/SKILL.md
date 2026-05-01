---
name: avaje-jsonb
description: Avaje Jsonb compile-time JSON serialisation library. Reflection-free adapters, custom serializers, polymorphic types, streaming. Use when working with avaje-jsonb for JSON processing.
---

# Avaje Jsonb

Avaje Jsonb is a compile-time JSON serialisation library for Java. It generates
JSON adapters at compile time via annotation processing — no runtime reflection,
fast startup, GraalVM native image ready.

## Key Principles

- `@Json` on types to generate compile-time JSON adapters
- No runtime reflection — all adapters generated at build time
- `@Json.SubTypes` for polymorphic JSON handling
- Custom `JsonAdapter` implementations for special types
- Streaming API for large JSON processing
- One of the fastest Java JSON libraries

## Task Guides

Load the relevant reference guide for the current task. **Only load what you need.**

| Task | Reference |
|------|-----------|
| Basic usage, property mapping | [usage](references/usage.md) |
| Custom adapters, polymorphism, streaming | [advanced](references/advanced.md) |
| Testing | [testing](references/testing.md) |

## Quick Reference

### Annotate a Type

```java
@Json
public record Customer(long id, String name, String email) {}
```

### Serialize / Deserialize

```java
Jsonb jsonb = Jsonb.builder().build();

String json = jsonb.toJson(customer);
Customer customer = jsonb.type(Customer.class).fromJson(json);
```

### Polymorphic Types

```java
@Json
@Json.SubTypes({
  @Json.SubType(type = Dog.class, name = "dog"),
  @Json.SubType(type = Cat.class, name = "cat")
})
public sealed interface Animal permits Dog, Cat {}

@Json
public record Dog(String name, String breed) implements Animal {}

@Json
public record Cat(String name, boolean indoor) implements Animal {}
```

## Regenerating References

```bash
cd /path/to/avaje/skills && ./generate-references.sh
```
