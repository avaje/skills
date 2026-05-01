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
  <version>2.5</version>
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

Avaje Config supports multiple configuration sources (in priority order):

1. System properties: `-Dserver.port=9000`
2. Environment variables: `SERVER_PORT=9000`
3. Application properties file: `application.yaml`
4. Default values in code

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

Defaults can be overridden by:

1. **System properties**: `java -Dserver.port=9000`
2. **Environment variables**: `export SERVER_PORT=9000`
3. **Configuration files** for current environment: `application-prod.yaml`

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

Activate a profile by setting the `config.profile` property:

```bash
# Development
java -Dconfig.profile=dev myapp.jar

# Test
java -Dconfig.profile=test myapp.jar

# Production
java -Dconfig.profile=prod myapp.jar
```

Or with environment variables:

```bash
export CONFIG_PROFILE=prod
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
String profile = Config.get("config.profile", "dev");
if (profile.equals("prod")) {
  // Production-specific behavior
}
```

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
| server.port | SERVER_PORT |
| database.host | DATABASE_HOST |
| app.name | APP_NAME |

The convention is: `UPPERCASE_WITH_UNDERSCORES`

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

Configuration values are resolved in this order (highest to lowest priority):

1. System properties: `java -Dserver.port=9000`
2. Environment variables: `export SERVER_PORT=9000`
3. Configuration file values: `application.yaml`
4. Defaults in code

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

## Adding a Configuration Listener

Implement `ConfigChangeListener` to be notified of configuration changes:

```java
import io.avaje.config.Config;
import io.avaje.config.ConfigChangeListener;

public class MyConfigListener implements ConfigChangeListener {
  @Override
  public void onConfigChange(ConfigChangeEvent event) {
    System.out.println("Configuration changed: " + event.getProperty());
  }
}
```

Register the listener:

```java
Config.addChangeListener(new MyConfigListener());
```

## Listening to Specific Properties

Listen to changes on specific properties:

```java
public class DatabaseConfigListener implements ConfigChangeListener {
  @Override
  public void onConfigChange(ConfigChangeEvent event) {
    String property = event.getProperty();
    String newValue = event.getNewValue();
    
    if (property.equals("database.host")) {
      System.out.println("Database host changed to: " + newValue);
      reconnectDatabase(newValue);
    }
  }
  
  private void reconnectDatabase(String newHost) {
    // Close existing connection and reconnect
  }
}
```

## Practical Examples

### Reload Cache on Configuration Change

```java
public class CacheConfigListener implements ConfigChangeListener {
  private final CacheService cacheService;
  
  public CacheConfigListener(CacheService cacheService) {
    this.cacheService = cacheService;
  }
  
  @Override
  public void onConfigChange(ConfigChangeEvent event) {
    if (event.getProperty().equals("cache.ttl")) {
      int newTtl = Integer.parseInt(event.getNewValue());
      cacheService.setTtl(newTtl);
      cacheService.clear();
    }
  }
}
```

### Update Logger Configuration

```java
public class LoggerConfigListener implements ConfigChangeListener {
  @Override
  public void onConfigChange(ConfigChangeEvent event) {
    if (event.getProperty().equals("logging.level")) {
      String level = event.getNewValue();
      LoggerFactory.setLogLevel(level);
    }
  }
}
```

### Notify Dependents

```java
public class AppConfigListener implements ConfigChangeListener {
  private final ApplicationEventBus eventBus;
  
  public AppConfigListener(ApplicationEventBus eventBus) {
    this.eventBus = eventBus;
  }
  
  @Override
  public void onConfigChange(ConfigChangeEvent event) {
    ConfigurationChangedEvent evt = 
      new ConfigurationChangedEvent(event.getProperty(), event.getNewValue());
    eventBus.publish(evt);
  }
}
```

## Using with Dependency Injection

With Avaje Inject, register the listener in your application setup:

```java
@Singleton
public class ApplicationStartup {
  public ApplicationStartup(ConfigChangeListener listener) {
    Config.addChangeListener(listener);
  }
}
```

## Important Notes

- Listeners are called **synchronously** - keep processing quick
- Changes are detected when configuration is reloaded
- Use for dynamic reconfiguration, not for every request
- External configuration services can push updates (cloud config)

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
