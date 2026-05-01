# Avaje Bundle — AWS AppConfig (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `simple-logger/add-aws-appconfig-to-project.md`

# Guide: Add AWS AppConfig to Your Project

This guide provides step-by-step instructions for integrating AWS AppConfig into your application for dynamic configuration management, particularly for dynamically changing log levels in avaje-simple-logger.

## What is AWS AppConfig?

[AWS AppConfig](https://docs.aws.amazon.com/appconfig/latest/userguide/what-is-appconfig.html) is an AWS service that enables you to:

- Store and manage application configuration separately from code
- Deploy configuration changes without redeploying applications
- Validate configuration syntax before deployment
- Monitor configuration changes and rollback if needed
- Use the same configuration across multiple environments

When integrated with avaje-simple-logger, you can change log levels dynamically without restarting your application.

## Prerequisites

Before starting, verify the following:

- [ ] AWS account with AppConfig access
- [ ] Application is already using avaje-simple-logger (or following [Add avaje-simple-logger to Maven Project guide](./add-avaje-simple-logger-to-maven-project.md))
- [ ] Application uses avaje-config (for configuration management)
- [ ] AWS AppConfig agent is available in your deployment environment (EC2, ECS, Lambda, on-premises)
- [ ] Java 11 or later
- [ ] IAM permissions to read from AWS AppConfig

### Permission Requirements

Your application needs IAM permissions for:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "appconfig:GetConfiguration",
        "appconfig:StartConfigurationSession"
      ],
      "Resource": "arn:aws:appconfig:*:*:application/*"
    }
  ]
}
```

## How It Works

When AppConfig is enabled:

1. Application starts and initializes avaje-config
2. avaje-aws-appconfig plugin loads initial configuration from AppConfig
3. Configuration is merged with local properties files
4. Plugin polls AppConfig at regular intervals (default 45 seconds)
5. When changes are detected, configuration is updated in-memory
6. Log levels (and other settings) take effect immediately
7. No application restart required

## Step 1: Add Dependencies

Add avaje-aws-appconfig to your `pom.xml`:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-aws-appconfig</artifactId>
  <version>2.8</version>
</dependency>
```

**Important:** This dependency includes avaje-config, which is required for dynamic configuration.

### Optional: Use Both Static and Dynamic Configuration

If you want both avaje-simple-logger AND dynamic configuration support:

```xml
<!-- Dynamic logging with AppConfig -->
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-simple-logger</artifactId>
  <version>1.5-RC1</version>
</dependency>

<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-aws-appconfig</artifactId>
  <version>2.8</version>
</dependency>
```

## Step 2: Create AWS AppConfig Configuration

### Step 2.1: Create Application in AWS AppConfig

