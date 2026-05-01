# Avaje Bundle — Testing (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `inject/testing.md`

# Testing with Avaje Inject

How to test beans and dependency injection with unit and component/integration tests.

## Unit Testing

Unit tests manually construct beans and use mocks for dependencies. This is fast, isolated,
and does not use the DI container.

**Example:**
```java
@Test
void testService() {
  UserRepository mockRepo = mock(UserRepository.class);
  UserService service = new UserService(mockRepo);
  when(mockRepo.findById(1)).thenReturn(new User(1, "John"));
  User user = service.findById(1);
  assertEquals("John", user.name);
}
```
**Best practices:**
- Use for pure logic, no DI needed.
- Mock only direct dependencies.

## Component/Integration Testing with @InjectTest

Component tests use the DI container to wire real beans. This is similar to Spring’s `@SpringBootTest`.

**Example:**
```java
@InjectTest
class UserServiceTest {
  @Inject UserService userService;

  @Test
  void findsUser() {
    User user = userService.findById(1);
    assertNotNull(user);
  }
}
```
**Best practices:**
- Use for service/business logic.
- Avoid mocking unless necessary for external systems.

## Providing Test Doubles (Mocks)

We can initialize `@Inject` fields with mocks to override real beans. This lets us control specific dependencies
and give them test specific behavior while using the real DI graph.

**Example:**
```java
@InjectTest
class ServiceWithMockTest {
  @Inject UserRepository userRepository = mock(UserRepository.class);
  @Inject UserService userService;

  @Test
  void testServiceWithMock() {
    when(userRepository.findById(1)).thenReturn(new User(1, "Jane"));
    User user = userService.findById(1);
    assertEquals("Jane", user.name);
  }
}
```

The DI container will use the initialized mock instead of creating a real `UserRepository` bean. This allows you to:
- Control external dependencies without manually constructing the service
- Leverage the full dependency graph while mocking specific beans
- Use mocks to invoke error conditions and simulate specific edge cases

## Using Mockito Annotations

Use `@Mock`/`@Spy` for cleaner setup. Mocks/spies are auto-wired into the test DI container.

**Example:**
```java
@InjectTest
class ServiceWithMockitoTest {
  @Mock UserRepository userRepository;
  @Spy Logger logger;
  @Inject UserService userService;

  @Test
  void testWithMockito() {
    when(userRepository.findById(1)).thenReturn(new User(1, "Alex"));
    User user = userService.findById(1);
    assertEquals("Alex", user.name);
    verify(userRepository).findById(1);
  }
}
```
**Annotations explained:**
- `@Mock` — Creates a complete mock that returns default values (null, empty collections, etc.)
- `@Spy` — Wraps a real object and allows selective method mocking while preserving real behavior

**Best practices:**
- Use `@Mock` for pure mocks, `@Spy` to partially mock real objects.

## Troubleshooting & Tips

- If a bean isn’t injected, check for missing `@Inject` or `@InjectTest`.
- Use try-with-resources for manual `TestScope` (advanced).

## More Examples

- See [inject-test module](../../inject-test/src/test/java/) for real-world tests.
- For advanced scenarios (e.g., Postgres/Ebean, LocalStack), see dedicated guides: `testing-postgres-ebean.md`, `testing-localstack.md` (coming soon).

---

