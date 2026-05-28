# Avaje Bundle — Setup (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `metrics/getting-started.md`

# Guide: Getting Started

## Purpose

This guide provides step-by-step instructions for adding **avaje-metrics** to a project,
creating the first metrics, and understanding the default registry.

When asked to *"add avaje-metrics"*, *"get started with metrics"*, *"create counters or
timers"*, or *"set up the default registry"* in a Java project, follow these steps
exactly.

---

## Overview

avaje-metrics is centered around a `MetricRegistry` and four main metric types:

| Type | Purpose | Example |
|---|---|---|
| `Counter` | Count events | requests, retries, errors |
| `Timer` | Measure execution time | service calls, HTTP handlers |
| `Meter` | Record value-carrying events | bytes sent, rows processed |
| `Gauge` | Read a current value from a supplier | queue depth, memory usage |

Most applications use the default registry via the static `Metrics` helper and enable
build-time enhancement for `@Timed`, then choose an export path such as OpenTelemetry,
Prometheus, StatsD, or Graphite separately.

---

## Step 1 — Add the dependency

Add `avaje-metrics` to `pom.xml`:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-metrics</artifactId>
  <version>${version}</version>
</dependency>
```

If the project uses `module-info.java`, also add:

```java
requires io.avaje.metrics;
```

---

## Step 2 — Add build-time enhancement

Most avaje-metrics applications use build-time enhancement for declarative method timing
with `@Timed`. Add the metrics Maven plugin under `pom.xml` / `build` / `plugins`:

```xml
<build>
  <plugins>
    <plugin>
      <groupId>io.avaje.metrics</groupId>
      <artifactId>metrics-maven-plugin</artifactId>
      <version>${avaje-metrics.version}</version>
      <extensions>true</extensions>
    </plugin>
  </plugins>
</build>
```

This enhances compiled classes during the Maven build. No runtime `-javaagent` setup is
needed for the common Maven path.

---

## Step 3 — Start with the default registry

The simplest path is to use the default registry through `Metrics`.

```java
import io.avaje.metrics.Metrics;
import io.avaje.metrics.MetricRegistry;

MetricRegistry registry = Metrics.registry();
```

Most applications do not need to create a separate registry unless they want to isolate
metric sets or manage collection independently.

If a separate registry is needed:

```java
MetricRegistry registry = Metrics.createRegistry();
```

---

## Step 4 — Create the first metrics

```java
import io.avaje.metrics.Metrics;
import io.avaje.metrics.Tags;

var requests = Metrics.counterBuilder("app.http.requests")
  .unit("{event}")
  .build();

var timer = Metrics.timerBuilder("app.service.run")
  .tags(Tags.of("operation:sync"))
  .build();

var bytesSent = Metrics.meterBuilder("app.bytes.sent")
  .unit("By")
  .build();

Metrics.gauge("app.queue.depth")
  .ofLongs(queue::size);
```

Metric naming guidance:

- use stable, dotted names such as `app.http.requests`
- use tags for dimensions like `env:prod` or `operation:sync`
- use units where they add real meaning, such as `By`, `row`, or `MiBy`

---

## Step 5 — Record values

```java
requests.inc();
requests.inc(42);

timer.time(service::run);

