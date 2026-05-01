# Avaje Bundle — Testing (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `nima/testing.md`

# Testing Nima Applications

How to write tests for nima web applications.

## Setting Up Tests

Add test dependencies:

```xml
<dependency>
  <groupId>org.junit.jupiter</groupId>
  <artifactId>junit-jupiter</artifactId>
  <version>5.9.0</version>
  <scope>test</scope>
</dependency>

<dependency>
  <groupId>io.avaje.test</groupId>
  <artifactId>avaje-http-test</artifactId>
  <version>2.1</version>
  <scope>test</scope>
</dependency>
```

## Basic HTTP Tests

Test controllers using the test client:

```java
import io.avaje.http.test.HttpTest;
import io.avaje.http.test.Client;

@HttpTest
public class UserControllerTest {
  
  Client httpClient;
  
  @Test
  public void testGetUser() {
    httpClient.request()
      .get("/users/1")
      .expect()
      .status(200)
      .contains("\"id\":1");
  }
  
  @Test
  public void testCreateUser() {
    httpClient.request()
      .post("/users")
      .body(new { name = "John", email = "john@example.com" })
      .expect()
      .status(201);
  }
  
  @Test
  public void testUserNotFound() {
    httpClient.request()
      .get("/users/999")
      .expect()
      .status(404);
  }
}
```

## Asserting Responses

Verify response content:

```java
@Test
public void testJsonResponse() {
  httpClient.request()
    .get("/api/users/1")
    .expect()
    .status(200)
    .contains("\"name\":\"John\"")
    .contains("\"email\":\"john@example.com\"");
}

@Test
public void testResponseHeaders() {
  httpClient.request()
    .get("/api/data")
    .expect()
    .status(200)
    .header("Content-Type", "application/json")
    .header("X-Custom-Header", "value");
}
```

## Request Building

Build complex requests:

```java
@Test
public void testWithHeaders() {
  httpClient.request()
    .get("/protected")
    .header("Authorization", "Bearer token123")
    .header("Accept", "application/json")
    .expect()
    .status(200);
}

@Test
public void testWithQueryParams() {
  httpClient.request()
    .get("/search?query=java&page=1&per_page=10")
    .expect()
    .status(200);
}

@Test
public void testPostWithBody() {
  CreateUserRequest req = new CreateUserRequest("John", "john@example.com");
  
  httpClient.request()
    .post("/users")
    .body(req)
    .expect()
    .status(201);
}
```

## Mocking Dependencies

Mock service dependencies:

```java
@HttpTest
public class UserControllerTest {
  
  @Mock
  private UserService userService;
  
  Client httpClient;
  
  @Test
  public void testGetUser() {
    User user = new User(1, "John", "john@example.com");
    when(userService.findById(1)).thenReturn(user);
    
    httpClient.request()
      .get("/users/1")
      .expect()
      .status(200)
      .contains("\"name\":\"John\"");
  }
  
  @Test
  public void testUserNotFound() {
    when(userService.findById(999))
      .thenThrow(new NotFoundException("User not found"));
    
    httpClient.request()
      .get("/users/999")
      .expect()
      .status(404);
  }
}
```

## Testing Exception Handling

Test error responses:

```java
@Test
public void testValidationError() {
  httpClient.request()
    .post("/users")
    .body(new { name = "" })  // Invalid - blank name
    .expect()
    .status(400)
    .contains("name is required");
}

@Test
public void testInternalError() {
  when(userService.findById(1))
    .thenThrow(new RuntimeException("Database error"));
  
  httpClient.request()
    .get("/users/1")
    .expect()
    .status(500)
    .contains("Internal Server Error");
}
```

## Integration Testing

Test with real dependencies:

```java
@ExtendWith(PostgreSQLExtension.class)
public class UserControllerIntegrationTest {
  
  @Container
  static PostgreSQLContainer db = new PostgreSQLContainer<>()
    .withDatabaseName("test_db")
    .withUsername("test")
    .withPassword("test");
  
  Client httpClient;
  
  @Test
  public void testCreateAndRetrieveUser() {
    // Create user
    httpClient.request()
      .post("/users")
      .body(new { name = "John", email = "john@example.com" })
      .expect()
      .status(201);
    
    // Retrieve user
    httpClient.request()
      .get("/users/1")
      .expect()
      .status(200)
      .contains("\"name\":\"John\"");
  }
}
```

## Test Fixtures

Reuse common setup:

```java
@HttpTest
public class UserControllerTest {
  
  Client httpClient;
  
  @BeforeEach
  public void setUp() {
    // Create test users
    userService.create(new User("user1", "user1@example.com"));
    userService.create(new User("user2", "user2@example.com"));
  }
  
  @Test
  public void testListUsers() {
    httpClient.request()
      .get("/users")
      .expect()
      .status(200)
      .contains("user1")
      .contains("user2");
  }
}
```

