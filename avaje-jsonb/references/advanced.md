# Avaje Bundle — Advanced (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

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
