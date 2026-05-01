---
name: avaje-inject
description: Avaje Inject compile-time DI framework with avaje-config. Bean creation, factories, qualifiers, lifecycle, configuration, testing. Use when working with avaje-inject outside of avaje-nima (e.g., with Ebean standalone, CLI tools).
---

# Avaje Inject

Avaje Inject is a compile-time dependency injection framework for Java. No runtime
reflection, no proxies — all DI code is generated at compile time via annotation
processing.

## Key Principles

- Compile-time code generation — fast startup, GraalVM native image ready
- `@Singleton` / `@Component` for beans, `@Factory` + `@Bean` for factory methods
- Constructor injection preferred, field/method injection supported
- `@InjectTest` + `@TestScope` for testing
- Pairs naturally with avaje-config for external configuration

## Task Guides

Load the relevant reference guide for the current task. **Only load what you need.**

| Task | Reference |
|------|-----------|
| Project setup, adding dependencies | [setup](references/setup.md) |
| Beans, factories, qualifiers, lifecycle | [dependency-injection](references/dependency-injection.md) |
| Configuration, profiles, env vars | [configuration](references/configuration.md) |
| Testing with @InjectTest | [testing](references/testing.md) |

## Quick Reference

### Bean Creation

```java
@Singleton
class CustomerService {

  private final Database database;

  @Inject
  CustomerService(Database database) {
    this.database = database;
  }
}
```

### Factory Methods

```java
@Factory
class AppConfig {

  @Bean
  Database database(Configuration config) {
    return Database.builder()
        .name("db")
        .dataSourceBuilder(...)
        .build();
  }
}
```

### Testing

```java
@InjectTest
class CustomerServiceTest {

  @Inject CustomerService service;

  @Test
  void find() {
    assertThat(service).isNotNull();
  }
}
```

### Test Scope

```java
@TestScope
@Factory
class TestConfig {

  @Bean
  Database database() {
    // test-only Database bean
  }
}
```

### Configuration

```yaml
# application.yaml
myapp:
  feature.enabled: true
```

```java
boolean enabled = Config.getBool("myapp.feature.enabled", false);
```

## Regenerating References

```bash
cd /path/to/avaje/skills && ./generate-references.sh
```
