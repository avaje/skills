# Avaje Bundle — Testing (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `config/testing.md`

# Testing with Avaje Config

How to test applications that use avaje-config.

## Test Configuration Files

Create test-specific configuration in `src/test/resources`:

```
src/test/resources/
├── application.yaml          # Test defaults
├── application-test.yaml     # Profile-specific
└── application-it.yaml       # Integration test config
```

**application-test.yaml**:
```yaml
server:
  port: 0  # Use random port

database:
  host: localhost
  port: 5432

cache:
  enabled: false
```

## Using Test Configuration

Tests automatically use `src/test/resources/application.yaml`:

```java
@Test
public void testConfiguration() {
  String dbHost = Config.get("database.host");
  assertEquals("localhost", dbHost);
}
```

## Overriding Configuration in Tests

Override specific properties:

```java
@Test
public void testWithCustomPort() {
  System.setProperty("server.port", "9000");
  try {
    int port = Config.getInt("server.port");
    assertEquals(9000, port);
  } finally {
    System.clearProperty("server.port");
  }
}
```

## Mocking Configuration

For advanced testing, mock the Config class:

```java
import static org.mockito.Mockito.*;

@Test
public void testWithMockedConfig() {
  // Create spy on real Config
  Config spy = spy(Config.class);
  
  when(spy.get("server.port")).thenReturn("9000");
  
  int port = Integer.parseInt(spy.get("server.port"));
  assertEquals(9000, port);
}
```

## JUnit 5 Extension

Create a custom extension for configuration:

```java
public class ConfigExtension implements BeforeEachCallback {
  private Map<String, String> originalProperties;
  
  @Override
  public void beforeEach(ExtensionContext context) {
    originalProperties = new HashMap<>();
    
    // Save original values
    originalProperties.put("server.port", System.getProperty("server.port"));
  }
  
  public void setProperty(String key, String value) {
    System.setProperty(key, value);
  }
  
  public void reset() {
    // Restore original values
    originalProperties.forEach((key, value) -> {
      if (value != null) {
        System.setProperty(key, value);
      } else {
        System.clearProperty(key);
      }
    });
  }
}
```

Use in tests:

```java
@ExtendWith(ConfigExtension.class)
public class MyTest {
  @Test
  public void test(ConfigExtension config) {
    config.setProperty("server.port", "9000");
    
    int port = Config.getInt("server.port");
    assertEquals(9000, port);
  }
}
```

## Integration Testing

For integration tests with external services:

**application-it.yaml**:
```yaml
server:
  port: 8080

database:
  host: localhost
  port: 5432
  name: test_db

redis:
  host: localhost
  port: 6379
```

Use Docker Compose or Testcontainers:

```java
public class IntegrationTest {
  @ClassRule
  public static DockerComposeContainer<?> environment =
    new DockerComposeContainer<>(new File("docker-compose.it.yml"))
      .withExposedService("postgres", 5432)
      .withExposedService("redis", 6379);
  
  @Test
  public void testWithRealServices() {
    String dbHost = Config.get("database.host");
    // Test with real database and redis
  }
}
```

## Testing Configuration Changes

Test configuration change listeners:

```java
@Test
public void testConfigChangeListener() {
  List<String> changes = new ArrayList<>();
  
  Config.addChangeListener(event -> {
    changes.add(event.getProperty());
  });
  
  System.setProperty("server.port", "9000");
  
  // Trigger configuration reload
  Config.reload();
  
  assertTrue(changes.contains("server.port"));
}
```

## Best Practices

| Practice | Reason |
|----------|--------|
| Use separate test config file | Prevents test pollution |
| Reset properties after tests | Clean state for next test |
| Use random ports | Allows parallel test execution |
| Mock external services | Faster, more reliable tests |
| Test both success and failure cases | Comprehensive coverage |

## Next Steps

- Learn about [environment variables](environment-variables.md) in tests
- See [troubleshooting](troubleshooting.md) for test issues

---

## Source: `config/troubleshooting.md`

# Troubleshooting

Common issues and solutions when using avaje-config.

## Property Not Found

**Symptom**: `No property found for key: server.port`

**Solution**:
1. Check property name spelling and case sensitivity
2. Ensure configuration file is in `src/main/resources/`
3. Verify the configuration file format is valid YAML
4. Check for typos in environment variable names

Example:
```yaml
# CORRECT
server:
  port: 8080

# NOT server_port or serverPort in YAML
```

