# Avaje Bundle — Usage (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `jsonb/basic-usage.md`

# Basic Usage of Avaje Jsonb

How to serialize and deserialize JSON with avaje-jsonb.

## Getting the Jsonb Instance

You can either use the default instance or build a custom one:

```java
import io.avaje.jsonb.Jsonb;

// Use default instance
Jsonb jsonb = Jsonb.instance();

// Or build with configuration
Jsonb jsonb = Jsonb.builder()
  .serializeNulls(true)
  .serializeEmpty(true)
  .build();
```

## Serialization

Convert Java objects to JSON:

```java
User user = new User(1, "John", "john@example.com");

// Using default instance
String json = Jsonb.instance().toJson(user);
// {"id":1,"name":"John","email":"john@example.com"}

// Or with JsonType for more control
String json = jsonb.type(User.class).toJson(user);
```

## Deserialization

Convert JSON to Java objects:

```java
String json = "{\"id\":1,\"name\":\"John\",\"email\":\"john@example.com\"}";

User user = jsonb.type(User.class).fromJson(json);
```

## Collections

Handle lists and maps using `Types` helper:

```java
import io.avaje.jsonb.Types;

List<User> users = new ArrayList<>();
users.add(new User(1, "John", "john@example.com"));
users.add(new User(2, "Jane", "jane@example.com"));

// Serialize list
String json = jsonb.type(Types.listOf(User.class)).toJson(users);

// Deserialize list
List<User> restored = jsonb.type(Types.listOf(User.class)).fromJson(json);
```

## Next Steps

- Learn [custom adapters](custom-adapters.md)
- Understand [property mapping](property-mapping.md)

---

## Source: `jsonb/property-mapping.md`

# Property Mapping

Map JSON properties to Java fields.

## Rename Properties

Use `@Json.Property` to map properties:

```java
import io.avaje.jsonb.Json;

@Json
public class User {
  @Json.Property("user_id")
  public long id;
  
  @Json.Property("full_name")
  public String name;
  
  public String email;
}

// JSON: {"user_id":1,"full_name":"John","email":"john@example.com"}
```

## Ignore Properties

Skip properties during serialization and deserialization:

```java
import io.avaje.jsonb.Json;

@Json
public class User {
  public long id;
  public String name;
  
  @Json.Ignore
  public String password;
}

// JSON: {"id":1,"name":"John"} (password excluded)
```

## Next Steps

- Learn [streaming](streaming.md)
