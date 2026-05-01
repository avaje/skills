# Avaje Bundle — Setup (Flattened)

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

## Source: `config/adding-avaje-config.md`

# Adding avaje-config to Your Project

This guide provides step-by-step instructions for integrating **avaje-config** into a Java project using Maven. It covers basic setup and common usage patterns for retrieving configuration properties.

## What is avaje-config?

avaje-config is a lightweight configuration library that loads and manages application properties from YAML and properties files. It provides:
- Automatic loading of configuration from standard locations
- Type-safe property access (String, int, long, boolean)
- Simple, fluent API for retrieving values

## Step 1: Add Maven Dependency

Add avaje-config to your `pom.xml`:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-config</artifactId>
  <version>5.1</version>
</dependency>
```

Replace `5.1` with the latest version from [Maven Central](https://mvnrepository.com/artifact/io.avaje/avaje-config).

## Step 2: Create Configuration Files

### 2a. Main Application Configuration

Create `src/main/resources/application.yaml` for production configuration with reasonable defaults:

```yaml
# Application configuration
app:
  name: MyApplication
  version: 1.0.0
  port: 8080
  timeout-seconds: 30
  debug: false

# Database configuration
database:
  url: jdbc:postgresql://localhost:5432/myapp
  username: appuser
  max-pool-size: 10

# Feature flags
features:
  logging-enabled: true
```

**Alternative with properties format** - `src/main/resources/application.properties`:

```properties
app.name=MyApplication
app.version=1.0.0
app.port=8080
app.timeout-seconds=30
app.debug=false

database.url=jdbc:postgresql://localhost:5432/myapp
database.username=appuser
database.max-pool-size=10

features.logging-enabled=true
```

### 2b. Test Configuration

Create `src/test/resources/application-test.yaml` for test-specific configuration:

```yaml
# Override settings for testing
app:
  port: 8081
  debug: true

database:
  url: jdbc:h2:mem:test
  username: sa
  max-pool-size: 2

features:
  logging-enabled: false
```

**Alternative with properties format** - `src/test/resources/application-test.properties`:

```properties
app.port=8081
app.debug=true

database.url=jdbc:h2:mem:test
database.username=sa
database.max-pool-size=2

features.logging-enabled=false
```

## Step 3: Use Config API in Your Code

### Getting String Values

```java
import io.avaje.config.Config;

public class AppConfig {

  public static String getAppName() {
    // Get value, throws exception if not found
    return Config.get("app.name");
  }

  public static String getAppName(String defaultName) {
    // Get value with default if not found
    return Config.get("app.name", defaultName);
  }

  public static String getDatabaseUrl() {
    return Config.get("database.url", "jdbc:h2:mem:default");
  }
}
```

### Getting Integer Values

```java
public class AppConfig {

  public static int getPort() {
    // Get integer value
    return Config.getInt("app.port");
  }

  public static int getPort(int defaultPort) {
    // Get integer with default
    return Config.getInt("app.port", defaultPort);
  }

  public static int getMaxPoolSize() {
    return Config.getInt("database.max-pool-size", 5);
  }
}
```

### Getting Long Values

```java
public class AppConfig {

  public static long getTimeoutMillis() {
    // Get long value
    return Config.getLong("app.timeout-millis", 30000L);
  }
}
```

### Getting Boolean Values

```java
public class AppConfig {

  public static boolean isDebugEnabled() {
    // Get boolean value
    return Config.getBool("app.debug");
  }

  public static boolean isLoggingEnabled() {
    return Config.getBool("features.logging-enabled", true);
  }
}
```

## Step 3b: Alternative - Using Configuration Object

As an alternative to using static `Config` methods, you can obtain the underlying `Configuration` object and use it directly. This approach is useful when you want to pass configuration as a parameter, store it as an instance variable, or access it from multiple methods.

### Obtaining the Configuration Object

```java
import io.avaje.config.Config;
import io.avaje.config.Configuration;

Configuration configuration = Config.asConfiguration();
```

### Using Configuration for Property Access

The `Configuration` object provides the same methods as the static `Config` class:

```java
public class AppService {
  
  private final Configuration configuration;
  
  public AppService() {
    this.configuration = Config.asConfiguration();
  }
  
  public void initialize() {
    // Get string values
    String appName = configuration.get("app.name");
    String appName = configuration.get("app.name", "DefaultApp");
    
    // Get integer values
    int port = configuration.getInt("app.port");
    int port = configuration.getInt("app.port", 8080);
    
    // Get long values
    long timeout = configuration.getLong("app.timeout-millis", 30000L);
    
    // Get boolean values
    boolean debug = configuration.getBool("app.debug");
    boolean debug = configuration.getBool("app.debug", false);
  }
}
```

### Complete Example with Configuration Object

```java
public class DatabaseService {
  
