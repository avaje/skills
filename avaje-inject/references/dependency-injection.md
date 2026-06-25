# Avaje Bundle — Dependency Injection (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `inject/creating-beans.md`

# Creating Beans with Avaje Inject

How to create and annotate beans with avaje-inject.

## Basic Bean

Mark a class as a singleton bean:

```java
import jakarta.inject.Singleton;

@Singleton
public class UserService {
  public User findById(long id) {
    return new User(id, "John");
  }
}
```

The `@Singleton` annotation makes it a singleton - one instance for the application.

## Implementing Interfaces

Beans can implement interfaces if desired:

```java
public interface UserService {
  User findById(long id);
}

@Singleton
public class UserServiceImpl implements UserService {
  @Override
  public User findById(long id) {
    return new User(id, "John");
  }
}
```

## Scopes

Control bean lifecycle:

```java
@Singleton          // One instance (default)
public class Single { }

@Prototype          // New instance each time
public class Multi { }
```

## Next Steps

- Learn [dependency injection](dependency-injection.md)
- Use [factory methods](factory-methods.md)

---

## Source: `inject/dependency-injection.md`

# Dependency Injection with Avaje Inject

How to inject dependencies into beans.

## Constructor Injection

Inject through constructor (recommended):

```java
@Singleton
public class OrderService {
  private final UserService userService;
  private final PaymentService paymentService;

  public OrderService(UserService userService, PaymentService paymentService) {
    this.userService = userService;
    this.paymentService = paymentService;
  }
}
```

If a bean class has more than one constructor, annotate the constructor Avaje
Inject should use with `@Inject`. This is common when a class has a package-private
test constructor in addition to the normal DI constructor.

```java
@Singleton
class MetricsReporter {

  @Inject
  MetricsReporter(Configuration config, Optional<GraphiteReporter> reporter) {
    this(config, reporter.map(MetricsReporter::scheduledTask).orElse(null));
  }

  MetricsReporter(Configuration config, ScheduledTask task) {
    // test-friendly constructor
  }
}
```

## Multiple Implementations

Use `@Named` qualifier:

```java
public interface Logger { }

@Singleton
@Named("file")
public class FileLogger implements Logger { }

@Singleton
@Named("console")
public class ConsoleLogger implements Logger { }

@Singleton
public class Service {
  private final Logger fileLogger;

  public Service(@Named("file") Logger logger) {
    this.fileLogger = logger;
  }
}
```

## Next Steps

- See [factory methods](factory-methods.md)
- Learn [lifecycle hooks](lifecycle-hooks.md)

---

## Source: `inject/factory-methods.md`

# Factory Methods

Create beans using factory methods.

## Basic Factory

```java
import io.avaje.inject.Factory;
import io.avaje.inject.Bean;

@Factory
public class DatabaseFactory {
  
  @Bean
  public DataSource createDataSource() {
    return new HikariDataSource(...);
  }
  
  @Bean
  public Database createDatabase(DataSource ds) {
    return new Database(ds);
  }
}
```

The factory methods create and configure beans.

## Optional Beans

Factory methods can return `Optional<T>`. When the optional is present, Avaje
Inject registers the contained `T` bean. When it is empty, no bean is registered.
Consumers can inject `Optional<T>` to model integrations that may be disabled.

```java
@Factory
class MetricsConfig {

  @Bean
  Optional<GraphiteReporter> graphiteReporter(Configuration config) {
    if (!config.enabled("metrics.graphite.enabled", false)) {
      return Optional.empty();
    }
    return Optional.of(GraphiteReporter.builder().build());
  }
}

@Singleton
class MetricsReporter {

  private final Optional<GraphiteReporter> reporter;

  MetricsReporter(Optional<GraphiteReporter> reporter) {
    this.reporter = reporter;
  }
}
```

An `@Bean Optional<T>` method does not register `Optional<T>` as the bean type. It
conditionally registers `T`.

## Bean Creation Order

Bean creation order follows real dependencies. If one bean must be initialized
before another, express that by accepting the dependency as a constructor or
factory-method parameter.

```java
@Factory
class DatabaseConfig {

  @Bean
  Database database(OpenTelemetry openTelemetry, DataSource dataSource) {
    return Database.builder()
      .dataSource(dataSource)
      .build();
  }
}
```

In this example `OpenTelemetry` is created before the `Database`. This is useful
when the database startup reads OpenTelemetry global state. Avoid reverse or
artificial dependencies that create cycles; the dependency direction should match
the required initialization order.

## Next Steps

- Learn [lifecycle hooks](lifecycle-hooks.md)

---

## Source: `inject/qualifiers.md`

# Using Qualifiers

Handle multiple bean implementations.

## Named Qualifier

```java
@Singleton
@Named("primary")
public class PrimaryService implements Service { }

@Singleton
@Named("secondary")
public class SecondaryService implements Service { }

@Singleton
public class Client {
  private final Service primary;

  public Client(@Named("primary") Service service) {
    this.primary = service;
  }
}
```

## Strongly Typed Qualifiers (Recommended)

For better type safety and IDE support, create custom qualifier annotations:

```java
@Qualifier
@Target({FIELD, PARAMETER})
@Retention(RUNTIME)
public @interface Blue { }

@Qualifier
@Target({FIELD, PARAMETER})
@Retention(RUNTIME)
public @interface Green { }
```

Then use them on beans and injections:

```java
@Singleton
@Blue
public class PrimaryService implements Service { }

@Singleton
@Green
public class SecondaryService implements Service { }

@Singleton
public class Client {
  private final Service primary;

  public Client(@Blue Service service) {
    this.primary = service;
  }
}
```

**Why prefer strongly typed qualifiers?** They provide compile-time type checking and IDE autocomplete support, avoiding the "Stringly typed" errors that can occur with `@Named`.

## Next Steps

- See [testing](testing.md)

---

## Source: `inject/lifecycle-hooks.md`

# Lifecycle Hooks

Initialize and cleanup beans.

## Post-Construct

Run code after bean is created:

```java
@Singleton
public class Service {

  @PostConstruct
  public void init() {
    System.out.println("Service initialized");
  }
}
```

## Pre-Destroy

Run code before bean is destroyed:

```java
@Singleton
public class Service {

  @PreDestroy
  public void shutdown() {
    System.out.println("Service shutting down");
  }
}
```

## Next Steps

- Learn [qualifiers](qualifiers.md)

---

## Source: `inject/native-image.md`

# Native Images with Avaje Inject

Building GraalVM native images with avaje-inject.

## Setup

Add native image plugin to `pom.xml`:

```xml
<plugin>
  <groupId>org.graalvm.buildtools</groupId>
  <artifactId>native-maven-plugin</artifactId>
  <version>1.0.0</version>
</plugin>
```

## Build

```bash
mvn -Pnative clean package
```

Avaje Inject provides automatic GraalVM metadata.

## Performance

Native images with inject offer:

- **Startup**: < 50ms
- **Memory**: 30-50MB
- **No warm-up**: Full speed immediately