**Accessing**:
```java
// Access nested properties with dot notation
int port = Config.getInt("server.port", 8080); // Provide default
```

## Profile Not Loading

**Symptom**: `application-prod.yaml` is not being loaded

**Solution**:
1. Verify profile is activated: `java -Dconfig.profile=prod myapp.jar`
2. Check environment variable: `export CONFIG_PROFILE=prod`
3. Ensure file name matches the profile: `application-PROFILE.yaml`
4. Verify file is in `src/main/resources/`

Check active profile:
```java
String profile = Config.get("config.profile", "dev");
System.out.println("Active profile: " + profile);
```

## Listener Not Called

**Symptom**: `ConfigChangeListener` never triggers

**Solution**:
1. Ensure listener is registered: `Config.addChangeListener(listener)`
2. Verify configuration source supports change notifications
3. Call `Config.reload()` to trigger change detection
4. Check that the property actually changed

Debug:
```java
Config.addChangeListener(event -> {
  System.out.println("Config changed: " + event.getProperty());
});

// Force reload
Config.reload();
```

## Type Conversion Error

**Symptom**: `NumberFormatException` or similar when getting property

**Solution**:
1. Verify property value type matches the `getXxx()` method
2. Provide a default value
3. Check for leading/trailing whitespace in YAML

Examples:
```yaml
# Correct types
server:
  port: 8080          # Integer
  ssl: true           # Boolean
  name: "localhost"   # String
```

```java
// Matching types
int port = Config.getInt("server.port");           // OK
boolean ssl = Config.getBool("server.ssl");        // OK
String name = Config.get("server.name");           // OK

// Type mismatch - these will fail:
// int port = Config.getInt("server.name");        // NO - wrong type
// boolean ssl = Config.getBool("server.port");    // NO - wrong type
```

## Environment Variables Not Working

**Symptom**: Environment variables not replacing `${ENV_VAR}` in YAML

**Solution**:
1. Verify syntax: `${ENV_VAR:default}` (colon before default)
2. Ensure environment variable is set: `export ENV_VAR=value`
3. Check variable name matches convention (UPPERCASE_UNDERSCORE)
4. Verify property is defined in YAML before setting

Example:
```yaml
database:
  host: ${DATABASE_HOST:localhost}  # Correct: colon before default
  port: ${DATABASE_PORT}             # No default - env var required
```

```bash
# Set the environment variable
export DATABASE_HOST=prod-db.example.com
export DATABASE_PORT=5432
java myapp.jar
```

## Configuration Class Not Found

**Symptom**: `No @Config class found for configuration`

**Solution**:
1. Ensure `@Config` class is on the classpath
2. Verify class is in scanned package
3. Check for compilation errors
4. Ensure dependency on `avaje-config` is included

Example:
```java
package com.example.config;

import io.avaje.config.Config;

@Config
public class DatabaseConfig {
  public final String host;
  public final int port;
  
  public DatabaseConfig(String host, int port) {
    this.host = host;
    this.port = port;
  }
}
```

## Native Image Issues

**Symptom**: Native image fails to start or missing configuration

**Solution**:
1. Generate reflection metadata: `native-image -agentlib:native-image=config-output-dir=...`
2. Ensure all config files are on classpath
3. Use environment variables for dynamic values
4. Verify GraalVM version compatibility

See [Native Image Guide](native-image.md) for detailed setup.

## Performance Issues

**Symptom**: Configuration loading is slow

**Solution**:
1. Avoid loading configuration in tight loops
2. Cache frequently accessed values
3. Use `@Config` classes for groups of properties
4. Consider native image for faster startup

Optimization:
```java
// Cache the value
private static final int CACHE_TTL = Config.getInt("cache.ttl", 300);

// Or use @Config class (loaded once)
@Config
public class CacheConfig {
  public final int ttl;
  
  public CacheConfig(int ttl) {
    this.ttl = ttl;
  }
}
```

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `NullPointerException` | Property not found | Provide default or check spelling |
| `NumberFormatException` | Wrong type conversion | Check property type matches method |
| `FileNotFoundException` | Config file missing | Move to `src/main/resources/` |
| `ClassNotFoundException` | `@Config` class not scanned | Check package location |

## Getting Help

1. Check the [Avaje Config documentation](https://avaje.io/config/)
2. Enable debug logging: `logging.level: DEBUG`
3. Check the [GitHub issues](https://github.com/avaje/avaje-config/issues)
4. Join the [Discord community](https://discord.gg/Qcqf9R27BR)
