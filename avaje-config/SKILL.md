---
name: avaje-config
description: Avaje Config external configuration library. YAML/properties loading, profiles, environment variables, change listeners, AWS AppConfig. Use when working with avaje-config for application configuration.
---

# Avaje Config

Avaje Config is a lightweight external configuration library for Java. It loads
configuration from YAML/properties files, environment variables, and cloud sources
like AWS AppConfig.

## Key Principles

- `Config.get("key")` / `Config.getInt(...)` / `Config.getBool(...)` for static access
- `Configuration` interface for injectable, testable config access
- YAML and properties file support with profile-based overrides
- Environment variable binding
- Runtime change listeners for dynamic configuration
- AWS AppConfig plugin for cloud-native config management
- GraalVM native image compatible

## Task Guides

Load the relevant reference guide for the current task. **Only load what you need.**

| Task | Reference |
|------|-----------|
| Setup, loading, defaults | [setup](references/setup.md) |
| Profiles, env vars, cloud integration | [advanced](references/advanced.md) |
| Testing, troubleshooting | [testing](references/testing.md) |

## Quick Reference

### application.yaml

```yaml
server:
  port: 8080
myapp:
  feature.enabled: true
  maxRetries: 3
```

### Static Access

```java
String value = Config.get("myapp.key");
int port = Config.getInt("server.port", 8080);
boolean enabled = Config.getBool("myapp.feature.enabled", false);
```

### Injectable Access

```java
@Singleton
class MyService {

  private final int maxRetries;

  @Inject
  MyService(Configuration config) {
    this.maxRetries = config.getInt("myapp.maxRetries", 3);
  }
}
```

### Change Listeners

```java
Config.onChange("myapp.feature.enabled", newValue -> {
  // react to runtime config change
});
```

## Regenerating References

```bash
cd /path/to/avaje/skills && ./generate-references.sh
```
