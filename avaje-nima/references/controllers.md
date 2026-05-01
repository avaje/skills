# Avaje Bundle — Controllers (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `nima/controller-basics.md`

# Creating Your First REST Controller

How to create a basic REST controller with avaje-nima.

## Installation

Add the dependency:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-nima</artifactId>
  <version>2.1</version>
</dependency>
```

## Simple Controller

Create a controller class:

```java
import io.avaje.nima.Controller;
import io.avaje.nima.Get;
import io.avaje.nima.Post;
import io.avaje.nima.Path;

@Controller
@Path("/users")
public class UserController {
  
  @Get
  public String list() {
    return "List of users";
  }
  
  @Get("/:id")
  public String get(long id) {
    return "User " + id;
  }
  
  @Post
  public String create(CreateUserRequest req) {
    return "Created user: " + req.name;
  }
}
```

## Request/Response

Handle JSON automatically:

```java
@Controller
@Path("/api/users")
public class UserApi {
  
  @Get(":id")
  public User getUser(long id) {
    // Automatically serialized to JSON
    return userService.findById(id);
  }
  
  @Post
  public User create(CreateUserRequest req) {
    // Automatically deserialized from JSON
    return userService.create(req.name, req.email);
  }
}

public class User {
  public long id;
  public String name;
  public String email;
  
  // getters/setters or records
}

public class CreateUserRequest {
  public String name;
  public String email;
}
```

Or using Records:

```java
public record User(long id, String name, String email) {}
public record CreateUserRequest(String name, String email) {}
```

## HTTP Methods

All HTTP methods are supported:

```java
@Controller
@Path("/posts/:id")
public class PostController {
  
  @Get
  public Post get(long id) { }
  
  @Post
  public Post create(CreatePostRequest req) { }
  
  @Put
  public Post update(long id, UpdatePostRequest req) { }
  
  @Delete
  public void delete(long id) { }
  
  @Patch
  public Post patch(long id, JsonPatch patch) { }
}
```

## Response Status

Set HTTP status codes:

```java
@Controller
public class ItemController {
  
  @Post
  public Response<Item> create(CreateItemRequest req) {
    Item item = itemService.create(req);
    return Response.of(item).status(201);  // Created
  }
  
  @Delete(":id")
  public void delete(long id) {
    itemService.delete(id);
    return Response.noContent();  // 204 No Content
  }
  
  @Get(":id")
  public Item get(long id) {
    return itemService.findById(id)
      .orElse(Response.notFound());  // 404 Not Found
  }
}
```

## Path Parameters

Extract values from the URL path:

```java
@Controller
@Path("/users/:userId/posts/:postId")
public class PostController {
  
  @Get
  public Post get(long userId, long postId) {
    // Both userId and postId are extracted from path
    return postService.findByUserAndId(userId, postId);
  }
}

// Call: GET /users/123/posts/456
// userId = 123, postId = 456
```

## Query Parameters

Handle query string parameters:

```java
@Controller
@Path("/search")
public class SearchController {
  
  @Get
  public List<Item> search(
    @Query String query,
    @Query int page,
    @Query("per_page") int pageSize
  ) {
    return itemService.search(query, page, pageSize);
  }
}

// Call: GET /search?query=java&page=1&per_page=10
```

## Headers

Access request headers:

```java
@Controller
public class AuthController {
  
  @Get("/protected")
  public String getProtected(
    @Header("Authorization") String auth,
    @Header("X-Custom-Header") String custom
  ) {
    return "Auth: " + auth;
  }
}
```

## Request Body

Handle request body:

```java
@Controller
@Path("/api/items")
public class ItemApi {
  
  @Post
  public Item create(@Body CreateItemRequest req) {
    return itemService.create(req);
  }
  
