# Avaje Bundle — Exporters (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `metrics/add-open-telemetry-export.md`

# Guide: Add OpenTelemetry Export

## Purpose

This guide provides step-by-step instructions for exporting **avaje-metrics** data to
OpenTelemetry.

When asked to *"export metrics to OpenTelemetry"*, *"choose the right OTEL module"*, or
*"wire avaje-metrics into OpenTelemetry"* in a project, follow these steps exactly.

---

## Overview

The main decision is **which OpenTelemetry module to use**.

| Module | Use when |
|---|---|
| `avaje-metrics-otel` | you want the easiest OTLP-backed setup for avaje metrics and traced timers |
| `avaje-metrics-otel-producer` | you already own the OpenTelemetry SDK wiring and want collection driven by the SDK reader/exporter |
| `avaje-metrics-otel-trace` | you only want traced timers / spans and are not exporting avaje metrics via OTEL |
| `avaje-metrics-otel-reporter` | you explicitly want the scheduled reporter path rather than the SDK `MetricProducer` path |

In most new setups, start with **`avaje-metrics-otel`** unless you have a clear reason to
own the SDK wiring yourself.

---

## Step 1 — Choose the module

### Easiest path: `avaje-metrics-otel`

Use this when you want:

- OTLP-backed metrics export
- OTLP-backed trace export
- `avaje-metrics-otel-producer` registered automatically
- traced timers working out of the box

### Explicit SDK path: `avaje-metrics-otel-producer`

Use this when:

- the application already builds its own `SdkMeterProvider`
- collection should be driven by the OpenTelemetry reader/exporter
- you want avaje metrics collected alongside normal OpenTelemetry metrics

For a direct Prometheus text endpoint without OpenTelemetry SDK wiring, use
[add-prometheus-scrape.md](add-prometheus-scrape.md) instead.

### Traced timers only: `avaje-metrics-otel-trace`

Use this when:

- the goal is spans from `buildTraced()` or `@Timed(span = ON)`
- avaje metrics are exported some other way, or not exported through OTEL at all

### Scheduled reporter path: `avaje-metrics-otel-reporter`

Use this when:

- you explicitly want avaje-metrics to run its own reporting schedule
- you do not want the `MetricProducer` bridge

Do **not** use `avaje-metrics-otel-reporter` and `avaje-metrics-otel-producer` for the
same registry/export path at the same time.

---

## Step 2 — Start with the convenience module when possible

Add the dependency:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-metrics-otel</artifactId>
  <version>${version}</version>
</dependency>
```

Minimal setup:

```java
import io.avaje.metrics.otel.MetricsOpenTelemetry;

import java.time.Duration;

var openTelemetry = MetricsOpenTelemetry.builder()
  .endpoint("http://otel-collector:4317")
  .serviceName("my-service")
  .meterInterval(Duration.ofSeconds(60))
  .traceInterval(Duration.ofSeconds(10))
  .buildAndRegisterGlobal();
```

This is the best default when the application wants both OTEL metrics export and traced
timer support with minimal setup code.

When using this we do **NOT** need Step 3 or Step 4.

---

## Step 3 — Use `avaje-metrics-otel-producer` when you already own the SDK

Add the dependency:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-metrics-otel-producer</artifactId>
  <version>${version}</version>
</dependency>
```

Then register the producer with your `SdkMeterProvider`:

```java
import io.avaje.metrics.Metrics;
import io.avaje.metrics.otel.producer.OtelMetricProducer;

var meterProvider = SdkMeterProvider.builder()
  .registerMetricReader(reader)
  .registerMetricProducer(
    OtelMetricProducer.builder()
      .registry(Metrics.registry())
      .timedThresholdMicros(1_000)
      .build())
  .build();
```

Use this path when the application already builds its own OpenTelemetry SDK and wants
collection intervals controlled by the SDK reader/exporter.

---

## Step 4 — Add traced timers only when metric export is handled elsewhere

