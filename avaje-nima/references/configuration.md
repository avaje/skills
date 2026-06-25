# Avaje Bundle — Configuration (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `config/getting-started.md`

# Getting Started with Avaje Config

A quick introduction to loading configuration with avaje-config.

## Installation

Add the dependency to your `pom.xml`:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-config</artifactId>
  <version>5.1</version>
</dependency>
```

## Loading Configuration

Create a `application.yaml` file in `src/main/resources`:

```yaml
server:
  port: 8080
  ssl:
    enabled: false

database:
  host: localhost
  port: 5432
  name: myapp
```

Access configuration in your code:

```java
import io.avaje.config.Config;

public class MyApplication {
  public static void main(String[] args) {
    int serverPort = Config.getInt("server.port");
    String dbHost = Config.get("database.host");
    boolean sslEnabled = Config.getBool("server.ssl.enabled", false);
  }
}
```

## Configuration Sources

Avaje Config supports multiple configuration sources. During initial loading the
highest priority values are:

1. System properties: `-Dserver.port=9000`
2. Environment variables: `SERVER_PORT=9000`
3. Explicit builder values such as `Configuration.builder().put(...)`
4. Application properties files and resources, with later sources overriding earlier sources
5. Default values in code

Runtime calls to `Config.setProperty(...)`, `Configuration.setProperty(...)`, or
dynamic configuration sources update the in-memory configuration immediately for
subsequent reads.

## Type-Safe Configuration

For larger applications, use type-safe configuration classes:

```java
@Config
public class AppConfig {
  public final String dbHost;
  public final int dbPort;
  
  public AppConfig(String dbHost, int dbPort) {
    this.dbHost = dbHost;
    this.dbPort = dbPort;
  }
}
```

Use in your code:

```java
public class MyService {
  private final AppConfig config;
  
  public MyService(AppConfig config) {
    this.config = config;
  }
}
```

## Next Steps

- Learn about [default values](default-values.md)
- Load [profile-specific configuration](profiles.md)
- Use [environment variables](environment-variables.md)

---

## Source: `config/default-values.md`

# Using Default Values

How to provide sensible defaults for configuration properties.

## Simple Defaults

Provide a default when reading a property:

```java
import io.avaje.config.Config;

// Returns 8080 if not configured
int port = Config.getInt("server.port", 8080);

// Returns "localhost" if not configured
String host = Config.get("server.host", "localhost");

// Returns false if not configured
boolean ssl = Config.getBool("server.ssl.enabled", false);
```

## Defaults in Configuration Classes

Use constructor parameters with defaults:

```java
@Config
public class AppConfig {
  public final int serverPort;
  public final String serverHost;
  public final boolean sslEnabled;

  public AppConfig(
    @ConfigProperty(value = "server.port", defValue = "8080") int serverPort,
    @ConfigProperty(value = "server.host", defValue = "localhost") String serverHost,
    @ConfigProperty(value = "server.ssl.enabled", defValue = "false") boolean sslEnabled
  ) {
    this.serverPort = serverPort;
    this.serverHost = serverHost;
    this.sslEnabled = sslEnabled;
  }
}
```

## Defaults in Configuration Files

Specify defaults in `application.yaml`:

```yaml
server:
  port: 8080
  host: localhost
  ssl:
    enabled: false
    keystore: classpath:keystore.jks

database:
  connections: 10
  timeout: 30
```

## When to Use Each Approach

| Approach | Use When |
|----------|----------|
| Direct call defaults | Simple, single properties |
| Configuration class defaults | Multiple related properties, type safety |
| YAML file defaults | Defaults shared across environments |

## Overriding Defaults

Defaults can be overridden during initial loading by:

1. **System properties**: `java -Dserver.port=9000`
2. **Environment variables**: `export SERVER_PORT=9000`
3. **Explicit builder values**: `Configuration.builder().put("server.port", "9000")`
4. **Configuration files**: `application.yaml`

After startup, `Config.setProperty(...)`, `Configuration.setProperty(...)`, and
dynamic configuration sources update the in-memory value used by subsequent reads.

See [Profiles](profiles.md) for loading environment-specific defaults.

## Next Steps

- Learn about [environment-specific profiles](profiles.md)
- Use [environment variables](environment-variables.md)

---

## Source: `config/profiles.md`

# Loading Profile-Specific Configuration

How to load different configuration for development, test, and production environments.

## Profile Files

Create environment-specific configuration files:

```
src/main/resources/
├── application.yaml          # Shared defaults
├── application-dev.yaml      # Development
├── application-test.yaml     # Test
└── application-prod.yaml     # Production
```

## Activating Profiles

Activate a profile by setting the `config.profiles` property (note: plural):

```bash
# Development
java -Dconfig.profiles=dev myapp.jar

