# Avaje Bundle — JSON (Flattened)

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

## Source: `jsonb/custom-adapters.md`

# Custom JSON Adapters

Create custom JSON serialization/deserialization logic.

## Adapter Implementation

```java
import io.avaje.json.JsonAdapter;
import io.avaje.json.JsonReader;
import io.avaje.json.JsonWriter;
import java.time.LocalDateTime;

public final class LocalDateTimeAdapter implements JsonAdapter<LocalDateTime> {

  @Override
  public void toJson(JsonWriter writer, LocalDateTime value) {
    writer.value(value.toString());
  }

  @Override
  public LocalDateTime fromJson(JsonReader reader) {
    return LocalDateTime.parse(reader.readString());
  }
}
```

## Register the Adapter

```java
import io.avaje.jsonb.Jsonb;
import java.time.LocalDateTime;

Jsonb jsonb = Jsonb.builder()
  .add(LocalDateTime.class, new LocalDateTimeAdapter())
  .build();
```

## Next Steps

- See [property mapping](property-mapping.md)

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

---

## Source: `jsonb/polymorphic-types.md`

# Polymorphic Types

Handle polymorphic JSON with inheritance.

## Type Discriminator

Use `@Json.SubType` on the base type to declare concrete subtypes:

```java
import io.avaje.jsonb.Json;

@Json(typeProperty = "type")
@Json.SubType(type = Dog.class, name = "dog")
@Json.SubType(type = Cat.class, name = "cat")
public abstract class Animal {
  public String name;
}

@Json
public class Dog extends Animal {
  public String breed;
}

@Json
public class Cat extends Animal {
  public String color;
}
```

Serialize and deserialize via the base type:

```java
import io.avaje.jsonb.JsonType;
import io.avaje.jsonb.Jsonb;

Jsonb jsonb = Jsonb.instance();
JsonType<Animal> animalType = jsonb.type(Animal.class);

Animal dog = animalType.fromJson("{\"type\":\"dog\",\"name\":\"Fido\",\"breed\":\"Labrador\"}");
String json = animalType.toJson(dog);
```

## Next Steps

- Learn [file chaining](file-chaining.md)

---

## Source: `jsonb/streaming.md`

# Streaming JSON

Efficiently stream large JSON documents.

## Streaming Deserialization

Process large JSON arrays element by element:

```java
import io.avaje.json.JsonReader;
import io.avaje.jsonb.JsonType;
import io.avaje.jsonb.Jsonb;
import java.util.stream.Stream;

Jsonb jsonb = Jsonb.instance();
JsonType<String> stringType = jsonb.type(String.class);
String payload = "[\"one\",\"two\",\"three\"]";

try (JsonReader reader = jsonb.reader(payload);
     Stream<String> values = stringType.stream(reader)) {
  values.forEach(System.out::println);
}
```

This avoids loading the entire array into memory.

## Next Steps

- See [polymorphic types](polymorphic-types.md)