## Best Practices

| Practice | Reason |
|----------|--------|
| Test both success and failure paths | Complete coverage |
| Use realistic test data | Better catch real bugs |
| Mock external services | Tests are fast and isolated |
| Test error responses | Users need clear error messages |
| Keep tests focused | Single assertion per test |

## Next Steps

- See [testing configuration](../../../docs/guides/testing.md) for test setup
- Learn about [filters](filters.md)
- See [troubleshooting](troubleshooting.md) for test issues

---

## Source: `nima/add-controller-test.md`

# Guide: Add a Controller Test

## Purpose

This guide provides step-by-step instructions for writing integration tests for an
**avaje-nima** controller using `avaje-nima-test` and `@InjectTest`. Tests run against
a real embedded Helidon server — no mocking framework needed.

When asked to *"add a test"*, *"test this endpoint"*, *"write a test for my
controller"*, or *"add a controller test"* to an avaje-nima project, follow these
steps exactly.

---

## How it works

`avaje-nima-test` (via `@InjectTest`) starts a real Helidon SE server on a random port
and wires the full `BeanScope` before any test in the class runs. The server is stopped
after the last test.

There are two ways to call endpoints from tests:

| | Approach 1: raw `HttpClient` | Approach 2: generated typed API |
|---|---|---|
| Inject | `HttpClient` | `HelloControllerTestAPI` |
| Response type | `HttpResponse<String>` | `HttpResponse<MyDto>` (typed) |
| Path construction | manual string | generated method per endpoint |
| Best for | raw/non-JSON, custom headers | standard CRUD/JSON endpoints |

**Prefer Approach 2** (generated typed API) for standard JSON endpoints; use Approach
1 when you need direct control over headers, raw body inspection, or are testing
non-JSON endpoints.

---

## Prerequisites

The following dependencies must be present in `pom.xml` (included in all
archetype-generated projects — verify before proceeding):

```xml
<!-- Starts an embedded Helidon server and wires beans for tests -->
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-nima-test</artifactId>
  <version>${avaje.nima.version}</version>
  <scope>test</scope>
</dependency>

<!-- JUnit 5 + AssertJ + Mockito (transitive) -->
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>junit</artifactId>
  <version>1.8</version>
  <scope>test</scope>
</dependency>
```

If either dependency is missing, add it inside `<dependencies>`.

---

## Step 1 — Confirm the test dependencies are present

Check `pom.xml` for `avaje-nima-test` (test scope). If missing, add it as shown above.

---

## Step 2 — Create or locate the test class

Test classes live in `src/test/java` and mirror the main source package. If a test
class already exists for the controller, open it. Otherwise create one at:

```
src/test/java/<base-package>/<ControllerName>Test.java
```

The class must carry `@InjectTest`. Declare the injections you need:

```java
package <base-package>;

import static org.assertj.core.api.Assertions.assertThat;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import io.avaje.http.client.HttpClient;
import io.avaje.inject.test.InjectTest;
import jakarta.inject.Inject;
import <controller-package>.HelloControllerTestAPI;

@InjectTest
class HelloControllerTest {

  @Inject HttpClient client;                    // Approach 1 — raw HTTP
  @Inject HelloControllerTestAPI helloApi;      // Approach 2 — typed API
```

- **`@InjectTest`** — JUnit 5 extension that starts the embedded server and builds the
  full `BeanScope` before the first test in the class.
- **`HttpClient`** — pre-configured with `http://localhost:<random-port>` as the base URL.
- **`HelloControllerTestAPI`** — auto-generated by `avaje-nima-generator` during test
  compilation; one interface per `@Controller`, named `<ControllerName>TestAPI`,
  located in the same package as the controller.

---

## Step 3 — Write the test method

### Approach 1 — `HttpClient` (untyped)

```java
@Test
void data_returnsJson() {
  HttpResponse<String> res = client.request()
    .path("hi/data")
    .GET().asString();

  assertThat(res.statusCode()).isEqualTo(200);
  assertThat(res.body()).contains("message");
  assertThat(res.body()).contains("timestamp");
}
```

**Request builder reference:**

| Scenario | Snippet |
|---|---|
| Path (relative to base URL) | `.path("hi/data/Alice")` |
| Query parameter | `.queryParam("q", "foo")` |
| Request header | `.header("Authorization", "Bearer ...")` |
| GET, return as String | `.GET().asString()` |
| POST with JSON body | `.body(myDto).POST().asString()` |
| Assert status | `assertThat(res.statusCode()).isEqualTo(200)` |
| Assert JSON field present | `assertThat(res.body()).contains("fieldName")` |
| Assert exact body | `assertThat(res.body()).isEqualTo("exact text")` |

### Approach 2 — Generated typed API (preferred for JSON)

`avaje-nima-generator` generates a `HelloControllerTestAPI` interface during
`mvn test-compile`. It mirrors the controller method-for-method, with return types
resolved to the actual response DTOs:

