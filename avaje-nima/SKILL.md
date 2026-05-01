---
name: avaje-nima
description: Avaje Nima web framework guidance — Helidon SE + avaje-inject + avaje-jsonb. Controllers, DI, configuration, JSON, testing, Docker, and native image. Use when building or modifying avaje-nima web services.
---

# Avaje Nima

Avaje Nima is a Java web framework built on Helidon SE with compile-time DI (avaje-inject),
compile-time JSON (avaje-jsonb), and annotation-driven controllers (avaje-http).

## Key Principles

- Compile-time code generation — no runtime reflection, no proxies
- Virtual threads (Java 21+) — high concurrency with simple blocking code
- `@Controller` + `@Get`/`@Post`/`@Put`/`@Delete` for REST endpoints
- `@Singleton` / `@Factory` / `@Bean` for dependency injection
- `@InjectTest` for integration testing
- GraalVM native image ready out of the box
- Default port 8080

## Task Guides

Load the relevant reference guide for the current task. **Only load what you need.**

| Task | Reference |
|------|-----------|
| Project setup, archetype, multi-module | [setup](references/setup.md) |
| Controllers, filters, exception handling | [controllers](references/controllers.md) |
| Dependency injection, factories, qualifiers | [dependency-injection](references/dependency-injection.md) |
| Configuration, profiles, env vars | [configuration](references/configuration.md) |
| JSON serialisation, custom adapters | [json](references/json.md) |
| Testing — controllers, DI, config | [testing](references/testing.md) |
| Docker, native image, deployment | [deployment](references/deployment.md) |

## Quick Reference

### Controller

```java
@Controller
@Path("/customers")
class CustomerController {

  private final CustomerService service;

  @Inject
  CustomerController(CustomerService service) {
    this.service = service;
  }

  @Get("/{id}")
  Customer find(long id) {
    return service.findById(id);
  }

  @Post
  void create(@Valid Customer customer) {
    service.save(customer);
  }
}
```

### Dependency Injection

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

### Testing

```java
@InjectTest
class CustomerControllerTest {

  @Inject CustomerApi api; // generated typed client

  @Test
  void find() {
    var customer = api.find(1);
    assertThat(customer).isNotNull();
  }
}
```

### Configuration

```yaml
# application.yaml
server:
  port: 8080
myapp:
  feature.enabled: true
```

```java
@Singleton
class MyService {
  @Inject MyService(Configuration config) {
    boolean enabled = config.getBool("myapp.feature.enabled", false);
  }
}
```

## Regenerating References

```bash
cd /path/to/avaje/skills && ./generate-references.sh
```
