---
name: avaje-simple-logger
description: Avaje Simple Logger — lightweight SLF4J implementation for Java. Setup, configuration, replacing Logback, dynamic log levels via AWS AppConfig. Use when adding or configuring avaje-simple-logger.
---

# Avaje Simple Logger

Avaje Simple Logger is a lightweight SLF4J implementation for Java. It's designed
for microservices and GraalVM native images where a full logging framework like
Logback is unnecessary overhead.

## Key Principles

- Drop-in SLF4J implementation — uses standard `LoggerFactory.getLogger()`
- Configuration via `simplelogger.properties` or `application.yaml`
- No XML configuration files needed
- GraalVM native image compatible
- Dynamic log level changes via AWS AppConfig (optional)
- Ideal companion for avaje-nima

## Task Guides

Load the relevant reference guide for the current task. **Only load what you need.**

| Task | Reference |
|------|-----------|
| Setup, configuration, replacing Logback | [setup](references/setup.md) |
| AWS AppConfig dynamic log levels | [aws-appconfig](references/aws-appconfig.md) |

## Quick Reference

### Dependency

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-simple-logger</artifactId>
  <version>${avaje-simple-logger.version}</version>
</dependency>
```

### Configuration

```properties
# src/main/resources/simplelogger.properties
org.slf4j.simpleLogger.defaultLogLevel=info
org.slf4j.simpleLogger.log.com.myapp=debug
```

### Usage

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

class MyService {
  private static final Logger log = LoggerFactory.getLogger(MyService.class);

  void doWork() {
    log.info("Processing request");
    log.debug("Detail: {}", detail);
  }
}
```

## Regenerating References

```bash
cd /path/to/avaje/skills && ./generate-references.sh
```