  @Put(":id")
  public Item update(long id, @Body UpdateItemRequest req) {
    return itemService.update(id, req);
  }
}
```

## Next Steps

- Learn about [exception handling](exception-handling.md)
- Add [request validation](validation.md)
- Use [filters & middleware](filters.md)

---

## Source: `nima/filters.md`

# Request/Response Filters

How to use filters and middleware in nima applications.

## Creating a Filter

Implement the filter interface:

```java
import io.avaje.nima.Filter;
import io.avaje.nima.FilterChain;
import io.avaje.nima.Context;

public class LoggingFilter implements Filter {
  private static final Logger log = LoggerFactory.getLogger(LoggingFilter.class);
  
  @Override
  public void doFilter(Request request, Response response, FilterChain chain) 
    throws Exception {
    
    long startTime = System.currentTimeMillis();
    
    try {
      log.info("Request: {} {}", request.method(), request.path());
      chain.doFilter(request, response);
    } finally {
      long duration = System.currentTimeMillis() - startTime;
      log.info("Response: {} - {} ms", response.status(), duration);
    }
  }
}
```

## Registering Filters

Register filters in your application:

```java
public class Application {
  public static void main(String[] args) {
    Server server = Server.builder()
      .addFilter(new LoggingFilter())
      .addFilter(new AuthenticationFilter())
      .addFilter(new CorsFilter())
      .build()
      .start();
  }
}
```

## Common Filters

### Authentication Filter

```java
public class AuthenticationFilter implements Filter {
  @Override
  public void doFilter(Request request, Response response, FilterChain chain) 
    throws Exception {
    
    String token = request.header("Authorization");
    
    if (token == null || !isValidToken(token)) {
      response.status(401);
      response.text("Unauthorized");
      return;
    }
    
    // Continue to next filter
    chain.doFilter(request, response);
  }
  
  private boolean isValidToken(String token) {
    // Validate JWT or session token
    return true;
  }
}
```

### CORS Filter

```java
public class CorsFilter implements Filter {
  @Override
  public void doFilter(Request request, Response response, FilterChain chain) 
    throws Exception {
    
    response.header("Access-Control-Allow-Origin", "*");
    response.header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS");
    response.header("Access-Control-Allow-Headers", "Content-Type,Authorization");
    
    if ("OPTIONS".equals(request.method())) {
      response.status(200);
      return;
    }
    
    chain.doFilter(request, response);
  }
}
```

### Request/Response Logging Filter

```java
public class DetailedLoggingFilter implements Filter {
  private static final Logger log = 
    LoggerFactory.getLogger(DetailedLoggingFilter.class);
  
  @Override
  public void doFilter(Request request, Response response, FilterChain chain) 
    throws Exception {
    
    log.debug("Request Headers: {}", request.headerMap());
    log.debug("Request Body: {}", request.body());
    
    chain.doFilter(request, response);
    
    log.debug("Response Status: {}", response.status());
    log.debug("Response Headers: {}", response.headerMap());
  }
}
```

### Exception Handling Filter

```java
public class ExceptionHandlingFilter implements Filter {
  private static final Logger log = 
    LoggerFactory.getLogger(ExceptionHandlingFilter.class);
  
  @Override
  public void doFilter(Request request, Response response, FilterChain chain) 
    throws Exception {
    
    try {
      chain.doFilter(request, response);
    } catch (ValidationException e) {
      log.warn("Validation error: {}", e.getMessage());
      response.status(400);
      response.json(new { message = e.getMessage() });
    } catch (NotFoundException e) {
      log.warn("Not found: {}", e.getMessage());
      response.status(404);
      response.json(new { message = e.getMessage() });
    } catch (Exception e) {
      log.error("Unexpected error", e);
      response.status(500);
      response.json(new { message = "Internal Server Error" });
    }
  }
}
```

## Filter Ordering

Filters execute in registration order:

```java
Server.builder()
  .addFilter(new ExceptionHandlingFilter())     // First
  .addFilter(new AuthenticationFilter())        // Second
  .addFilter(new LoggingFilter())               // Third
  .build()
  .start();