1. Go to [AWS AppConfig Console](https://console.aws.amazon.com/appconfig/)
2. Click **Create Application**
3. Enter Application name (e.g., `my-application`)
4. Click **Create Application**

### Step 2.2: Create Environment

1. In your application, click **Create Environment**
2. Enter Environment name (e.g., `dev`, `staging`, `prod`)
3. Click **Create Environment**

### Step 2.3: Create Configuration Profile

1. In your environment, click **Create Configuration Profile**
2. Enter Configuration Profile name (e.g., `default`)
3. Select **Content type**: Choose `application/x-properties` for properties format or `application/x-yaml` for YAML format
4. Click **Create Configuration Profile**

### Step 2.4: Create Configuration Content

Now create the actual configuration content.

#### Option A: Properties Format

Click **Create Configuration** and enter:

```properties
logger.defaultLogLevel=warn
logger.format=json
log.level.com.mycompany=debug
log.level.io.avaje=info
```

#### Option B: YAML Format

Click **Create Configuration** and enter:

```yaml
logger:
  defaultLogLevel: warn
  format: json
log:
  level:
    com.mycompany: debug
    io.avaje: info
```

### Step 2.5: Enable Configuration

1. Click **Save configuration** and review the content
2. Click **Start Deployment**
3. Select or create a **Deployment Strategy** (Immediate for quick testing, All at once or Linear for gradual rollout)
4. Click **Deploy**

## Step 3: Configure Your Application

### Step 3.1: Enable AppConfig in Your Application

Create `src/main/application.yaml` (or update if exists):

```yaml
aws:
  appconfig:
    enabled: true
    application: my-application  # Must match AWS AppConfig application name
    environment: ${ENVIRONMENT:dev}  # Environment variable, defaults to 'dev'
    configuration: default  # Configuration profile name
    pollingEnabled: true
    pollingSeconds: 45  # Check for changes every 45 seconds
```

### Step 3.2: Create avaje-logger.properties

Create `src/main/resources/avaje-logger.properties`:

```properties
logger.defaultLogLevel=warn
logger.format=json
logger.component=my-service
logger.environment=production
log.level.com.mycompany=info
log.level.io.avaje=warn
```

These are the local defaults. AWS AppConfig will override these if different values are configured there.

### Step 3.3: Disable AppConfig for Tests

Create `src/test/application-test.yaml`:

```yaml
aws:
  appconfig:
    enabled: false
```

This prevents tests from making network calls to AWS AppConfig.

### Step 3.4: Disable AppConfig for Local Development (Optional)

For local development without AWS credentials, create `src/main/resources/application-local.yaml`:

```yaml
aws:
  appconfig:
    enabled: false
```

Then run your application with: `java -Dspring.profiles.active=local -jar myapp.jar`

## Configuration Reference

### AWS AppConfig Settings

| Property | Type | Default | Description |
|---|---|---|---|
| `aws.appconfig.enabled` | boolean | `true` | Enable/disable AppConfig plugin |
| `aws.appconfig.application` | string | (required) | AWS AppConfig application name |
| `aws.appconfig.environment` | string | (required) | AWS AppConfig environment name |
| `aws.appconfig.configuration` | string | `default` | Configuration profile name |
| `aws.appconfig.pollingEnabled` | boolean | `true` | Enable polling for changes |
| `aws.appconfig.pollingSeconds` | integer | `45` | Poll interval in seconds |
| `aws.appconfig.refreshSeconds` | integer | `pollingSeconds - 1` | Max time to wait for changes |

### Log Level Configuration

In your AppConfig configuration, you can set:

```properties
# Set default log level for entire application
logger.defaultLogLevel=warn

# Set specific package log levels
log.level.com.mycompany=debug
log.level.com.mycompany.database=trace
log.level.io.avaje=info

# Set log format (json or plain)
logger.format=json
```

## Step 4: Handle Application Startup

### When AppConfig is Unavailable

If the AppConfig agent is not available or configuration cannot be loaded:

1. Application uses local `avaje-logger.properties` values
2. Logs a warning about AppConfig unavailability
3. Continues to function normally with local configuration
4. Will periodically retry connecting to AppConfig

### During Local Development

If you want to develop without AWS access:

1. Disable AppConfig in `application-local.yaml`
2. Use local `avaje-logger.properties` for configuration
3. Any changes require application restart (normal behavior)

## Step 5: Deploy Your Application

### For Traditional Applications

Build your application:

```bash
mvn clean package
```

When running, ensure environment variables are set:

```bash
export ENVIRONMENT=prod
export AWS_REGION=us-east-1
java -jar myapp.jar
```

### For AWS Lambda

AWS Lambda has the AppConfig agent built-in. Simply:

1. Set environment variables in Lambda configuration:
   - `ENVIRONMENT=prod`
   - `AWS_REGION=us-east-1`
2. Grant IAM permissions (see Prerequisites section)
3. Deploy your application

### For Amazon ECS

1. Ensure ECS task role has AppConfig permissions
2. Set environment variables in task definition:
   ```json
   {
     "name": "ENVIRONMENT",
     "value": "prod"
   }
   ```
3. Deploy task

### For Amazon EC2

1. Install AWS AppConfig agent on EC2 instance
2. Start the agent: `sudo systemctl start aws-appconfig-agent`
3. Set environment variables:
   ```bash
   export ENVIRONMENT=prod
   export AWS_REGION=us-east-1
   ```
4. Run your application

## Step 6: Monitor and Update Configuration

### Changing Log Levels at Runtime

To change log levels without restarting:

1. Go to AWS AppConfig Console
2. Navigate to your Application → Environment → Configuration Profile
3. Click **Update configuration**
4. Change the log levels (e.g., `log.level.com.mycompany=trace`)
5. Click **Save** and **Deploy**
6. Within the polling interval (default 45 seconds), your application will update

### Rollback Configuration

1. Go to AWS AppConfig Console
2. Click **View deployments**
3. Select the deployment to rollback
4. Click **Rollback**
5. Confirm the rollback

### Monitor Configuration Changes

Add logging to see when configuration changes are applied:

```java
import io.avaje.config.Config;
import io.avaje.config.Configuration;

// Listen for configuration changes
Configuration.onChange((Map<String, String> changes) -> {
  for (var entry : changes.entrySet()) {
    if (entry.getKey().startsWith("log.level.") || 
        entry.getKey().startsWith("logger.")) {
      System.err.println("Log config changed: " + entry.getKey() + 
                         " = " + entry.getValue());
    }
  }
});
```

## Troubleshooting

### Issue: "AppConfig plugin failed to initialize"

**Cause:** AWS credentials not available or AppConfig agent not running.

**Solution:**
- Check AWS credentials are configured (IAM role, environment variables, or credentials file)
- Check AppConfig agent is running: `ps aux | grep aws-appconfig-agent`
- Check network connectivity to AppConfig endpoint
- Verify security group allows outbound traffic to AppConfig port (port 2371 by default)

### Issue: No Log Level Changes After Updating Configuration

**Cause:** Application hasn't checked for changes yet.

**Solution:**
- Wait for the polling interval (default 45 seconds)
- Force refresh by calling `Configuration.refresh()` in your application
- Check that `aws.appconfig.pollingEnabled` is `true`
- Verify AppConfig deployment status is "DEPLOYMENT_SUCCESS"

### Issue: "Configuration not found" Error

**Cause:** Application name, environment, or configuration profile name doesn't match AWS AppConfig.

**Solution:**
- Verify exact names match in application.yaml:
  ```yaml
  aws.appconfig:
    application: my-application  # Match exact AWS AppConfig name
    environment: prod             # Match exact environment name
    configuration: default        # Match exact profile name
  ```
- Check AWS AppConfig console for exact names

### Issue: AppConfig Configuration Not Overriding Local Properties

**Cause:** AppConfig not enabled or configuration wasn't deployed.

**Solution:**
- Check `aws.appconfig.enabled` is `true` in application.yaml
- Check deployment status in AWS AppConfig console (should be "DEPLOYMENT_SUCCESS")
- Check log levels are correctly formatted in AppConfig configuration
- Wait for polling interval and check application logs

### Issue: Tests Connecting to AppConfig

**Cause:** AppConfig enabled in test environment.

**Solution:**
- Create `src/test/application-test.yaml` with `aws.appconfig.enabled: false`
- Ensure test profile is active when running tests
- For Maven: `mvn test` automatically uses test profile
- For IDE: Configure test runner to use test profile

### Issue: Development Environment Without AWS Access

**Cause:** Trying to run application locally without AWS credentials.

**Solution:**
- Create `src/main/resources/application-local.yaml`:
  ```yaml
  aws.appconfig:
    enabled: false
  ```
- Run with: `java -Dspring.profiles.active=local -jar myapp.jar` (if using Spring)
- Or set in code: `System.setProperty("spring.profiles.active", "local")`
- Use local `avaje-logger.properties` for configuration

## Complete Example: Spring Boot Application

### pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  
  <groupId>com.mycompany</groupId>
  <artifactId>my-service</artifactId>
  <version>1.0.0</version>
  
  <dependencies>
    <!-- Spring Boot -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
      <version>3.0.0</version>
    </dependency>
    
    <!-- Logging -->
    <dependency>
      <groupId>io.avaje</groupId>
      <artifactId>avaje-simple-logger</artifactId>
      <version>1.5-RC1</version>
    </dependency>
    
    <!-- Dynamic Configuration via AppConfig -->
    <dependency>
      <groupId>io.avaje</groupId>
      <artifactId>avaje-aws-appconfig</artifactId>
      <version>2.8</version>
    </dependency>
    
    <!-- Testing -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <version>3.0.0</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
</project>
```

### src/main/resources/application.yaml

```yaml
spring:
  application:
    name: my-service

aws:
  appconfig:
    enabled: true
    application: my-service-app
    environment: ${ENVIRONMENT:dev}
    configuration: default
    pollingEnabled: true
    pollingSeconds: 45
```

### src/main/resources/avaje-logger.properties

```properties
logger.defaultLogLevel=warn
logger.format=json
logger.component=my-service
logger.environment=${ENVIRONMENT:dev}
log.level.com.mycompany=info
log.level.com.mycompany.database=debug
log.level.io.avaje=warn
log.level.org.springframework=info
```

### src/test/resources/application-test.yaml

```yaml
aws:
  appconfig:
    enabled: false
```

### src/test/resources/avaje-logger-test.properties

```properties
logger.defaultLogLevel=info
logger.format=plain
log.level.com.mycompany=debug
log.level.io.avaje=debug
```

### Application Code

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import io.avaje.config.Configuration;

@SpringBootApplication
public class MyServiceApplication {
  
  private static final Logger log = LoggerFactory.getLogger(MyServiceApplication.class);
  
  public static void main(String[] args) {
    // Listen for configuration changes
    Configuration.onChange(changes -> {
      for (var entry : changes.entrySet()) {
        if (entry.getKey().startsWith("log.level.") || 
            entry.getKey().startsWith("logger.")) {
          System.err.println("Logging config changed: " + entry.getKey() + 
                           " = " + entry.getValue());
        }
      }
    });
    
    SpringApplication.run(MyServiceApplication.class, args);
    log.info("My Service started successfully");
  }
}
```

## Complete Example: AWS Lambda

### pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  
  <groupId>com.mycompany</groupId>
  <artifactId>my-lambda</artifactId>
  <version>1.0.0</version>
  
  <dependencies>
    <!-- AWS Lambda -->
    <dependency>
      <groupId>com.amazonaws</groupId>
      <artifactId>aws-lambda-java-core</artifactId>
      <version>1.2.2</version>
    </dependency>
    
    <!-- Logging -->
    <dependency>
      <groupId>io.avaje</groupId>
      <artifactId>avaje-simple-logger</artifactId>
      <version>1.5-RC1</version>
    </dependency>
    
    <!-- Dynamic Configuration via AppConfig -->
    <dependency>
      <groupId>io.avaje</groupId>
      <artifactId>avaje-aws-appconfig</artifactId>
      <version>2.8</version>
    </dependency>
  </dependencies>
  
  <build>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.4.1</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```

### src/main/resources/application.yaml

```yaml
aws:
  appconfig:
    enabled: true
    application: my-lambda-app
    environment: ${ENVIRONMENT:dev}
    configuration: default
    pollingEnabled: true
    pollingSeconds: 60
```

### src/main/resources/avaje-logger.properties

```properties
logger.defaultLogLevel=warn
logger.format=json
logger.component=my-lambda
log.level.com.mycompany=info
log.level.com.mycompany.handlers=debug
```

### Lambda Handler Code

```java
import com.amazonaws.lambda.core.Context;
import com.amazonaws.lambda.core.RequestHandler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import io.avaje.config.Configuration;

public class MyLambdaHandler implements RequestHandler<String, String> {
  
  private static final Logger log = LoggerFactory.getLogger(MyLambdaHandler.class);
  
  static {
    // Listen for configuration changes
    Configuration.onChange(changes -> {
      for (var entry : changes.entrySet()) {
        if (entry.getKey().startsWith("log.level.") || 
            entry.getKey().startsWith("logger.")) {
          System.err.println("Logging config changed: " + entry.getKey() + 
                           " = " + entry.getValue());
        }
      }
    });
  }
  
  @Override
  public String handleRequest(String input, Context context) {
    log.info("Lambda invoked with input: {}", input);
    return "Success";
  }
}
```

### AWS Lambda Configuration

1. Create Lambda function with Java runtime
2. Upload JAR file (produced by `mvn clean package`)
3. Set handler: `com.mycompany.MyLambdaHandler::handleRequest`
4. Add environment variables:
   - `ENVIRONMENT=prod`
   - `AWS_REGION=us-east-1`
5. Attach IAM role with AppConfig permissions
6. Set timeout to at least 30 seconds (for initial AppConfig load)

## Advanced: Programmatic Configuration Access

Access configuration values in your code:

```java
import io.avaje.config.Config;

// Get string value
String level = Config.get("log.level.com.mycompany", "info");

// Get integer value
int pollingSeconds = Config.getInt("aws.appconfig.pollingSeconds", 45);

// Get boolean value
boolean enabled = Config.getBool("aws.appconfig.enabled", true);

// Listen for changes
Config.onChange(changes -> {
  if (changes.containsKey("log.level.com.mycompany")) {
    String newLevel = changes.get("log.level.com.mycompany");
    System.out.println("Log level changed to: " + newLevel);
  }
});
```

## Summary

You now have AWS AppConfig integrated into your application for dynamic configuration!

### What You've Done

- ✅ Created AWS AppConfig application and environment
- ✅ Created configuration profile with logging settings
- ✅ Added avaje-aws-appconfig dependency
- ✅ Configured application.yaml with AppConfig settings
- ✅ Set up local properties as fallback
- ✅ Disabled AppConfig for tests
- ✅ Deployed application with AppConfig support

### Key Benefits

- 🚀 Change log levels without restarting your application
- 🔄 Gradual configuration rollout with deployment strategies
- ↩️ Rollback configuration if problems occur
- 🛡️ AWS AppConfig validates syntax before deployment
- 📊 Monitor configuration changes in real-time
- 🔒 Centralized configuration management across multiple services

### Next Steps

1. **Customize polling interval** - Adjust `pollingSeconds` based on your needs
2. **Test configuration changes** - Update AppConfig configuration and verify application responds
3. **Set up monitoring** - Log configuration changes to track when they occur
4. **Add more settings** - Use AppConfig for other application settings beyond logging
5. **Implement gradual rollout** - Use AppConfig deployment strategies for safer changes

### Troubleshooting Resources

- [AWS AppConfig Documentation](https://docs.aws.amazon.com/appconfig/)
- [avaje-config Documentation](https://avaje.io/config/)
- [avaje-aws-appconfig GitHub](https://github.com/avaje/avaje-config)
- [avaje-simple-logger GitHub](https://github.com/avaje/avaje-simple-logger)