For more, see the [full library reference](../LIBRARY.md) and [avaje.io/inject](https://avaje.io/inject/).

---

## Source: `inject/testing-postgres-ebean.md`

# Testing with Postgres, Ebean, and Avaje Inject

This guide shows how to set up robust component/integration tests using Avaje Inject, Ebean ORM, and a real Postgres database (via Testcontainers). It covers using TestEntityBuilder for test data, and handling multiple named databases.

---

## 1. Test Configuration Example

Define a test configuration with `@TestScope` and `@Factory` to provide beans for Postgres, Ebean Database, and TestEntityBuilder.

```java
@TestScope
@Factory
class TestConfiguration {

  @Bean
  PostgresContainer container() {
    return PostgresContainer.builder("17")
      .dbName("testdb")
      .containerName("ut_test_postgres")
      .port(5557)
      .build()
      .start();
  }

  @Bean
  Database database(PostgresContainer container) {
    return container.ebean().builder()
      .name("primary")
      .ddlRun(true)
      .build();
  }

  @Bean
  TestEntityBuilder testEntityBuilder(Database database) {
    return TestEntityBuilder.builder(database).build();
  }
}
```

- The PostgresContainer is started automatically for tests.
- The Database bean is configured for Ebean and wired into your tests.
- TestEntityBuilder helps create and persist test entities populated with random data.

---

## 2. Using TestEntityBuilder

TestEntityBuilder makes it easy to create and persist test data with random values, reducing boilerplate.

**Example:**
```java
@InjectTest
class UserServiceTest {

  @Inject Database database;
  @Inject TestEntityBuilder builder;

  @Test
  void testFindUser() {
    // Persist a random user
    User user = builder.save(User.class);
    // Or: build, customize, then save
    // User user = builder.build(User.class).setActive(true);
    // database.save(user);

    User found = database.find(User.class, user.getId());
    assertEquals(user.getName(), found.getName());
  }
}
```

- See the [Ebean TestEntityBuilder guide](https://github.com/ebean-orm/ebean/blob/HEAD/docs/guides/testing-with-testentitybuilder.md) for advanced usage.

---

## 3. Multiple Named Databases

To test with multiple databases (e.g., @MainDb, @ReportingDb, @ArchiveDb), define multiple beans with custom qualifiers:

```java
@TestScope
@Factory
class MultiDbTestFactory {

  @MainDb
  @Bean
  Database mainDb(PostgresContainer container) {
    return container.ebean().builder().build();
  }

  @ExtraDb
  @Bean
  Database extraDb(PostgresContainer container) {
    return container.ebean().extraDatabaseBuilder()
      .name("extra")
      .initSqlFile("init-extra-database.sql")
      .seedSqlFile("seed-extra-database.sql")
      .build();
  }
}
```

- Use custom qualifiers (e.g., `@MainDb`, `@ReportingDb`) to inject the correct Database in your tests.

---

## 4. Example Test with Multiple Databases

```java
@InjectTest
class MultiDbTest {

  @Inject @MainDb Database mainDb;
  @Inject @ReportingDb Database reportingDb;
  @Inject TestEntityBuilder builder;

  @Test
  void testAcrossDatabases() {
    // Use builder with a specific database if needed
    User user = builder.save(User.class); // uses default injected db
    assertNotNull(mainDb.find(User.class, user.getId()));
    // ... test logic for reportingDb as well
  }
}
```

---

## 5. Best Practices & Troubleshooting

- Always use `@TestScope` and `@Factory` for test bean setup.
- Clean up test data if needed (TestEntityBuilder can help).
- Use unique database/container names to avoid conflicts in parallel test runs.
- For advanced container config, see [Testcontainers](https://www.testcontainers.org/) docs.
- If a bean isn’t injected, check for missing qualifiers or bean definitions.

---

For more, see:
- [Ebean TestEntityBuilder guide](https://github.com/ebean-orm/ebean/blob/HEAD/docs/guides/testing-with-testentitybuilder.md)
- [inject-test module](../../inject-test/src/test/java/)
- [avaje.io/inject](https://avaje.io/inject/)

---

## Source: `inject/testing-localstack.md`

# Testing with LocalStack and Avaje Inject

This guide shows how to set up integration/component tests using Avaje Inject and LocalStack, with AWS SDK v2 clients (e.g., SqsClient). LocalStack provides a local AWS cloud stack for testing SQS, S3, DynamoDB, and more.

---

## 1. Test Configuration Example

Define a test configuration with `@TestScope` and `@Factory` to provide beans for LocalStack and SqsClient.

```java
@TestScope
@Factory
class TestConfig {

  @Bean
  LocalstackContainer localstack() {
    return LocalstackContainer.builder("4.3.0")
      // .mirror("<your-mirror-repo>") // optional: use a local/ECR mirror
      .awsRegion("ap-southeast-2")
      .services("sqs") // comma-separated list, e.g. "sqs,s3,dynamodb"
      .containerName("ut_localstack")
      .port(4567)
      .start();
  }

  @Bean
  SqsClient sqsClient(LocalstackContainer localstack) {
    return localstack.sdk2().sqsClient();
  }
}
```

- The LocalStack container is started automatically for tests.
- The SqsClient is configured to connect to the local SQS endpoint.
- Add more AWS services as needed via `.services()`.

---

## 2. Example Test Using SqsClient

```java
@InjectTest
class SqsServiceTest {

  @Inject SqsClient sqsClient;

  @Test
  void testSendAndReceive() {
    // Create a queue, send a message, receive it, etc.
    String queueUrl = sqsClient.createQueue(r -> r.queueName("test-queue")).queueUrl();
    sqsClient.sendMessage(r -> r.queueUrl(queueUrl).messageBody("hello world"));
    var messages = sqsClient.receiveMessage(r -> r.queueUrl(queueUrl)).messages();
    assertFalse(messages.isEmpty());
    assertEquals("hello world", messages.get(0).body());
  }
}
```

---

## 3. Best Practices & Troubleshooting

- Use `@TestScope` and `@Factory` for test bean setup.
- Use `.services()` to limit LocalStack startup to only the AWS services you need.
- Clean up resources (queues, buckets, etc.) after tests if needed.
- For advanced config, see [LocalStack docs](https://docs.localstack.cloud/) and [Testcontainers LocalStack module](https://www.testcontainers.org/modules/localstack/).
- If a bean isn’t injected, check for missing bean definitions or incorrect service names.

---

For more, see:
- [inject-test module](../../inject-test/src/test/java/)
- [avaje.io/inject](https://avaje.io/inject/)
- [LocalStack](https://localstack.cloud/)

---

## Source: `inject/testing-avaje-inject-vs-spring.md`

# Avaje Inject vs Spring DI: Testing Setup Comparison

This guide is for developers familiar with Spring DI and testing. It shows how common Spring test patterns map to Avaje Inject, with code examples and notes on differences.

---

## 1. Basic Component Test: Side-by-Side

| Avaje Inject                | Spring Boot Test                |
|-----------------------------|---------------------------------|
| `@InjectTest`               | `@SpringBootTest`               |
| `@Inject`                   | `@Autowired`                    |
| `@Factory`/`@Bean` (test beans) | `@TestConfiguration`/`@Bean`  |
| Test beans are isolated     | Test beans may need `@Primary`  |
| No profiles needed          | Often uses `@ActiveProfiles`    |

**Avaje Inject Example:**
```java
@InjectTest
class MyServiceTest {
  @Inject MyService myService;
  @Test void testLogic() { /* ... */ }
}
```

**Spring Example:**
```java
@SpringBootTest
class MyServiceTest {
  @Autowired MyService myService;
  @Test void testLogic() { /* ... */ }
}
```

---

## 2. Test-Specific Beans

**Avaje Inject:**
```java
@TestScope
@Factory
class TestConfig {
  @Bean
  MyService myService() { return new MyService(...); }
}
```

**Spring:**
```java
@TestConfiguration
class SpringTestConfig {
  @Bean
  @Primary // needed if "main" bean also wired during test (not conditionally wired)
  MyService myService() { return new MyService(...); }
}
```

---

## 3. Profiles and Conditional Wiring

**Spring:**
- Use `@ConditionalOnMissingBean`, `@ConditionalOnProperty`, etc. for conditional wiring of "main" components to exclude those when testing.
- Alternatively use `@ActiveProfiles("test")` in test setup and `@Profile("!test")` on wiring of "main" components to exclude those when testing.

```java
@Profile("!test")
@Bean
DataSource prodDataSource() { ... }

@Profile("test")
@Bean
DataSource testDataSource() { ... }
```

**Avaje Inject:**
- Test beans wired via `@TestScope` automatically when the matching beans are not wired, so no need for profiles or conditional wiring.
- The test DI context is isolated from production beans (via layering of BeanScopes).

---

## 4. Summary Table: Key Differences

| Pattern/Need                | Spring DI                      | Avaje Inject                 |
|-----------------------------|-------------------------------|------------------------------|
| Test context annotation     | `@SpringBootTest`              | `@InjectTest`                |
| Inject beans                | `@Autowired`                   | `@Inject`                    |
| Test-only beans             | `@TestConfiguration` + `@Bean` | `@TestScope` + `@Factory`    |
| Override prod beans         | `@Primary` or `@Profile`       | Test beans override by scope |
| Conditional wiring          | `@Profile`, `@Conditional*`    | Not needed for tests         |
| Activate test config        | `@ActiveProfiles("test")`      | Not needed for tests         |

---

## 5. Notes for Spring Users
- Avaje Inject test beans in `@TestScope` automatically override production beans without needing `@Primary` or profiles.
- Avaje Inject test beans in `@TestScope` also have a global scope that is layered on top of the main BeanScope context, so they are isolated from production beans and won't accidentally interfere with them.
- No need for `@Primary`, `@Profile`, or `@ActiveProfiles` to control test wiring.
- No conditional wiring is needed for test beans—just define them in a `@TestScope @Factory`.
- Avaje Inject test context startup is typically fast using layering of BeanScopes so having *LOTS* of component testing is encouraged.

For more, see the [inject-test module](../../inject-test/src/test/java/) and [avaje.io/inject](https://avaje.io/inject/).

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