```

Request flows through in order: ExceptionHandling → Authentication → Logging → Controller

## Path-Specific Filters

Apply filters to specific paths:

```java
public class AdminAuthFilter implements Filter {
  @Override
  public void doFilter(Request request, Response response, FilterChain chain) 
    throws Exception {
    
    if (request.path().startsWith("/admin")) {
      if (!isAdmin(request)) {
        response.status(403);
        response.text("Forbidden");
        return;
      }
    }
    
    chain.doFilter(request, response);
  }
}
```

## Intercepting Request Body

Read and modify request body:

```java
public class RequestBodyFilter implements Filter {
  @Override
  public void doFilter(Request request, Response response, FilterChain chain) 
    throws Exception {
    
    String body = request.body();
    
    if (body != null && body.contains("sensitive")) {
      // Sanitize or reject
      response.status(400);
      response.text("Invalid input");
      return;
    }
    
    chain.doFilter(request, response);
  }
}
```

## Performance Considerations

- Keep filters lightweight
- Avoid blocking I/O in filters
- Cache expensive computations
- Order filters by frequency of use

## Best Practices

| Practice | Reason |
|----------|--------|
| Order filters properly | Execution sequence matters |
| Log at appropriate levels | Debug vs production clarity |
| Handle exceptions gracefully | Prevent filter chain breakage |
| Use specific conditions | Apply filters only when needed |
| Test filters independently | Ensure correct behavior |

## Next Steps

- Learn about [dependency injection](dependency-injection.md)
- See [exception handling](exception-handling.md)
- Check [testing guide](testing.md) for filter testing

---

## Source: `nima/exception-handling.md`

# Exception Handling

How to handle errors gracefully in nima applications.

## Global Exception Handler

Create a global exception handler:

```java
import io.avaje.nima.ExceptionHandler;
import io.avaje.nima.Context;

@ExceptionHandler
public class GlobalExceptionHandler {
  
  public ErrorResponse handle(Exception e, Context ctx) {
    int status = 500;
    String message = "Internal Server Error";
    
    if (e instanceof ValidationException) {
      status = 400;
      message = e.getMessage();
    } else if (e instanceof ResourceNotFoundException) {
      status = 404;
      message = e.getMessage();
    } else if (e instanceof UnauthorizedException) {
      status = 401;
      message = e.getMessage();
    }
    
    ctx.status(status);
    return new ErrorResponse(status, message);
  }
}

public class ErrorResponse {
  public int status;
  public String message;
  
  public ErrorResponse(int status, String message) {
    this.status = status;
    this.message = message;
  }
}
```

## Controller-Level Exception Handling

Handle exceptions per controller:

```java
@Controller
@Path("/users")
public class UserController {
  
  @ExceptionHandler
  public ErrorResponse handleException(Exception e, Context ctx) {
    ctx.status(500);
    return new ErrorResponse(500, e.getMessage());
  }
  
  @Get(":id")
  public User getUser(long id) {
    return userService.findById(id)
      .orElseThrow(() -> new ResourceNotFoundException("User not found"));
  }
}
```

## Custom Exceptions

Create custom exceptions:

```java
public class ResourceNotFoundException extends RuntimeException {
  public ResourceNotFoundException(String message) {
    super(message);
  }
}

public class ValidationException extends RuntimeException {
  public final List<String> errors;
  
  public ValidationException(List<String> errors) {
    super("Validation failed");
    this.errors = errors;
  }
}

public class UnauthorizedException extends RuntimeException {
  public UnauthorizedException(String message) {
    super(message);
  }
}
```

## Handling Specific Exceptions

Return different responses based on exception type:

```java
@ExceptionHandler
public Response<?> handle(Exception e, Context ctx) {
  
  if (e instanceof ValidationException) {
    ctx.status(400);
    return Response.of(new {
      errors = ((ValidationException) e).errors,
      message = "Validation failed"
    });
  }
  
  if (e instanceof ResourceNotFoundException) {
    ctx.status(404);
    return Response.of(new {
      message = e.getMessage()
    });
  }
  
  if (e instanceof UnauthorizedException) {
    ctx.status(401);
    return Response.of(new {
      message = "Unauthorized"
    });
  }
  
  // Default 500
  ctx.status(500);
  return Response.of(new {
    message = "Internal Server Error"
  });
}
```

## Validation Error Responses

Return validation errors with details:

```java
@Controller
@Path("/items")
public class ItemController {
  