Add the dependency:

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-metrics-otel-trace</artifactId>
  <version>${version}</version>
</dependency>
```

Then use traced timers:

```java
var timer = Metrics.timerBuilder("app.service.method")
  .buildTraced();

timer.time(service::run);
```

This module does not export avaje metrics to OTEL backends. It only provides the span
bridge for traced timers.

---

## Step 5 — Verify

1. Start the application with the chosen OTEL path configured.
2. Record some avaje metrics:

```java
Metrics.counter("app.requests").inc();
Metrics.timer("app.service.run").time(service::run);
```

3. Confirm the metrics and, if enabled, traced timer spans arrive in the configured
OpenTelemetry backend or collector.

## Notes

- `avaje-metrics-otel` is the best default for new OTLP-backed setups.
- `avaje-metrics-otel-producer` is the right choice when the application already owns the SDK.
- `avaje-metrics-otel-trace` is trace-only.
- `avaje-metrics-otel-reporter` is a separate scheduled path and should be used intentionally.
- For full builder and mapping details, see the module READMEs:
  - [metrics-otel/README.md](../../metrics-otel/README.md)
  - [metrics-otel-producer/README.md](../../metrics-otel-producer/README.md)
  - [metrics-otel-trace/README.md](../../metrics-otel-trace/README.md)
  - [metrics-otel-reporter/README.md](../../metrics-otel-reporter/README.md)

---

## Source: `metrics/add-prometheus-scrape.md`

# Guide: Add Prometheus Scraping

## Purpose

This guide provides step-by-step instructions for exposing **avaje-metrics** directly as
a Prometheus scrape endpoint using `avaje-metrics-prometheus`.

When asked to *"add Prometheus metrics"*, *"add a Prometheus scrape endpoint"*, or
*"export avaje-metrics in Prometheus format"* in a project, follow these steps exactly.

---

## Overview

`avaje-metrics-prometheus` is a lightweight pull exporter:

1. the application records metrics in a `MetricRegistry`
2. Prometheus scrapes an HTTP endpoint
3. the endpoint calls `PrometheusMetrics.scrape()`
4. avaje metrics are collected using `CollectionMode.CUMULATIVE`

Use this module when the application wants a direct Prometheus text endpoint without
building an OpenTelemetry SDK.

If the application already uses OpenTelemetry, use
[`avaje-metrics-otel-producer`](../../metrics-otel-producer/README.md) with the OTEL
Prometheus reader instead.

---

## Step 1 — Add the dependency

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-metrics-prometheus</artifactId>
  <version>${version}</version>
</dependency>
```

If the project uses `module-info.java`, also add:

```java
requires io.avaje.metrics.prometheus;
```

---

## Step 2 — Create the Prometheus scrape writer

```java
import io.avaje.metrics.Metrics;
import io.avaje.metrics.prometheus.PrometheusMetrics;

var prometheus = PrometheusMetrics.builder()
  .registry(Metrics.registry())
  .build();
```

Most applications use the default registry. Use `.registry(myRegistry)` only when the
application records metrics into a custom registry.

---

## Step 3 — Expose an HTTP endpoint

Expose a route such as `/metrics` from the application's existing web framework.

The response should use:

```java
var body = prometheus.scrape();
var contentType = PrometheusMetrics.CONTENT_TYPE;
```

`PrometheusMetrics.CONTENT_TYPE` is:

```text
text/plain; version=0.0.4; charset=utf-8
```

---

## Step 4 — Understand the metric mapping

| avaje metric | Prometheus output |
|---|---|
| `Counter` | `name_total` counter |
| `Timer` | `name_seconds` summary with `_count` and `_sum` samples |
| bucketed `Timer` | `name_seconds` histogram with `_bucket`, `_count`, and `_sum` samples |
| `Meter` | `name_count_total` and `name_total` counters |
| `GaugeLong` / `GaugeDouble` | `name` gauge |

Timer and meter `max` values are omitted by default because they are scrape-window values.
Enable them only when wanted:

```java
var prometheus = PrometheusMetrics.builder()
  .includeMax(true)
  .build();
```

---

## Step 5 — Verify

Record a few metrics:

```java
Metrics.counter("app.requests").inc();
Metrics.timer("app.service.run").time(service::run);
```

Then curl the endpoint:

```bash
curl -s http://localhost:8080/metrics
```

Confirm output similar to:

```text
# TYPE app_requests_total counter
app_requests_total 1
# TYPE app_service_run_seconds summary
app_service_run_seconds_count 1
app_service_run_seconds_sum 0.005
```

## Notes

- `PrometheusMetrics` is pull-based and does not start a scheduler.
- Prometheus counter output assumes avaje `Counter` values are used as increasing counters.
- Tags in `key:value` format are exported as Prometheus labels.
- Metric and label names are sanitized to Prometheus-compatible names.
- `timedThresholdMicros(...)` exists, but it applies to cumulative process-lifetime timer
  totals and is usually less useful for Prometheus scraping than for delta reporters.
- For OpenTelemetry-based Prometheus scraping, use `avaje-metrics-otel-producer` instead.

---

## Source: `metrics/add-statsd-reporting.md`

# Guide: Add StatsD Reporting

## Purpose

This guide provides step-by-step instructions for exporting **avaje-metrics** data to
StatsD / DogStatsD using `avaje-metrics-statsd`.

When asked to *"add StatsD reporting"*, *"send metrics to DogStatsD"*, or *"configure
`StatsdReporter`"* in a project, follow these steps exactly.

---

## Overview

`avaje-metrics-statsd` reports avaje-metrics data on a schedule using the Datadog Java
StatsD client.

The usual pattern is:

1. add `avaje-metrics-statsd`
2. build a `StatsdReporter`
3. start it during application startup
4. close it on shutdown

---

## Step 1 — Add the dependency

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-metrics-statsd</artifactId>
  <version>${version}</version>
</dependency>
```

---

## Step 2 — Build and start the reporter

```java
import io.avaje.metrics.statsd.StatsdReporter;

import java.util.concurrent.TimeUnit;

StatsdReporter reporter = StatsdReporter.builder()
  .hostname("localhost")
  .port(8125)
  .tags(new String[]{"env:dev", "service:billing"})
  .schedule(60, TimeUnit.SECONDS)
  .timedThresholdMicros(1_000)
  .build()
  .start();
```

Close the reporter on shutdown:

```java
reporter.close();
```

---

## Step 3 — Add custom registries or database metrics when needed

Use a non-default registry:

```java
var registry = Metrics.createRegistry();

StatsdReporter reporter = StatsdReporter.builder()
  .registry(registry)
  .build()
  .start();
```

Include Ebean database metrics directly:

```java
StatsdReporter reporter = StatsdReporter.builder()
  .database(database)
  .build()
  .start();
```

Use `databaseVerbose(database)` when you explicitly want the more detailed database path.

---

## Step 4 — Use a custom client only when necessary

If the project already creates its own `StatsDClient`, you can supply it directly:

```java
StatsdReporter reporter = StatsdReporter.builder()
  .client(customStatsdClient)
  .build()
  .start();
```

When `client(...)` is used, the hostname, port, and tags configuration on the builder is
not used.

---

## Step 5 — Verify

1. Start the application with the reporter running.
2. Record a few metrics:

```java
Metrics.counter("app.requests").inc();
Metrics.timer("app.service.run").time(service::run);
```

3. Confirm the expected metric names and tags arrive in StatsD / DogStatsD.

## Notes

- `schedule(...)` controls how often avaje-metrics is collected and sent.
- `timedThresholdMicros(...)` is useful for suppressing low-value timers when timing is
  applied broadly.
- `registry(...)`, `database(...)`, and `reporter(...)` can be combined when multiple
  metric sources need to be exported.

---

## Source: `metrics/add-graphite-reporting.md`

# Guide: Add Graphite Reporting

## Purpose

This guide provides step-by-step instructions for exporting **avaje-metrics** data to
Graphite using `avaje-metrics-graphite`.

When asked to *"add Graphite reporting"*, *"send metrics to Graphite"*, or *"configure
`GraphiteReporter`"* in a project, follow these steps exactly.

---

## Overview

`avaje-metrics-graphite` reports avaje-metrics data to a Carbon / Graphite server.

The usual pattern is:

1. add `avaje-metrics-graphite`
2. build a `GraphiteReporter`
3. call `report()` on the schedule owned by the application
4. close or stop that schedule during application shutdown

---

## Step 1 - Add the dependency

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-metrics-graphite</artifactId>
  <version>${version}</version>
</dependency>
```