# Test
java -Dconfig.profiles=test myapp.jar

# Production
java -Dconfig.profiles=prod myapp.jar

# Multiple profiles (comma-separated)
java -Dconfig.profiles=prod,docker myapp.jar
```

Or with environment variables:

```bash
export CONFIG_PROFILES=prod
java myapp.jar
```

## Example Profile Configurations

**application.yaml** (shared defaults):
```yaml
app:
  name: MyApp
  version: 1.0.0

logging:
  level: INFO
```

**application-dev.yaml** (development):
```yaml
server:
  port: 8080

database:
  host: localhost
  port: 5432

logging:
  level: DEBUG
```

**application-prod.yaml** (production):
```yaml
server:
  port: 443
  ssl:
    enabled: true

database:
  host: db.example.com
  port: 5432

logging:
  level: WARN
```

## Accessing Profile in Code

Get the active profile:

```java
String profile = Config.get("config.profiles", "dev");
if (profile.equals("prod")) {
  // Production-specific behavior
}
```

## Test Configuration Auto-Loading vs Profile Activation

These are two distinct mechanisms — do not confuse them:

**`application-test.yaml` auto-loading (no activation needed):**
`src/test/resources/application-test.yaml` is a special hardcoded filename.
avaje-config loads it automatically whenever it is present on the classpath —
typically during Maven/Gradle test runs. No `config.profiles=test` or
`avaje.profiles=test` is required.

```
src/test/resources/
└── application-test.yaml   ← loaded automatically, no profile activation needed
```

**Explicit profile activation (activation required):**
All other profile files (`application-dev.yaml`, `application-it.yaml`, etc.)
require explicit activation:

```bash
java -Dconfig.profiles=it myapp.jar   # loads application-it.yaml
```

> **Common mistake:** setting `-Davaje.profiles=test` in your test runner to
> load `application-test.yaml`. This is not needed — the file is auto-loaded
> unconditionally when present in test resources.

## Profile-Specific Beans

Use profiles with dependency injection:

```java
@Config
public class DatabaseConfig {
  public final String host;
  
  @Config
  public static class Prod {
    public final String host = "prod-db.example.com";
  }
  
  @Config
  public static class Dev {
    public final String host = "localhost";
  }
}
```

## Next Steps

- Use [environment variables](environment-variables.md) to override values
- Set up [change listeners](change-listeners.md) to react to configuration changes

---

## Source: `config/environment-variables.md`

# Using Environment Variables

How to configure your application using environment variables.

## Basic Usage

Reference environment variables in configuration files:

```yaml
server:
  port: ${SERVER_PORT:8080}

database:
  host: ${DATABASE_HOST:localhost}
  port: ${DATABASE_PORT:5432}
  user: ${DATABASE_USER}
  password: ${DATABASE_PASSWORD}
```

Format: `${ENV_VAR_NAME:default_value}`

If the environment variable is not set, uses the default value (or error if no default).

## Setting Environment Variables

**Linux/Mac**:
```bash
export SERVER_PORT=9000
export DATABASE_HOST=prod-db.example.com
java myapp.jar
```

**Docker**:
```dockerfile
ENV SERVER_PORT=9000
ENV DATABASE_HOST=prod-db.example.com
CMD ["java", "-jar", "myapp.jar"]
```

Or with `docker run`:
```bash
docker run -e SERVER_PORT=9000 -e DATABASE_HOST=prod-db.example.com myapp:latest
```

**Kubernetes**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: myapp
    image: myapp:latest
    env:
    - name: SERVER_PORT
      value: "9000"
    - name: DATABASE_HOST
      value: "prod-db.example.com"
```

## Convention: ENV_VAR_NAME

Environment variable names follow this convention:

| YAML Property | Environment Variable |
|---------------|----------------------|
| `server.port` | `SERVER_PORT` |
| `database.host` | `DATABASE_HOST` |
| `app.name` | `APP_NAME` |
| `my.foo-bar` | `MY_FOOBAR` |

The translation rule is: **dots → underscores, hyphens removed, uppercase**.