  @Post
  public Item create(CreateItemRequest req) {
    List<String> errors = new ArrayList<>();
    
    if (req.name == null || req.name.isEmpty()) {
      errors.add("name is required");
    }
    if (req.price <= 0) {
      errors.add("price must be positive");
    }
    
    if (!errors.isEmpty()) {
      throw new ValidationException(errors);
    }
    
    return itemService.create(req);
  }
}

// Response:
// {
//   "message": "Validation failed",
//   "errors": ["name is required", "price must be positive"]
// }
```

## Logging Exceptions

Log exceptions while handling:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@ExceptionHandler
public Response<?> handle(Exception e, Context ctx) {
  Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);
  
  if (e instanceof ValidationException) {
    log.warn("Validation error: {}", e.getMessage());
    ctx.status(400);
  } else {
    log.error("Unexpected error", e);
    ctx.status(500);
  }
  
  return Response.of(new { message = e.getMessage() });
}
```

## Async Error Handling

Handle errors in async operations:

```java
@Controller
@Path("/async")
public class AsyncController {
  
  @Get
  public CompletableFuture<Data> fetchAsync() {
    return dataService.fetchAsync()
      .exceptionally(e -> {
        logger.error("Async fetch failed", e);
        throw new RuntimeException("Failed to fetch data");
      });
  }
}
```

## Best Practices

| Practice | Reason |
|----------|--------|
| Use specific exception types | Better error categorization |
| Return meaningful error messages | Helps API consumers debug |
| Log all exceptions | Essential for debugging |
| Use consistent error format | Better API experience |
| Don't expose stack traces to clients | Security and user experience |

## Next Steps

- Add [validation](validation.md) to prevent invalid data
- Use [filters](filters.md) for cross-cutting concerns
- See [troubleshooting](troubleshooting.md) for common errors

---

## Source: `nima/add-global-exception-handler.md`

# Guide: Add a Global Exception Handler

## Purpose

This guide provides step-by-step instructions for adding a centralised exception
handler to an **avaje-nima** project. The handler catches exceptions thrown by any
controller, maps them to structured JSON error responses, and sets the correct HTTP
status codes — without repeating error-handling logic in every endpoint.

When asked to *"add a global exception handler"*, *"add centralised error handling"*,
or *"add an error response"* to an avaje-nima project, follow these steps exactly.

---

## Overview

The pattern uses two classes in a `web/exception` package:

| Class | Purpose |
|---|---|
| `ErrorResponse` | JSON record returned in the response body for all errors |
| `GlobalExceptionController` | `@Controller` with `@ExceptionHandler` methods; one per exception type |

avaje's annotation processor generates the routing glue at compile time — no runtime
configuration needed.

> `avaje-nima` already transitively includes `avaje-jsonb` (`@Json`) and
> `avaje-http-api` (`@ExceptionHandler`). Only `avaje-record-builder` needs to be
> added explicitly.

---

## Step 1 — Add the `avaje-record-builder` dependency to `pom.xml`

`ErrorResponse` uses `@RecordBuilder` to generate a builder. Add the dependency to
`pom.xml` as a `provided`-scope annotation processor:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-record-builder</artifactId>
  <version>1.4</version>
  <scope>provided</scope>
</dependency>
```

---

## Step 2 — Create `ErrorResponse.java`

Create the file at `src/main/java/<base-package>/web/exception/ErrorResponse.java`.

Replace `<base-package>` with the project's root package (find it by looking at
existing controller imports or `module-info.java`).

```java
package <base-package>.web.exception;

import io.avaje.jsonb.Json;
import io.avaje.recordbuilder.RecordBuilder;

