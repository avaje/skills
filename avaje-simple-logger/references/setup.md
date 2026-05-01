# Avaje Bundle — Setup (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `simple-logger/add-avaje-simple-logger-to-maven-project.md`

# Guide: Add avaje-simple-logger to an Existing Maven Project

This guide provides step-by-step instructions for adding avaje-simple-logger to a Maven project, including how to replace Logback or other SLF4J implementations.

## Prerequisites

Before starting, verify the following:

- [ ] You have a Maven project with a `pom.xml` file
- [ ] Java 11 or later is the target version
- [ ] You have identified any existing logging framework (Logback, Log4j 2, etc.)
- [ ] You understand the difference between your `src/main/resources` and `src/test/resources` directories

### Detecting Your Current Logging Framework

Run the following command to see your project's dependencies:

```bash
mvn dependency:tree | grep -E "(logback|log4j|slf4j|logger)"
```

This will help you identify which scenario (Fresh Start, Replace Logback, or Replace Log4j) applies to your project.

---

## Scenario Decision Tree

**Does your project have any logging framework?**

- **No logging framework** → Go to: [Option 1: Fresh Start](#option-1-fresh-start)
- **Using Logback** (ch.qos.logback) → Go to: [Option 2: Replace Logback](#option-2-replace-logback)
- **Using Log4j 2** (org.apache.logging.log4j) → Go to: [Option 3: Replace-log4j-2](#option-3-replace-log4j-2)
- **Using other SLF4J implementation** → Use Option 2 as reference, remove the other binding

---

## Option 1: Fresh Start

**When to use:** Adding logging to a project with no existing logging framework.

### Step 1: Add the Dependency

Open your `pom.xml` and add the following dependency in the `<dependencies>` section:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-simple-logger</artifactId>
  <version>1.5-RC1</version>
</dependency>
```

### Step 2: Create Production Configuration

Create the file `src/main/resources/avaje-logger.properties` with the following content:

```properties
# Default log level for all loggers (TRACE, DEBUG, INFO, WARN, ERROR)
logger.defaultLogLevel=warn

# Output format: json (default) or plain
logger.format=json

# JSON field naming convention: underscore (default), camel, or legacy
logger.naming=underscore

# Logger name formatting: full, short, or character limit (e.g., 100)
logger.nameTargetLength=50

# Timezone for log timestamps (optional)
#logger.timezone=UTC

# Specific package log levels (optional)
log.level.io.avaje=INFO
log.level.com.mycompany=DEBUG
```

### Step 3: Create Test Configuration

Create the file `src/test/resources/avaje-logger-test.properties` with the following content:

```properties
# For tests, use plain text format for readability
logger.format=plain

# Default log level for tests (usually more verbose than production)
logger.defaultLogLevel=INFO

# Test-specific package levels
log.level.io.avaje=DEBUG
log.level.com.mycompany=DEBUG
```

### Step 4: Verify the Setup

Run the following command to verify everything is working:

```bash
mvn clean test
```

You should see logs appearing in the test output in plain text format. If you don't see any logs, verify:
- The properties files are in the correct directories
- The log level is not set too high (WARN or ERROR might not show test logs)

---

## Option 2: Replace Logback

**When to use:** Your project currently uses Logback (`ch.qos.logback`).

### Step 1: Remove Logback Dependencies

In your `pom.xml`, find and remove these dependencies:

```xml
<!-- REMOVE THESE -->
<dependency>
  <groupId>ch.qos.logback</groupId>
  <artifactId>logback-classic</artifactId>
  <!-- version ... -->
</dependency>

<dependency>
  <groupId>ch.qos.logback</groupId>
  <artifactId>logback-core</artifactId>
  <!-- version ... -->
</dependency>
```

Also check for and remove any other logging bridges:
```xml
<!-- REMOVE if present -->
<dependency>
  <groupId>org.slf4j</groupId>
  <artifactId>jcl-over-slf4j</artifactId>
</dependency>
```

### Step 2: Add avaje-simple-logger Dependency

Add the avaje-simple-logger dependency to your `pom.xml`:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-simple-logger</artifactId>
  <version>1.5-RC1</version>
</dependency>
```

### Step 3: Remove Logback Configuration Files

Find and delete these files from your project:
- `src/main/resources/logback.xml`
- `src/main/resources/logback-spring.xml` (if using Spring Boot)
- `src/test/resources/logback-test.xml`

### Step 4: Create avaje-logger.properties from Logback Configuration

Review your old `logback.xml` file and map the configuration to `avaje-logger.properties`.

#### Configuration Mapping Reference

| Logback Setting | avaje-simple-logger Equivalent |
|---|---|
| `<root level="WARN">` | `logger.defaultLogLevel=warn` |
| `<logger name="com.foo" level="DEBUG">` | `log.level.com.foo=DEBUG` |
| `<pattern>%msg%n</pattern>` | `logger.format=plain` |
| `<pattern>%d %msg%n</pattern>` | `logger.format=json` (timestamps included) |
| `<appender ref="STDOUT">` | (implicit - uses System.out) |

#### Example: Convert logback.xml to avaje-logger.properties

**Old logback.xml:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <root level="WARN">
    <appender-ref ref="STDOUT" />
  </root>
  <logger name="com.mycompany" level="DEBUG" />
  <logger name="io.avaje" level="INFO" />
</configuration>
```

**New avaje-logger.properties:**
```properties
logger.defaultLogLevel=warn
logger.format=json
log.level.com.mycompany=DEBUG
log.level.io.avaje=INFO
```

### Step 5: Create Test Configuration

Create `src/test/resources/avaje-logger-test.properties`:

```properties
logger.format=plain
logger.defaultLogLevel=INFO
log.level.com.mycompany=DEBUG
log.level.io.avaje=DEBUG
```

### Step 6: Verify the Migration

Run the following commands:

```bash
# Check that Logback is no longer a dependency
mvn dependency:tree | grep logback

# Build and test
mvn clean test
```

You should see:
- No logback entries in dependency tree
- Logs appearing in test output (in plain format)
- No "SLF4J: No providers found" errors

---

## Option 3: Replace Log4j 2

**When to use:** Your project currently uses Apache Log4j 2.

### Step 1: Remove Log4j 2 Dependencies

In your `pom.xml`, find and remove these dependencies:

```xml
<!-- REMOVE THESE -->
<dependency>
  <groupId>org.apache.logging.log4j</groupId>
  <artifactId>log4j-api</artifactId>
  <!-- version ... -->
</dependency>

<dependency>
  <groupId>org.apache.logging.log4j</groupId>
  <artifactId>log4j-core</artifactId>
  <!-- version ... -->
</dependency>

<dependency>
  <groupId>org.apache.logging.log4j</groupId>
  <artifactId>log4j-slf4j2-impl</artifactId>
  <!-- version ... -->
</dependency>
```

Also check for these and remove if present:
```xml
<!-- REMOVE if present -->
<dependency>
  <groupId>org.apache.logging.log4j</groupId>
  <artifactId>log4j-jcl</artifactId>
</dependency>
```

### Step 2: Add avaje-simple-logger Dependency

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-simple-logger</artifactId>
  <version>1.5-RC1</version>
</dependency>
```

### Step 3: Remove Log4j 2 Configuration Files

Find and delete:
- `src/main/resources/log4j2.xml`
- `src/main/resources/log4j2.properties`
- `src/main/resources/log4j2.yaml`
- `src/test/resources/log4j2-test.xml`
- `src/test/resources/log4j2-test.properties`

### Step 4: Create avaje-logger.properties from Log4j 2 Configuration

Review your old `log4j2.xml` and map to `avaje-logger.properties`.

#### Example: Convert log4j2.xml to avaje-logger.properties

**Old log4j2.xml:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="warn">
  <Appenders>
    <Console name="Console" target="SYSTEM_OUT">
      <PatternLayout pattern="%msg%n"/>
    </Console>
  </Appenders>
  <Loggers>
    <Root level="warn">
      <AppenderRef ref="Console"/>
    </Root>
    <Logger name="com.mycompany" level="debug"/>
    <Logger name="io.avaje" level="info"/>
  </Loggers>
</Configuration>
```

**New avaje-logger.properties:**
```properties
logger.defaultLogLevel=warn
logger.format=plain
log.level.com.mycompany=debug
log.level.io.avaje=info
```

### Step 5: Create Test Configuration

Create `src/test/resources/avaje-logger-test.properties`:

```properties
logger.format=plain
logger.defaultLogLevel=INFO
log.level.com.mycompany=DEBUG
log.level.io.avaje=DEBUG
```

### Step 6: Verify the Migration

```bash
# Check that Log4j 2 is no longer a dependency
mvn dependency:tree | grep log4j

# Build and test
mvn clean test
```

---

## Dependency Configuration Details

### Main Dependency

Use this for projects that need dynamic log level configuration:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-simple-logger</artifactId>
  <version>1.5-RC1</version>
</dependency>
```

This includes:
- `avaje-simple-json-logger` - Core JSON logging
- `avaje-config` - Dynamic configuration support
- `avaje-applog` and `avaje-applog-slf4j` - Application logging bridge

### Alternative: Lightweight Version

If you don't need dynamic configuration, use this instead:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-simple-json-logger</artifactId>
  <version>1.5-RC1</version>
</dependency>
```

Note: You can still change log levels programmatically via `LoggerContext.get().putAll()` if needed.

### Removing Other SLF4J Bindings

Make sure you only have ONE SLF4J binding. Remove any of these if present:

```xml
<!-- Remove any of these -->
<dependency>
  <groupId>org.slf4j</groupId>
  <artifactId>slf4j-simple</artifactId>
</dependency>

<dependency>
  <groupId>org.slf4j</groupId>
  <artifactId>slf4j-jdk14</artifactId>
</dependency>

<dependency>
  <groupId>org.slf4j</groupId>
  <artifactId>slf4j-log4j12</artifactId>
</dependency>
```

---

## Resource Configuration (Production)

### File Location and Name

**Production:** `src/main/resources/avaje-logger.properties`

This file is loaded automatically when the application starts.

### Key Settings

#### logger.defaultLogLevel
The default log level for all loggers when no specific level is configured.

**Values:** `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`

```properties
logger.defaultLogLevel=warn
```

#### logger.format
Output format for logs.

**Values:** `json` (default), `plain`

```properties
# JSON format (structured logs for log aggregation)
logger.format=json

# Plain text format (human readable)
logger.format=plain
```

#### log.level.{package}
Set specific log levels for individual packages.

```properties
# Set com.mycompany package to DEBUG level
log.level.com.mycompany=DEBUG

# Set io.avaje package to INFO level
log.level.io.avaje=INFO

# Multiple settings
log.level.com.foo=WARN
log.level.com.foo.bar=DEBUG
```

#### logger.component
The application component name (added to JSON output).

```properties
# Literal value
logger.component=my-service

# From environment variable or system property
logger.component=${SERVICE_NAME}

# From system property with fallback
logger.component=${app.name:my-service}
```

#### logger.environment
The environment name (added to JSON output).

```properties
# Literal value
logger.environment=production

# From environment variable with fallback
logger.environment=${APP_ENV:local}
```

#### logger.nameTargetLength
How to format logger names in output.

```properties
# Use full logger name (default)
logger.nameTargetLength=full

# Use only the class name (last part after .)
logger.nameTargetLength=short

# Abbreviate to 100 characters (shortens package names)
logger.nameTargetLength=100
```

#### logger.timezone
Timezone for timestamps in logs.

```properties
# Use UTC timezone
logger.timezone=UTC

# Use system default timezone
logger.timezone=system
```

#### logger.timestampPattern
Timestamp format in logs.

**Values:** `ISO_OFFSET_DATE_TIME` (default), `ISO_ZONED_DATE_TIME`, `ISO_LOCAL_DATE_TIME`, `ISO_DATE_TIME`, `ISO_INSTANT`

```properties
logger.timestampPattern=ISO_OFFSET_DATE_TIME
```

#### logger.naming
JSON field naming convention (when using `logger.format=json`).

**Values:** `underscore` (default), `camel`, `legacy`

```properties
# Underscore format (default, recommended for new projects)
# Fields: logger_name, exception_type, exception_message, exception_stacktrace
logger.naming=underscore

# CamelCase format
# Fields: loggerName, exceptionType, exceptionMessage, exceptionStacktrace
logger.naming=camel

# Legacy format (for backwards compatibility)
# Fields: logger, exceptionType, exceptionMessage, stacktrace
logger.naming=legacy
```

Example JSON output with underscore (default):
```json
{
  "logger_name":"io.avaje.config",
  "exception_type":"java.lang.RuntimeException",
  "exception_message":"Configuration error"
}
```

Example JSON output with camelCase:
```json
{
  "loggerName":"io.avaje.config",
  "exceptionType":"java.lang.RuntimeException",
  "exceptionMessage":"Configuration error"
}
```

#### logger.propertyNames
Override specific JSON property names.

```properties
# Override individual property names (comma and equals delimited)
logger.propertyNames=logger_name=app_logger,env=application_env,timestamp=@timestamp

# Override a single property
logger.propertyNames=logger_name=loggerName
```

### Complete Example Configuration

```properties
# Basic configuration
logger.defaultLogLevel=warn
logger.format=json
logger.naming=underscore
logger.nameTargetLength=full
logger.timezone=UTC

# Application context
logger.component=${SERVICE_NAME:my-app}
logger.environment=${APP_ENV:development}

# Package-specific levels
log.level.com.mycompany=INFO
log.level.com.mycompany.sensitive=DEBUG
log.level.io.avaje=WARN
log.level.org.springframework=WARN

# Adjust for troubleshooting
# log.level.com.mycompany.payment=TRACE
```

---

## Test Configuration

### File Location and Name

**Testing:** `src/test/resources/avaje-logger-test.properties`

This file overrides the production config when running tests (Maven's test classpath has different resource priority).

### Typical Test Configuration

```properties
# Plain format for readability during test execution
logger.format=plain

# Higher default log level to see test activity
logger.defaultLogLevel=INFO

# More verbose logging for specific packages
log.level.com.mycompany=DEBUG
log.level.com.mycompany.test=TRACE
log.level.io.avaje=DEBUG
```

### When to Create This File

- You want different log levels during testing than production
- You prefer plain text format during test execution
- You need TRACE-level logging for specific packages during testing
- You want less verbose logging to reduce test output

### If Not Created

If you only create `avaje-logger.properties`, the same settings will be used for both production and testing.

---

## Verification

### Build Verification

Ensure the project builds without errors:

```bash
mvn clean package
```

Expected output:
- ✅ No SLF4J warnings or errors
- ✅ Build completes successfully
- ✅ No "Multiple SLF4J bindings found" messages

### Test Verification

Run the tests to verify logging is working:

```bash
mvn test
```

Expected output:
- ✅ Tests execute successfully
- ✅ Log output appears in the console
- ✅ Log format matches your configuration (JSON or plain)
- ✅ Log levels are respected (DEBUG logs only if level ≤ DEBUG)

### Manual Logging Test

Create a simple test to verify logging works:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.junit.jupiter.api.Test;

public class LoggingTest {
  private static final Logger log = LoggerFactory.getLogger(LoggingTest.class);

  @Test
  void testLogging() {
    log.trace("This is a TRACE message");
    log.debug("This is a DEBUG message");
    log.info("This is an INFO message");
    log.warn("This is a WARN message");
    log.error("This is an ERROR message");
  }
}
```

Run this test:
```bash
mvn test -Dtest=LoggingTest
```

You should see all 5 log messages in the output (or up to the level configured in your properties file).

### Verification Checklist

- [ ] Build completes without errors
- [ ] No SLF4J provider warnings
- [ ] Tests run and produce log output
- [ ] Log format matches configuration (JSON or plain)
- [ ] Log levels are being respected
- [ ] Package-specific log levels are working

---

## GraalVM Native Image Setup

If you're building a GraalVM native image, avaje-simple-logger is designed to work seamlessly.

### Automatic Initialization

avaje-simple-logger automatically initializes at GraalVM build time:
- The logger is set up during image build (not at runtime)
- Configuration from `avaje-logger.properties` is processed at build time
- Your native image will have logging ready to use

You should see this in the build output:
```
io.avaje.simplelogger.graalvm.BuildInitialization
```

This indicates avaje-simple-logger is being prepared for the native image.


### Build Command Example

```bash
native-image -cp target/my-app.jar com.mycompany.MyApplication my-app
```

The logger will be ready to use in the resulting native binary.

---

## Dynamic Log Levels (Advanced)

This section is optional. Use it if you need to change log levels at runtime (useful for K8s/Lambda).

### When to Use

- Production applications in Kubernetes
- Serverless functions (AWS Lambda)
- Applications using AWS AppConfig or similar configuration services
- Need to increase logging levels temporarily for troubleshooting

### How It Works

avaje-simple-logger integrates with `avaje-config`. When configuration changes start with `log.level.`, they are automatically applied:

```properties
# Initial configuration
log.level.com.mycompany=WARN

# Later, if avaje-config updates this property:
log.level.com.mycompany=DEBUG

# The change is applied without restarting the application
```

### Programmatic Log Level Changes

You can also change log levels in your code:

```java
import io.avaje.applog.LoggerContext;
import java.util.HashMap;
import java.util.Map;

// Change log levels programmatically
Map<String, String> levels = new HashMap<>();
levels.put("com.mycompany", "DEBUG");
levels.put("com.mycompany.payment", "TRACE");
LoggerContext.get().putAll(levels);
```


---

## Troubleshooting

### Error: "SLF4J: No providers found"

**Cause:** avaje-simple-logger dependency is not in the classpath.

**Solution:**
1. Verify the dependency is added to `pom.xml`
2. Run `mvn dependency:tree` to confirm it's present
3. Check the `<version>` tag is correct
4. Run `mvn clean install` to refresh your local repository

### Error: "Multiple SLF4J bindings detected"

**Cause:** More than one SLF4J implementation is in the classpath (e.g., both Logback and avaje-simple-logger).

**Solution:**
1. Run `mvn dependency:tree | grep -E "(logback|log4j|slf4j-simple|avaje-simple)"` to find duplicates
2. Remove the old logging implementation (Logback, Log4j, etc.)
3. Keep only avaje-simple-logger

### Issue: No logs appearing in output

**Cause:** Log level is set too high.

**Solution:**
1. Lower `logger.defaultLogLevel` in your properties file
2. Run the application again with `logger.defaultLogLevel=DEBUG` or `logger.defaultLogLevel=TRACE`
3. Check that your properties file is in the correct location (`src/main/resources/avaje-logger.properties`)

### Issue: Logs not in JSON format

**Cause:** `logger.format=plain` is set instead of json.

**Solution:**
1. In `src/main/resources/avaje-logger.properties`, set `logger.format=json`
2. Rebuild: `mvn clean package`
3. Re-run your application

### Issue: Properties file not being read

**Cause:** File is in the wrong location or has wrong name.

**Solution:**
1. Verify file location: `src/main/resources/avaje-logger.properties` (exactly this path)
2. Verify filename: `avaje-logger.properties` (exact case)
3. Check that `src/main/resources` is marked as a resource directory in your IDE
4. Run `mvn clean package` to ensure resources are copied

### Issue: Test logs not appearing

**Cause:** Test properties file is missing or log level is too high.

**Solution:**
1. Create `src/test/resources/avaje-logger-test.properties`
2. Set `logger.defaultLogLevel=DEBUG` or `logger.defaultLogLevel=INFO`
3. Run tests with `mvn test`

---

## Complete Examples

### Example 1: Spring Boot Application

**pom.xml (relevant sections):**
```xml
<dependencies>
  <!-- Remove logback-spring-boot-starter if present -->

  <!-- Add avaje-simple-logger -->
  <dependency>
    <groupId>io.avaje</groupId>
    <artifactId>avaje-simple-logger</artifactId>
    <version>1.5-RC1</version>
  </dependency>

  <!-- Spring Boot dependencies -->
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
  </dependency>
</dependencies>
```

**src/main/resources/application.properties:**
```properties
spring.application.name=my-spring-app
server.port=8080
```

**src/main/resources/avaje-logger.properties:**
```properties
logger.defaultLogLevel=info
logger.format=json
logger.component=my-spring-app
logger.environment=production
log.level.org.springframework=warn
log.level.org.springframework.web=info
log.level.com.mycompany=debug
```

**src/test/resources/avaje-logger-test.properties:**
```properties
logger.format=plain
logger.defaultLogLevel=debug
log.level.org.springframework=warn
log.level.com.mycompany=debug
```

### Example 2: Multi-module Maven Project

**Parent pom.xml:**
```xml
<project>
  <groupId>com.mycompany</groupId>
  <artifactId>my-project-parent</artifactId>
  <packaging>pom</packaging>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>io.avaje</groupId>
        <artifactId>avaje-simple-logger</artifactId>
        <version>1.5-RC1</version>
      </dependency>
    </dependencies>
  </dependencyManagement>

  <modules>
    <module>core</module>
    <module>service</module>
    <module>api</module>
  </modules>
</project>
```

**Each module's pom.xml:**
```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-simple-logger</artifactId>
  <!-- Version inherited from parent -->
</dependency>
```

**Shared properties file at root level or in a resources module:**
- `src/main/resources/avaje-logger.properties` (same in each module or in common resources)
- `src/test/resources/avaje-logger-test.properties` (same in each module or in common resources)



### Example 3: GraalVM Native Image Project

**pom.xml:**
```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-simple-logger</artifactId>
  <version>1.5-RC1</version>
</dependency>

<dependency>
  <groupId>org.graalvm.buildtools</groupId>
  <artifactId>native-maven-plugin</artifactId>
  <version>1.0.0</version>
  <executions>
    <execution>
      <goals>
        <goal>build</goal>
      </goals>
    </execution>
  </executions>
</dependency>
```

**src/main/resources/avaje-logger.properties:**
```properties
logger.defaultLogLevel=warn
logger.format=json
logger.component=my-native-app
logger.environment=production
log.level.com.mycompany=info
```

**Build command:**
```bash
mvn clean package -Pnative
```

**Runtime:**
```bash
./target/my-app
```

The logger is fully functional in the native binary, with all configuration from the properties file applied at build time.

---

## Summary

You now have avaje-simple-logger configured in your Maven project!

### What You've Done

- ✅ Added avaje-simple-logger dependency
- ✅ Configured production logging with `avaje-logger.properties`
- ✅ Configured test logging with `avaje-logger-test.properties`
- ✅ Optionally replaced an existing logging framework

### Next Steps

1. **Customize configuration** - Adjust log levels and format for your needs
2. **Start using logging** - Begin logging in your code with SLF4J: `LoggerFactory.getLogger(MyClass.class)`
3. **Monitor logs** - For JSON format, use a log aggregation service (ELK, Splunk, etc.)
4. **Enable dynamic configuration** - If needed for K8s/Lambda, set up avaje-config

### Additional Resources

- Project README: https://github.com/avaje/avaje-simple-logger
- SLF4J Documentation: https://www.slf4j.org/
- avaje-config: https://avaje.io/config/
- GraalVM Native Image: https://www.graalvm.org/latest/reference-manual/native-image/