> **Hyphen note:** hyphens are dropped entirely, not converted to underscores.
> `my.foo-bar` → `MY_FOOBAR`, not `MY_FOO_BAR`.
> This differs from Spring Boot's relaxed binding where hyphens become underscores.
> To avoid ambiguity, prefer dot-only property names (e.g., `database.maxPoolSize`).

## Two Mechanisms: Explicit vs Automatic

avaje-config supports two distinct ways to use environment variables.

### 1. Explicit `${ENV_VAR:default}` in YAML (expression evaluation)

Use the `${VAR:default}` syntax inside YAML values. The expression is evaluated at
load time using the exact variable name you specify:

```yaml
database:
  host: ${DATABASE_HOST:localhost}
  port: ${DATABASE_PORT:5432}
  password: ${DATABASE_PASSWORD}      # No default. An env var is required
```

This form:
- Uses the **exact env var name** you specify
- Supports **default values** after the colon
- Supports **compound values** where the env var is part of a larger string:

```yaml
aws.appconfig:
  application: ${ENVIRONMENT_NAME:dev}-my-service   # e.g. "prod-my-service"
```

### 2. Automatic property override (no YAML changes needed)

For **every** property key avaje-config knows about, it automatically checks whether
a matching environment variable exists (using the `toEnvKey` translation rule above).
If one is set, it overrides the file-based value. No `${...}` in the YAML is needed.

```yaml
# application.yaml - no ${...} needed
database:
  host: localhost
  port: 5432
```

```bash
# This env var automatically overrides database.host → DATABASE_HOST
export DATABASE_HOST=prod-db.example.com
java myapp.jar
```

```java
// Still returns "prod-db.example.com" from env var
String host = Config.get("database.host");
```

The automatic check also acts as a **fallback for missing keys**. If a key is not
found in any configuration file, avaje-config will check the translated env var name.

## Accessing in Code

Read environment variables directly:

```java
import io.avaje.config.Config;

String dbHost = Config.get("database.host"); // Uses ${DATABASE_HOST}
int port = Config.getInt("server.port");     // Uses ${SERVER_PORT}
```

Or access the environment variable directly:

```java
String dbHost = System.getenv("DATABASE_HOST");
```

## Priority Order

There are two different cases to keep clear: initial loading and runtime changes.

During initial loading, values are resolved in this order (highest to lowest
priority):

1. System properties matching the configuration key: `java -Dserver.port=9000`
2. Environment variables using the standard name mapping: `SERVER_PORT=9000`
3. Explicit builder values such as `Configuration.builder().put(...)`
4. Loaded configuration files and resources; later sources override earlier sources
5. Defaults passed to getters in code, such as `Config.getInt("server.port", 8080)`

The environment variable name is derived from the configuration key by replacing
`.` with `_`, removing `-`, and upper-casing the result. For example,
`backport.metrics.reporter` maps to `BACKPORT_METRICS_REPORTER`. Hyphens are
removed rather than converted to underscores, so `my.feature-name` maps to
`MY_FEATURENAME`.

Runtime changes made through `Config.setProperty(...)`,
`Configuration.setProperty(...)`, `putAll(...)`, or a dynamic configuration source
such as AWS AppConfig update the in-memory configuration immediately and win for
subsequent reads until the value is changed or cleared.

### Builder values vs system properties and environment variables

`Configuration.builder().put(...)` and `load(...)` are useful for explicit test or
application defaults, but they are still overridden by matching system properties
and environment variables when the configuration is built.

```java
var config = Configuration.builder()
  .put("server.port", "8080")
  .build();
```

With `-Dserver.port=9000`, `config.getInt("server.port")` returns `9000`.
With `SERVER_PORT=9001` and no system property, it returns `9001`.

## Secrets Management

For sensitive values (passwords, API keys), use environment variables:

```yaml
database:
  password: ${DATABASE_PASSWORD}

api:
  key: ${API_KEY}
  secret: ${API_SECRET}
```

**Never** commit these values to version control. Use:

- CI/CD secrets (GitHub Actions, Jenkins, GitLab CI)
- Secret management services (AWS Secrets Manager, HashiCorp Vault)
- .env files (development only, in .gitignore)

## Next Steps

- Use [profiles](profiles.md) for environment-specific configuration
- Set up [change listeners](change-listeners.md) to react to configuration changes

---

## Source: `config/change-listeners.md`

# Reacting to Configuration Changes

How to listen for and respond to configuration changes at runtime.