  private final Configuration config;
  
  public DatabaseService() {
    this.config = Config.asConfiguration();
  }
  
  public void setupConnection() {
    String url = config.get("database.url");
    String user = config.get("database.username");
    int poolSize = config.getInt("database.max-pool-size", 10);
    
    System.out.println("Connecting to: " + url);
    System.out.println("User: " + user);
    System.out.println("Pool size: " + poolSize);
  }
}
```

### When to Use Configuration Object vs Static Methods

| Scenario | Approach |
|----------|----------|
| Quick property access in a method | Use static `Config` methods |
| Storing configuration as instance variable | Use `Configuration` object |
| Passing configuration to methods/constructors | Use `Configuration` object |
| Dependency injection scenarios | Use `Configuration` object |
| One-off property lookups | Use static `Config` methods |

**Both approaches access the same underlying configuration**, so choose based on your code structure and preferences.

## Step 4: Access Configuration in Your Application

### In a Main Application Class

```java
public class MyApplication {

  public static void main(String[] args) {
    String appName = Config.get("app.name", "MyApp");
    int port = Config.getInt("app.port", 8080);
    boolean debug = Config.getBool("app.debug", false);

    System.out.println("Starting " + appName + " on port " + port);
    if (debug) {
      System.out.println("Debug mode enabled");
    }
  }
}
```

### In a Service Class

```java
public class DatabaseService {

  private final String dbUrl;
  private final String dbUser;
  private final int maxPoolSize;

  public DatabaseService() {
    this.dbUrl = Config.get("database.url");
    this.dbUser = Config.get("database.username");
    this.maxPoolSize = Config.getInt("database.max-pool-size", 10);
  }

  public void connect() {
    System.out.println("Connecting to " + dbUrl);
    // Initialize connection pool with maxPoolSize
  }
}
```

## How Configuration is Loaded

When your application starts, avaje-config automatically loads properties in this order:

1. **Main resources** - `src/main/resources/application.yaml` or `.properties`
2. **Test resources** (when running tests) - `src/test/resources/application-test.yaml` or `.properties`
3. **Later sources override earlier ones** - Test configuration takes precedence over main configuration

This means:
- Define default values in `application.yaml` (main resources)
- Override specific values in `application-test.yaml` when running tests
- Your tests run with test-specific configuration automatically

## Common Patterns

### Configuration Wrapper Class

Create a configuration class to centralize all property access:

```java
public class Config {

  public static String appName() {
    return io.avaje.config.Config.get("app.name", "MyApplication");
  }

  public static int port() {
    return io.avaje.config.Config.getInt("app.port", 8080);
  }

  public static String databaseUrl() {
    return io.avaje.config.Config.get("database.url");
  }

  public static int maxPoolSize() {
    return io.avaje.config.Config.getInt("database.max-pool-size", 10);
  }
}

// Usage:
int port = Config.port();
String dbUrl = Config.databaseUrl();
```

### Constructor Injection Pattern

Use configuration to initialize services:

```java
public class DatabaseConnectionPool {

  private final String url;
  private final int maxSize;

  public DatabaseConnectionPool() {
    this.url = io.avaje.config.Config.get("database.url");
    this.maxSize = io.avaje.config.Config.getInt("database.max-pool-size", 10);
  }

  public void initialize() {
    // Set up connection pool
  }
}
```

## Testing with Configuration

When running tests, avaje-config automatically uses `application-test.yaml` or `application-test.properties`:

```java
@Test
public void testWithTestConfiguration() {
  // This test automatically uses application-test.yaml
  // Port will be 8081 (from test config)
  int port = Config.getInt("app.port");
  assertEquals(8081, port);
}
```

## Key Directories and Files

```
src/
├── main/
│   └── resources/
│       ├── application.yaml       # Main configuration (production defaults)
│       └── application.properties # Alternative format for main config
└── test/
    └── resources/
        ├── application-test.yaml       # Test configuration overrides
        └── application-test.properties # Alternative format for test config
```

## Next Steps

- Review the [avaje-config documentation](https://avaje.io/config/) for advanced features
- Consider creating a wrapper class for type-safe configuration access
- Use environment-specific values to handle different deployment environments
- Organize your configuration hierarchically (use dot notation like `app.port`, `database.url`)

## Troubleshooting

**Property not found exception:**
- Ensure the property exists in `application.yaml` or `application-test.yaml`
- Check property naming - use consistent dot notation (e.g., `app.port` not `app-port`)
- Verify the file is in the correct location (`src/main/resources` or `src/test/resources`)

**Test uses wrong configuration:**
- Ensure `application-test.yaml` or `application-test.properties` exists in `src/test/resources`
- Verify filename spelling exactly matches

**Values not updated:**
- Stop and restart your application
- Configuration is loaded once at startup

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