If the application uses `module-info.java`, also add:

```java
requires io.avaje.metrics.graphite;
```

---

## Step 2 - Build the reporter

```java
import io.avaje.metrics.graphite.GraphiteReporter;

GraphiteReporter reporter = GraphiteReporter.builder()
  .prefix("prod.billing.")
  .hostname("graphite.example.com")
  .port(2003)
  .timedThresholdMicros(1_000)
  .build();
```

Common builder options:

- `prefix(...)` prepends a common metric path prefix such as environment and service.
- `hostname(...)` and `port(...)` set the Graphite destination.
- `socketFactory(...)` supplies a custom socket factory when needed.
- `batchSize(...)` tunes the number of tuples per Graphite payload.
- `timedThresholdMicros(...)` suppresses low-value timer metrics.
- `excludeDefaultRegistry()` reports only explicitly added registries or suppliers.

---

## Step 3 - Schedule reporting

`GraphiteReporter` does not own a scheduler. Call `report()` from application-owned
scheduling infrastructure:

```java
var executor = Executors.newSingleThreadScheduledExecutor();
executor.scheduleAtFixedRate(reporter::report, 60, 60, TimeUnit.SECONDS);
```

Close the scheduler on shutdown:

```java
executor.shutdown();
```

---

## Step 4 - Add custom registries or database metrics when needed

Use a non-default registry:

```java
var registry = Metrics.createRegistry();

GraphiteReporter reporter = GraphiteReporter.builder()
  .registry(registry)
  .hostname("graphite.example.com")
  .port(2003)
  .build();
```

Include Ebean database metrics directly:

```java
GraphiteReporter reporter = GraphiteReporter.builder()
  .database(database)
  .hostname("graphite.example.com")
  .port(2003)
  .build();
```

Use `registry(MetricSupplier)` when a custom supplier exposes metrics from another
source.

---

## Step 5 - Understand label-tag metric names

Graphite metric paths do not carry tags. When a metric has a `label:<value>` tag,
the reporter appends the label value to the Graphite metric path.

For example:

```text
web.api + label:MyController.myMethod
```

is reported as:

```text
web.api.MyController.myMethod.count
web.api.MyController.myMethod.total
web.api.MyController.myMethod.mean
web.api.MyController.myMethod.max
```

For compatibility with older application timer names, the `app.component` base name
uses the legacy `app.<label>` path:

```text
app.component + label:MyClass.myMethod -> app.MyClass.myMethod.count
```

Non-label tags are ignored by the Graphite reporter because the current Graphite
path format has no tag dimension.

---

## Step 6 - Verify

1. Start the application with the reporter scheduled.
2. Record a few metrics:

```java
Metrics.counter("app.requests").inc();
Metrics.timer("app.service.run").time(service::run);
```

3. Confirm the expected metric paths arrive in Graphite.

## Notes

- `GraphiteReporter` reports the default registry unless `excludeDefaultRegistry()` is used.
- `prefix(...)` should usually include a trailing period, such as `prod.billing.`.
- `timedThresholdMicros(...)` is useful for broad `@Timed` enhancement where many methods
  are not operationally interesting.
- `database(...)`, `registry(...)`, and `registry(MetricSupplier)` can be combined when
  multiple metric sources need to be exported.