@Json
@RecordBuilder
public record ErrorResponse(
    int httpCode,
    String path,
    String message,
    String traceId
) {
    public static ErrorResponseBuilder builder() {
        return ErrorResponseBuilder.builder();
    }
}
```

**Fields:**

| Field | Description |
|---|---|
| `httpCode` | The HTTP status code (e.g. `400`, `404`, `500`) |
| `path` | The request path where the error occurred |
| `message` | A human-readable description of the error |
| `traceId` | Distributed trace ID (set to `null` until tracing is integrated) |

> `@RecordBuilder` instructs the `avaje-record-builder` processor to generate
> `ErrorResponseBuilder` at compile time. The static `builder()` method delegates to
> the generated builder.

---

## Step 3 — Create `GlobalExceptionController.java`

Create the file at
`src/main/java/<base-package>/web/exception/GlobalExceptionController.java`:

```java
package <base-package>.web.exception;

import io.avaje.http.api.Controller;
import io.avaje.http.api.ExceptionHandler;
import io.avaje.http.api.Produces;
import io.helidon.http.BadRequestException;
import io.helidon.http.InternalServerException;
import io.helidon.http.NotFoundException;
import io.helidon.webserver.http.ServerRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Controller
final class GlobalExceptionController {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionController.class);

    private static final int HTTP_500 = 500;
    private static final int HTTP_400 = 400;
    private static final int HTTP_404 = 404;

    private static final String HTTP_500_MESSAGE = "An error occurred processing the request.";
    private static final String HTTP_404_MESSAGE = "Not found for ";

    @Produces(statusCode = HTTP_500)
    @ExceptionHandler
    ErrorResponse defaultErrorResponse(Exception ex, ServerRequest req) {
        logException(ex, path(req));
        return ErrorResponse.builder()
            .httpCode(HTTP_500)
            .path(path(req))
            .message(HTTP_500_MESSAGE)
            .build();
    }

    @Produces(statusCode = HTTP_400)
    @ExceptionHandler
    ErrorResponse badRequest(BadRequestException ex, ServerRequest req) {
        logException(ex, path(req));
        return ErrorResponse.builder()
            .httpCode(HTTP_400)
            .path(path(req))
            .message(ex.getMessage())
            .build();
    }

    @Produces(statusCode = HTTP_500)
    @ExceptionHandler
    ErrorResponse internalServerError(InternalServerException ex, ServerRequest req) {
        logException(ex, path(req));
        return ErrorResponse.builder()
            .httpCode(HTTP_500)
            .path(path(req))
            .message(HTTP_500_MESSAGE)
            .build();
    }

    @Produces(statusCode = HTTP_400)
    @ExceptionHandler(UnsupportedOperationException.class)
    ErrorResponse unsupportedOperation(UnsupportedOperationException ex, ServerRequest req) {
        return ErrorResponse.builder()
            .httpCode(HTTP_400)
            .path(path(req))
            .message(ex.getMessage())
            .traceId(null)
            .build();
    }

    @Produces(statusCode = HTTP_404)
    @ExceptionHandler(NotFoundException.class)
    ErrorResponse notFound(ServerRequest req) {
        String path = path(req);
        log.debug("404 not found path:{}", path);
        return ErrorResponse.builder()
            .httpCode(HTTP_404)
            .path(path)
            .message(HTTP_404_MESSAGE + path)
            .traceId(null)
            .build();
    }

    private static void logException(Exception ex, String path) {
        log.error("An error occurred processing request on path '{}'", path, ex);
    }

    private static String path(ServerRequest req) {
        return req != null && req.path() != null
            ? req.path().path()
            : null;
    }
}
```

---

## Step 4 — Key rules to follow

1. **`GlobalExceptionController` must be package-private** (`final class`, no `public`).
   avaje-inject discovers it from generated wiring regardless of visibility.
2. **`ErrorResponse` must be `public`** — it is part of the JSON API surface.
3. Both files go in the **same `web/exception` package** (or equivalent sub-package).
4. The `@ExceptionHandler` exception type is inferred from the first parameter; use
   `@ExceptionHandler(SomeException.class)` when the parameter type differs or is
   omitted (e.g. the 404 handler which has no exception parameter).
5. Always pair `@ExceptionHandler` with `@Produces(statusCode = N)` to set the correct
   HTTP status.

### Handler method signature rules

avaje-http maps `@ExceptionHandler` methods by inspecting the first parameter type:

```java
// Implicit — exception type inferred from first parameter
@ExceptionHandler
ErrorResponse handle(BadRequestException ex, ServerRequest req) { … }