## Listening to a Specific Property

Use `Config.onChange()` to register a lambda that fires when a named property changes:

```java
import io.avaje.config.Config;

// String value listener
Config.onChange("database.host", newHost -> {
  System.out.println("Database host changed to: " + newHost);
  reconnectDatabase(newHost);
});

// Typed listeners
Config.onChangeInt("server.port", newPort -> {
  System.out.println("Port changed to: " + newPort);
});

Config.onChangeLong("upload.max.bytes", newSize -> {
  fileService.setMaxSize(newSize);
});

Config.onChangeBool("features.enabled", isEnabled -> {
  featureManager.setEnabled(isEnabled);
});
```

## Listening to Multiple Properties

Use the bulk `Config.onChange(Consumer<ModificationEvent>, String... keys)` form
to watch several properties with a single listener:

```java
import io.avaje.config.Config;
import io.avaje.config.ModificationEvent;

Config.onChange(event -> {
  Set<String> changed = event.modifiedKeys();
  System.out.println("Config changed. Modified keys: " + changed);

  if (changed.contains("database.host")) {
    reconnectDatabase(Config.get("database.host"));
  }
  if (changed.contains("cache.ttl")) {
    cacheService.setTtl(Config.getInt("cache.ttl", 300));
  }
}, "database.host", "cache.ttl");
```

Omit the key arguments to listen for **any** configuration change:

```java
Config.onChange(event -> {
  System.out.println("Any config changed: " + event.modifiedKeys());
});
```

## Practical Example: Dynamic Feature Flag

```java
@Singleton
public class FeatureManager {
  private volatile boolean featureEnabled;

  @Inject
  public FeatureManager() {
    this.featureEnabled = Config.getBool("features.new-ui", false);

    Config.onChangeBool("features.new-ui", newValue -> {
      this.featureEnabled = newValue;
      System.out.println("Feature toggle updated: " + newValue);
    });
  }

  public boolean isEnabled() {
    return featureEnabled;
  }
}
```

## Triggering a Reload

Force an immediate reload of all configuration sources (e.g. for AWS AppConfig):

```java
Config.asConfiguration().reloadSources();
```

## Important Notes

- Listeners are called **synchronously**, keeping processing quick
- Changes are delivered when configuration is reloaded (polling or explicit `reloadSources()`)
- Use for dynamic reconfiguration (feature flags, pool sizes, log levels)
- Listeners registered via `Config.onChange()` are held with a strong reference

## Next Steps

- Configure [cloud integration](cloud-integration.md) for dynamic configuration
- See [troubleshooting](troubleshooting.md#listener-not-called) if listeners aren't working

---

## Source: `config/cloud-integration.md`

# Cloud Integration

How to integrate avaje-config with cloud configuration services.

## AWS AppConfig

Integrate with AWS Systems Manager Parameter Store:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-aws-appconfig</artifactId>
  <version>2.5</version>
</dependency>
```

Configure in `application.yaml`:

```yaml
aws.appconfig:
    enabled: true
    application: ${ENVIRONMENT_NAME:dev}-my-application
    environment: ${ENVIRONMENT_NAME:dev}
    configuration: default
```

This automatically loads configuration from AWS AppConfig.


Configure in `application-test.yaml`:

```yaml
aws.appconfig.enabled: false
```

To disable loading the AWS AppConfig when running tests.


## Docker Compose Example

```yaml
version: '3'
services:
  app:
    image: myapp:latest
    environment:
      - DATABASE_HOST=postgres
      - DATABASE_PORT=5432
      - DATABASE_USER=myuser
      - DATABASE_PASSWORD=mypassword
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:14
    environment:
      - POSTGRES_USER=myuser
      - POSTGRES_PASSWORD=mypassword
      - POSTGRES_DB=myapp

  redis:
    image: redis:7
```

## Kubernetes Example

Create a ConfigMap for non-sensitive data:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  application.yaml: |
    server:
      port: 8080
    app:
      name: MyApp
```

Create a Secret for sensitive data:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
type: Opaque
stringData:
  DATABASE_PASSWORD: secretpassword
  API_KEY: secretkey
```

Mount in your Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:latest
    envFrom:
    - configMapRef:
        name: myapp-config
    - secretRef:
        name: myapp-secrets
```


## Next Steps

- Set up [change listeners](change-listeners.md) to react to cloud config updates
- See [troubleshooting](troubleshooting.md) for integration issues