bytesSent.addEvent(4_096);
```

If you want explicit timer lifecycle control:

```java
var event = timer.startEvent();
try {
  service.run();
  event.end();
} catch (RuntimeException e) {
  event.endWithError(e);
  throw e;
}
```

---

## Step 6 — Inspect collected metrics

For a quick sanity check, collect metrics from the default registry:

```java
var metrics = Metrics.collectMetrics();
var json = Metrics.collectAsJson().asJson();
```

This is useful for verification during local setup even if the application will later use
an exporter module.

---

## Next steps

- For built-in JVM metrics, see [register-jvm-metrics.md](register-jvm-metrics.md)
- For method timing and traced timers, see [add-method-timing.md](add-method-timing.md)
- For build-time enhancement options, see [configure-metrics-agent.md](configure-metrics-agent.md)
- For OpenTelemetry export, see [add-open-telemetry-export.md](add-open-telemetry-export.md)
- For Prometheus scraping, see [add-prometheus-scrape.md](add-prometheus-scrape.md)

## Notes

- `Metrics.registry()` returns the default shared registry.
- `Metrics.createRegistry()` creates a separate registry when isolation is needed.
- `metrics-maven-plugin` enables the common build-time enhancement path for `@Timed`.
- Export is a separate concern; `avaje-metrics` collects metrics, while modules such as
  OpenTelemetry, Prometheus, StatsD, or Graphite handle shipping them elsewhere.

---

## Source: `metrics/register-jvm-metrics.md`

# Guide: Register JVM Metrics

## Purpose

This guide provides step-by-step instructions for registering the built-in JVM metric
sets exposed by **avaje-metrics**.

When asked to *"add JVM metrics"*, *"register runtime metrics"*, *"add heap/thread/GC
metrics"*, or *"use `Metrics.jvmMetrics()`"* in a project, follow these steps exactly.

---

## Overview

avaje-metrics exposes built-in JVM metrics via `Metrics.jvmMetrics()` and `MetricRegistry`
because `MetricRegistry` extends `JvmMetrics`.

The most common choices are:

| Call | Best for |
|---|---|
| `registerJvmCoreMetrics()` | lower-cardinality / lower-cost baseline metrics |
| `registerJvmMetrics()` | full built-in JVM metric set |
| individual `register...()` methods | precise control over which JVM metrics are enabled |

---

## Step 1 — Choose core or full JVM metrics

For a smaller baseline set:

```java
import io.avaje.metrics.Metrics;

Metrics.jvmMetrics()
  .registerJvmCoreMetrics();
```

For the full default built-in set:

```java
Metrics.jvmMetrics()
  .registerJvmMetrics();
```

`registerJvmCoreMetrics()` is the better default when you want lower-cardinality export or using GraalVM native image.
`registerJvmMetrics()` is the better choice when broader runtime visibility matters more.

---

## Step 2 — Add detail and global tags when needed

```java
import io.avaje.metrics.Metrics;
import io.avaje.metrics.Tags;

Metrics.jvmMetrics()
  .withDetails()
  .withGlobalTags(Tags.of("env:dev", "service:billing"))
  .withReportAlways()
  .registerJvmMetrics();
```

Useful options:

- `withDetails()` — include more detailed GC, thread, and cgroup metrics where supported
- `withGlobalTags(...)` — apply stable tags such as environment or service name
- `withReportAlways()` — report even metrics that do not change often
- `withReportChangesOnly()` — reduce repeated reporting for stable values

---

## Step 3 — Register only selected JVM metric groups

If full registration is too broad, enable only the groups you need:

```java
Metrics.jvmMetrics()
  .withDetails()
  .registerJvmMemoryMetrics()
  .registerJvmThreadMetrics()
  .registerJvmGCMetrics();
```

Other focused options include:

- `registerJvmOsLoadMetric()`
- `registerProcessMemoryMetrics()`
- `registerCGroupMetrics()`

This is useful when export cost or metric volume matters.

---

## Step 4 — Verify

After registration, collect metrics from the default registry:

```java
var metrics = Metrics.collectMetrics();
var json = Metrics.collectAsJson().asJson();
```

Look for names such as:

- `jvm.memory.heap.used`
- `jvm.threads.current`
- `jvm.gc.time`

---

## Notes

- `registerJvmCoreMetrics()` is usually the safest starting point for production export.
- `withDetails()` increases metric volume; use it intentionally.
- `withGlobalTags(...)` is a good place to apply stable tags such as environment or service.
- The built-in JVM metrics can be registered on the default registry or any custom
  `MetricRegistry`.