```java
// Generated: <controller-package>.HelloControllerTestAPI
@Client("/hi")
public interface HelloControllerTestAPI {
  @Get                   HttpResponse<String>           hi();
  @Get("/data")          HttpResponse<GreetingResponse> data();
  @Get("/data/{name}")   HttpResponse<GreetingResponse> dataByName(String name);
}
```

Using the API in a test:

```java
@Test
void dataByName_returnsTypedResponse() {
  HttpResponse<GreetingResponse> res = helloApi.dataByName("World");

  assertThat(res.statusCode()).isEqualTo(200);
  assertThat(res.body().message()).isEqualTo("World");
  assertThat(res.body().timestamp()).isGreaterThan(0);
}
```

Key advantages over Approach 1:
- **Typed responses** — no JSON string parsing or `.contains()` hacks.
- **Compile-time safety** — method signatures are checked by `javac`.
- **Path parameters are method parameters** — `dataByName("World")` vs.
  `.path("hi/data/World")`.

---

## Step 4 — Avoid controller method name collisions

`avaje-nima-generator` derives the internal route-handler name from the **Java method
name**. Two controller methods in the same class that share a Java name — even with
different parameter lists — produce a naming collision in the generated `$Route` class
and fail to compile.

**What goes wrong:**

```java
// Both generate a private method named _data — compile error.
@Get("/data")        GreetingResponse data()            { ... }
@Get("/data/{name}") GreetingResponse data(String name) { ... }
```

**The fix:** give each overload a **unique Java method name**. The HTTP path (set by
`@Get`) is independent:

```java
@Get("/data")        GreetingResponse data()                   { ... }  // -> _data
@Get("/data/{name}") GreetingResponse dataByName(String name)  { ... }  // -> _dataByName
```

---

## Step 5 — Verify

```bash
mvn test
```

Expected output:

```
Tests run: N, Failures: 0, Errors: 0, Skipped: 0
```

---

## Notes

- `@InjectTest` starts an embedded server on a **random port** — never hard-code a
  port number in tests.
- `HttpClient` and `HelloControllerTestAPI` can be injected as `static` if desired for
  class-level lifecycle (one server instance shared across all `@Test` methods).
- The `TestAPI` interface is generated into `target/generated-test-sources` during
  `mvn test-compile`. It will not exist on a clean checkout until at least one
  compilation has run.
- The `HttpResponse` type used by avaje HttpClient is JDK `java.net.http.HttpResponse`.
- `avaje-nima-test` and the `junit` wrapper pull in JUnit 5 and AssertJ transitively —
  no additional test libraries are required.

---

## Version compatibility

| Component | Tested version |
|---|---|
| `avaje-nima-test` | 1.8 |
| `avaje-inject-test` | (transitive via avaje-nima-test) |
| JUnit 5 | (transitive via `io.avaje:junit`) |
| AssertJ | (transitive via `io.avaje:junit`) |
| Java | 25 |
| Helidon SE | 4.4.0 |

---

## References

- avaje-http client docs: https://avaje.io/http-client/
- avaje-inject test docs: https://avaje.io/inject/#testing

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

## Source: `jsonb/testing.md`

# Testing JSON Serialization

How to test JSON with avaje-jsonb.

## Serialization Tests

Test JSON output:

```java
import io.avaje.jsonb.JsonType;
import io.avaje.jsonb.Jsonb;

@Test
public void testUserSerialization() {
  Jsonb jsonb = Jsonb.instance();
  JsonType<User> userType = jsonb.type(User.class);

  User user = new User(1, "John", "john@example.com");
  String json = userType.toJson(user);
  
  assertEquals("{\"id\":1,\"name\":\"John\",\"email\":\"john@example.com\"}", json);
}
```

## Deserialization Tests

Test JSON parsing:

```java
import io.avaje.jsonb.JsonType;
import io.avaje.jsonb.Jsonb;

@Test
public void testUserDeserialization() {
  Jsonb jsonb = Jsonb.instance();
  JsonType<User> userType = jsonb.type(User.class);

  String json = "{\"id\":1,\"name\":\"John\",\"email\":\"john@example.com\"}";
  User user = userType.fromJson(json);
  
  assertEquals(1, user.id);
  assertEquals("John", user.name);
  assertEquals("john@example.com", user.email);
}
```

## Round-Trip Tests

Ensure data is preserved:

```java
import io.avaje.jsonb.JsonType;
import io.avaje.jsonb.Jsonb;

@Test
public void testRoundTrip() {
  Jsonb jsonb = Jsonb.instance();
  JsonType<User> userType = jsonb.type(User.class);

  User original = new User(1, "John", "john@example.com");
  String json = userType.toJson(original);
  User restored = userType.fromJson(json);
  
  assertEquals(original.id, restored.id);
  assertEquals(original.name, restored.name);
}
```