// Explicit — handles exactly UnsupportedOperationException
@ExceptionHandler(UnsupportedOperationException.class)
ErrorResponse handle(UnsupportedOperationException ex, ServerRequest req) { … }

// No exception parameter — handler receives only the request (e.g. for 404)
@ExceptionHandler(NotFoundException.class)
ErrorResponse handle(ServerRequest req) { … }
```

### Handler priority

More-specific exception types take priority over broader ones. The `Exception`
catch-all is the fallback:

```
NotFoundException             → 404
BadRequestException           → 400
InternalServerException       → 500
UnsupportedOperationException → 400
Exception (catch-all)         → 500
```

---

## Step 5 — Verify

```bash
mvn compile
```

The build must succeed with no errors from the annotation processors. Then run and test:

```bash
curl -i http://localhost:8080/no-such-path
# Expected: HTTP 404, Content-Type: application/json
```

Expected response body:

```json
{"httpCode":404,"path":"/no-such-path","message":"Not found for /no-such-path","traceId":null}
```

---

## Notes

- The `traceId` field is always `null` in this baseline. Populate it with a distributed
  trace ID (e.g. from a `traceparent` header) when tracing is integrated:
  ```java
  String traceId = req.headers().value(HeaderNames.create("traceparent")).orElse(null);
  ```
- To add handlers for additional exception types, add new methods following the same
  pattern: `@Produces(statusCode = N)` + `@ExceptionHandler` + exception type as first
  parameter.
- The `Exception` catch-all is the fallback. More-specific types always take priority.

---

## Version compatibility

| Component | Tested version |
|---|---|
| `avaje-record-builder` | 1.4 |
| `avaje-nima` (includes `avaje-http-api`, `avaje-jsonb`) | 1.8 |
| Helidon SE | 4.4.0 |
| Java | 25 |

---

## References

- avaje-http `@ExceptionHandler` docs: https://avaje.io/http/
- avaje-record-builder: https://github.com/avaje/avaje-record-builder

---

## Source: `nima/validation.md`

# Request Validation

How to validate request data in nima applications.

## Using Bean Validation

Add the dependency:

```xml
<dependency>
  <groupId>jakarta.validation</groupId>
  <artifactId>jakarta.validation-api</artifactId>
  <version>3.0.0</version>
</dependency>

<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-validator</artifactId>
  <version>2.0</version>
</dependency>
```

Validate request objects:

```java
public class CreateUserRequest {
  @NotNull
  @NotBlank
  public String name;
  
  @NotNull
  @Email
  public String email;
  
  @Min(18)
  public int age;
}

@Controller
@Path("/users")
public class UserController {
  private final Validator validator;
  
  public UserController(Validator validator) {
    this.validator = validator;
  }
  
  @Post
  public User create(CreateUserRequest req) {
    Set<ConstraintViolation<CreateUserRequest>> violations = 
      validator.validate(req);
    
    if (!violations.isEmpty()) {
      List<String> errors = violations.stream()
        .map(v -> v.getPropertyPath() + ": " + v.getMessage())
        .toList();
      throw new ValidationException(errors);
    }
    
    return userService.create(req);
  }
}
```

## Common Validation Annotations

| Annotation | Purpose |
|-----------|---------|
| `@NotNull` | Value must not be null |
| `@NotBlank` | String must not be blank |
| `@NotEmpty` | Collection/array must not be empty |
| `@Size(min, max)` | String/collection size |
| `@Min(value)` | Number minimum |
| `@Max(value)` | Number maximum |
| `@Email` | Valid email format |
| `@Pattern(regex)` | Matches regex |
| `@Future` | Date must be in future |
| `@Past` | Date must be in past |

## Custom Validation

Create custom validators:

```java
@Constraint(validatedBy = UniqueEmailValidator.class)
@Target({ ElementType.FIELD })
@Retention(RetentionPolicy.RUNTIME)
public @interface UniqueEmail {
  String message() default "Email already exists";
  Class<?>[] groups() default {};
  Class<? extends Payload>[] payload() default {};
}

