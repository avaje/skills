---
name: avaje-metrics
description: Avaje Metrics instrumentation and reporting. Timers, counters, gauges, meters, JVM metrics, @Timed enhancement, metrics agent configuration, OpenTelemetry, Prometheus, StatsD, Graphite, and Ebean metrics. Use when adding, configuring, or troubleshooting avaje-metrics.
---

# Avaje Metrics

Avaje Metrics is a lightweight metrics library for Java. It provides programmatic
timers, counters, gauges, and meters, plus optional build-time method timing and
reporters for common observability systems.

## Key Principles

- Default and custom `MetricRegistry` support
- Timers, counters, gauges, and meters for application metrics
- `@Timed` method timing via `metrics-maven-plugin`
- `metrics.mf` controls enhancement, naming, tags, buckets, and traced timers
- Label-tag timer naming is preferred for lower metric-name cardinality
- Optional JVM metrics registration
- Export paths for OpenTelemetry, Prometheus, StatsD, and Graphite
- Ebean database metrics integration

## Task Guides

Load the relevant reference guide for the current task. **Only load what you need.**

| Task | Reference |
|------|-----------|
| Setup, first metrics, JVM metrics | [setup](references/setup.md) |
| Timers, `@Timed`, metrics agent configuration | [method-timing](references/method-timing.md) |
| OpenTelemetry, Prometheus, StatsD, Graphite | [exporters](references/exporters.md) |
| Ebean database metrics | [integrations](references/integrations.md) |

## Quick Reference

### Dependency

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-metrics</artifactId>
  <version>9.10</version>
</dependency>
```

### Programmatic Metrics

```java
import io.avaje.metrics.Metrics;

Metrics.counter("app.requests").inc();

var timer = Metrics.timer("app.service.run");
timer.time(service::run);

Metrics.gauge("app.queue.depth", queue::size);
```

### Method Timing

```java
import io.avaje.metrics.annotation.Timed;

@Timed
class BillingService {

  void sync() {
    // timed by build-time enhancement
  }
}
```

### Metrics Agent Configuration

```text
# src/main/resources/metrics.mf
packages: com.example
timedMetricNaming: label-tag
nameTrimPackages: com.example
```

### Reporter Examples

```java
StatsdReporter.builder()
  .hostname("localhost")
  .port(8125)
  .build()
  .start();
```

```java
GraphiteReporter.builder()
  .hostname("graphite.example.com")
  .port(2003)
  .prefix("prod.myapp.")
  .build()
  .report();
```

## Regenerating References

```bash
cd /path/to/avaje/skills && ./generate-references.sh
```