public class UniqueEmailValidator 
  implements ConstraintValidator<UniqueEmail, String> {
  
  private final UserService userService;
  
  public UniqueEmailValidator(UserService userService) {
    this.userService = userService;
  }
  
  @Override
  public boolean isValid(String value, ConstraintValidatorContext context) {
    if (value == null) return true;
    return !userService.emailExists(value);
  }
}

public class CreateUserRequest {
  @UniqueEmail
  public String email;
}
```

## Group Validation

Validate different groups for different operations:

```java
public interface CreateGroup {}
public interface UpdateGroup {}

public class UserRequest {
  @NotNull(groups = UpdateGroup.class)
  public Long id;
  
  @NotBlank(groups = { CreateGroup.class, UpdateGroup.class })
  public String name;
  
  @Email(groups = { CreateGroup.class, UpdateGroup.class })
  public String email;
}

@Controller
@Path("/users")
public class UserController {
  
  @Post
  public User create(UserRequest req) {
    validate(req, CreateGroup.class);
    return userService.create(req);
  }
  
  @Put(":id")
  public User update(long id, UserRequest req) {
    req.id = id;
    validate(req, UpdateGroup.class);
    return userService.update(req);
  }
  
  private void validate(UserRequest req, Class<?> group) {
    Set<ConstraintViolation<UserRequest>> violations = 
      validator.validate(req, group);
    
    if (!violations.isEmpty()) {
      List<String> errors = violations.stream()
        .map(v -> v.getMessage())
        .toList();
      throw new ValidationException(errors);
    }
  }
}
```

## Cascading Validation

Validate nested objects:

```java
public class User {
  @NotBlank
  public String name;
  
  @Valid
  @NotNull
  public Address address;
}

public class Address {
  @NotBlank
  public String street;
  
  @NotBlank
  public String city;
  
  @Pattern(regexp = "\\d{5}")
  public String zipCode;
}

@Controller
public class UserController {
  @Post("/users")
  public User create(CreateUserRequest req) {
    // Validates User AND nested Address
    validate(req);
    return userService.create(req);
  }
}
```

## Field-Level Validation

Validate individual fields:

```java
@NotBlank
public String validateEmail(String email) {
  if (!email.contains("@")) {
    throw new ValidationException("Invalid email format");
  }
  return email;
}
```

## Response Format

Return validation errors consistently:

```java
public class ValidationErrorResponse {
  public String message;
  public List<FieldError> errors;
  
  public static class FieldError {
    public String field;
    public String message;
    
    public FieldError(String field, String message) {
      this.field = field;
      this.message = message;
    }
  }
}

@ExceptionHandler
public ValidationErrorResponse handle(ValidationException e) {
  ValidationErrorResponse resp = new ValidationErrorResponse();
  resp.message = "Validation failed";
  resp.errors = e.errors.stream()
    .map(err -> new FieldError(err.field, err.message))
    .toList();
  return resp;
}
```

## Best Practices

| Practice | Reason |
|----------|--------|
| Validate on the server | Never trust client validation |
| Use bean validation annotations | Standard, declarative approach |
| Return field-level errors | Helps API consumers fix issues |
| Validate early | Fail fast on invalid requests |
| Test validation rules | Ensure error messages are clear |

## Next Steps

- Learn about [exception handling](exception-handling.md)
- Use [filters](filters.md) for validation middleware
- See [testing guide](testing.md) for testing validation
