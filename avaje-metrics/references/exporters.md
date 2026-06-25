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
| `avaje-metrics-otel-trace` | you want traced timers / spans |
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

- the goal is spans from `buildTraced()`, `buildRootTraced()`, or `@Timed(span = Timed.SpanMode.CHILD)` / `ROOT`

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
  .deploymentEnvironmentName("production")
  .resourceAttributes("business.domain=fleet,business.platform=ship")
  .traceSampleRatio(0.05)
  .meterInterval(Duration.ofSeconds(60))
  .traceInterval(Duration.ofSeconds(10))
  .buildAndRegisterGlobal();
```

This is the best default when the application wants both OTEL metrics export and traced
timer support with minimal setup code.

When using this we do **NOT** need Step 3 or Step 4.

### Choose gRPC or HTTP/protobuf export

By default, `MetricsOpenTelemetry` uses OTLP gRPC and passes `endpoint(...)`
directly to the metric and span exporters. The default endpoint is
`http://localhost:4317`.

For OTLP HTTP/protobuf, select `HTTP_PROTOBUF` and provide the HTTP base endpoint:

```java
var openTelemetry = MetricsOpenTelemetry.builder()
  .protocol(MetricsOpenTelemetry.Protocol.HTTP_PROTOBUF)
  .endpoint("http://otel-collector:4318")
  .serviceName("my-service")
  .buildAndRegisterGlobal();
```

In HTTP/protobuf mode, the builder appends `/v1/metrics` for metric export and
`/v1/traces` for trace export. If the application needs signal-specific endpoints,
headers, compression, or timeout configuration, keep using explicit
`metricExporter(...)` and `spanExporter(...)` instances.

### Register global OpenTelemetry once and early

`buildAndRegisterGlobal()` registers the OpenTelemetry SDK with
`GlobalOpenTelemetry`. Call it in one place only.

If another library reads `GlobalOpenTelemetry` during startup, create this
OpenTelemetry instance before that library is initialized. For example,
`ebean-opentelemetry` resolves its tracer while Ebean databases are configured, so
the OpenTelemetry bean should be created before Ebean `Database` beans.

With Avaje Inject, model this as a real dependency:

```java
@Bean
Database database(OpenTelemetry openTelemetry, Configuration config) {
  return Database.builder()
    .name("db")
    .dataSourceBuilder(dataSource(config))
    .build();
}
```

Do not call `buildAndRegisterGlobal()` from multiple factories or helper classes.
If the application already owns SDK creation, use `avaje-metrics-otel-producer`
instead of the convenience global-registration path.

### Resource attributes

For Lambda or other non-Kubernetes deployments, add resource attributes with the builder:

```java
var openTelemetry = MetricsOpenTelemetry.builder()
  .serviceName("backport")
  .deploymentEnvironmentName("production")
  .serviceNamespace("tracking")
  .resourceAttributes("business.domain=fleet,business.subdomain=tracking,business.platform=ship")
  .buildAndRegisterGlobal();
```

The convenience module also reads:

- system property `otel.resource.attributes`
- environment variable `OTEL_RESOURCE_ATTRIBUTES`

using the standard comma-separated `key=value,key2=value2` format. The system property wins over
the environment variable.

The service name can also be supplied using the standard `otel.service.name` system property or
`OTEL_SERVICE_NAME` environment variable. Explicit builder attributes override configured resource
attributes, `otel.service.name` / `OTEL_SERVICE_NAME` override `service.name` from resource
attributes, and `serviceName(...)` overrides all configured service names.

For the full set of OTel SDK environment variables and system properties read by the
convenience module (endpoint, timeouts, intervals, deployment environment name) see
[Configure OpenTelemetry environment variables](configure-otel-environment.md).

### Trace sampling

Without explicit sampler configuration, the OpenTelemetry SDK default is
`parentBased(alwaysOn)`. For an avaje-nima service using `NimaOtelFilter`, requests
without incoming trace headers create root HTTP SERVER spans, so this default samples
all of those request traces.

For Kubernetes services, configure a parent-based trace-id ratio:

```java
var openTelemetry = MetricsOpenTelemetry.builder()
  .endpoint("http://otel-collector:4317")
  .serviceName("orders")
  .deploymentEnvironmentName("production")
  .traceSampleRatio(0.05)
  .buildAndRegisterGlobal();
```

This samples new root request traces at 5% while respecting incoming sampled or
unsampled parent decisions. Traced timers inside sampled requests are exported as
child spans; traced timers inside unsampled requests are not.

The same configuration can be supplied using standard OpenTelemetry names:

```bash
OTEL_TRACES_SAMPLER=parentbased_traceidratio
OTEL_TRACES_SAMPLER_ARG=0.05
```

or:

```bash
java \
  -Dotel.traces.sampler=parentbased_traceidratio \
  -Dotel.traces.sampler.arg=0.05 \
  -jar app.jar
```

For Lambda-style applications, configure the SDK sampler in the same way:

```java
var openTelemetry = MetricsOpenTelemetry.builder()
  .serviceName("orders-lambda")
  .deploymentEnvironmentName("production")
  .traceSampleRatio(0.10)
  .buildAndRegisterGlobal();
```

This controls sampling when Lambda instrumentation or `@Timed(span = Timed.SpanMode.ROOT)`
starts a root span. Use `ROOT` on the top-level handler boundary, then use child traced
timers inside it. `@Timed(span = Timed.SpanMode.CHILD)` and `buildTraced()` remain no-op
when there is no current recording span.

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

Use `buildRootTraced()` for a top-level boundary that should initiate sampling when no
recording span is current.

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
- For **AWS Lambda** (or other freeze-on-exit serverless runtimes) follow
  [add-open-telemetry-lambda.md](add-open-telemetry-lambda.md) — the
  `enableWaitIfRunning()` builder option is essential to avoid losing metrics on
  Lambda freeze.
- `avaje-metrics-otel-producer` is the right choice when the application already owns the SDK.
- `avaje-metrics-otel-trace` is trace-only.
- `avaje-metrics-otel-reporter` is a separate scheduled path and should be used intentionally.
- For full builder and mapping details, see the module READMEs:
  - [metrics-otel/README.md](../../metrics-otel/README.md)
  - [metrics-otel-producer/README.md](../../metrics-otel-producer/README.md)
  - [metrics-otel-trace/README.md](../../metrics-otel-trace/README.md)
  - [metrics-otel-reporter/README.md](../../metrics-otel-reporter/README.md)

---

## Source: `metrics/add-open-telemetry-lambda.md`

# Guide: Add OpenTelemetry Export — AWS Lambda

## Purpose

This guide provides step-by-step instructions for exporting **avaje-metrics** data
(and related traces) to OpenTelemetry from an **AWS Lambda** function (or any similar
"freeze-on-exit" serverless runtime).

When asked to *"export Lambda metrics to OpenTelemetry"*, *"why are my Lambda metrics
missing in Grafana / Mimir / Tempo"*, or *"add `enableWaitIfRunning()` to a Lambda
function"*, follow these steps exactly.

This guide is the Lambda-specific companion to
[add-open-telemetry-export.md](add-open-telemetry-export.md). Read that one first if
you have not yet decided which OTEL module to use.

---

## Overview

AWS Lambda freezes the worker between invocations. Two consequences matter for
OpenTelemetry:

1. **Freeze-on-exit cuts in-flight exports mid-flight.** The default
   `PeriodicMetricReader` and `BatchSpanProcessor` background threads ship telemetry
   asynchronously. If the runtime suspends while an OTLP HTTP/gRPC export is in
   progress, the request is interrupted. The export *may* complete on a later thaw,
   minutes later — or be lost.

2. **Low-traffic Lambdas starve the periodic reader.** A Lambda invoked once a
   minute spends most of its life frozen. The periodic reader cannot tick on a
   reliable schedule, so metrics produced inside an invocation may never be exported
   before the runtime is suspended again.

`avaje-metrics-otel` solves both with a single builder call:

```java
.enableWaitIfRunning()
```

This wraps the metric and span exporters to track in-flight exports and provides a
`TelemetryWaiter` that, at the **end** of an invocation:

1. **Waits** briefly if a scheduled background export is currently in progress, and
2. **Force-flushes** telemetry that has gone stale (no successful background export
   within the configured `flushIfStale` window).

In busy environments the periodic reader keeps `lastSuccess` fresh and the stale
forceFlush is a no-op. In low-traffic environments the stale forceFlush ships data on
the invocation thread before the runtime is suspended again.

The pattern mirrors the avaje-metrics StatsD `waitIfRunning()` pattern: most
invocations have zero overhead; only an invocation that overlaps an active export, or
arrives after a long quiet period, pays a brief synchronous cost.

---

## Step 1 — Add the dependency

```xml
<dependency>
  <groupId>io.avaje</groupId>
  <artifactId>avaje-metrics-otel</artifactId>
  <version>${version}</version>
</dependency>
```

This is the same module as the standard OTEL recipe — Lambda support is built in.

---

## Step 2 — Build the SDK once at handler-class init

Build the `OpenTelemetrySdk` and `TelemetryWaiter` **once** when the Lambda handler
class is loaded — not per invocation. The Lambda runtime reuses the same handler
instance across invocations on the same warm worker.

```java
import io.avaje.metrics.otel.MetricsOpenTelemetry;
import io.avaje.metrics.otel.TelemetryWaiter;
import io.opentelemetry.sdk.OpenTelemetrySdk;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

public class OrdersHandler {

  private static final TelemetryWaiter WAITER;

  static {
    var result = MetricsOpenTelemetry.builder()
        .protocol(MetricsOpenTelemetry.Protocol.HTTP_PROTOBUF)
        .endpoint(System.getenv("OTEL_EXPORTER_OTLP_ENDPOINT"))
        .serviceName("orders-lambda")
        .deploymentEnvironmentName(System.getenv("ENV"))
        .exportTimeout(Duration.ofSeconds(5))
        .connectTimeout(Duration.ofSeconds(2))
        .enableWaitIfRunning()
            .timeout(Duration.ofSeconds(35))
            // .flushIfStale(Duration.ofSeconds(60))  // optional
            .buildAndRegisterGlobal();

    WAITER = result.waiter();
  }

  public Response handle(Request request) {
    try {
      return process(request);
    } finally {
      WAITER.waitIfRunning();
    }
  }
}
```

The two critical pieces are:

- `enableWaitIfRunning()` — wraps the exporters and produces the waiter.
- `WAITER.waitIfRunning()` in a `finally` block — runs at the end of every
  invocation, blocks briefly only if needed.

If you have multiple Lambda handler classes in the same deployment artifact (e.g. an
event handler **and** a schedule handler), build the SDK in a shared class so all
handlers use the same `TelemetryWaiter` instance.

> **Tip:** Most of the per-environment values above (`endpoint`, `deploymentEnvironmentName`,
> `serviceName`) can be supplied via standard OTel SDK environment variables instead of
> explicit builder calls. See
> [Configure OpenTelemetry environment variables](configure-otel-environment.md) — this
> keeps the handler code identical across environments and the values configurable from
> CloudFormation / Lambda env vars.

---

## Step 3 — Understand the Lambda-friendly defaults

Calling `enableWaitIfRunning()` switches two defaults to Lambda-friendly values, but
only when the caller has not already set them explicitly:

| Setting              | Standalone default | Lambda default               | Why |
|----------------------|--------------------|------------------------------|-----|
| `meterInterval`      | 60 seconds         | **30 seconds**               | Faster ticks reduce stale-flush frequency in low-traffic envs. |
| `flushIfStale`       | n/a                | **2 × meterInterval** (60 s) | Forgives one missed tick + jitter; flushes when two or more are missed. |
| `WaiterBuilder.timeout` | 5 seconds       | 5 seconds (set higher)       | Lambda freezes mid-export are common — recommend **35 s**. |
| `connectTimeout`     | unset (10 s SDK)   | recommend **2 s**            | Fail fast on networking issues so they don't burn invocation time. |
| `exportTimeout`      | unset (10 s SDK)   | recommend **5 s**            | Same. |

You can override any of these. Pass `Duration.ZERO` to `flushIfStale(...)` to disable
the stale forceFlush and use only the in-flight wait behaviour.

### How `flushIfStale` works

The waiter records `lastSuccessAtMillis` whenever a wrapped export completes
successfully. At the end of `waitIfRunning()`:

1. If `(now - lastSuccess) > flushIfStale` for metrics, call `SdkMeterProvider.forceFlush()`.
2. If `(now - lastSuccess) > flushIfStale` for spans, call `SdkTracerProvider.forceFlush()`.

`lastSuccess` starts at `0`, so the **first invocation after cold start** always
triggers a forceFlush — this is intentional, and ships startup metrics promptly.

---

## Step 4 — Wiring with dependency injection

> **⚠ Ordering matters.** The `@Bean` method that returns `TelemetryWaiter` must
> declare `OpenTelemetry` as a parameter so the DI container invokes
> `openTelemetry()` first. Without that parameter, the waiter bean may be created
> before the SDK is built, returning a no-op waiter that silently never flushes.

### Spring

```java
@Configuration
public class MetricsConfig {

  @Bean
  OpenTelemetry openTelemetry() {
    var result = MetricsOpenTelemetry.builder()
        .endpoint(System.getenv("OTEL_EXPORTER_OTLP_ENDPOINT"))
        .protocol(MetricsOpenTelemetry.Protocol.HTTP_PROTOBUF)
        .serviceName("orders-lambda")
        .exportTimeout(Duration.ofSeconds(5))
        .enableWaitIfRunning()
            .timeout(Duration.ofSeconds(35))
            .buildAndRegisterGlobal();
    this.waiter = result.waiter();
    return result.sdk();
  }

  @Bean
  TelemetryWaiter telemetryWaiter(OpenTelemetry openTelemetry) {
    return waiter;   // captured above; OpenTelemetry param forces this to run after openTelemetry()
  }

  private TelemetryWaiter waiter;
}
```

### avaje-inject

```java
@Factory
public class MetricsConfig {

  private TelemetryWaiter waiter;

  @Bean
  OpenTelemetry openTelemetry() {
    var result = MetricsOpenTelemetry.builder()
        .endpoint(Config.getNullable("otel.endpoint"))
        .protocol(MetricsOpenTelemetry.Protocol.HTTP_PROTOBUF)
        .serviceName("orders-lambda")
        .exportTimeout(Duration.ofSeconds(5))
        .enableWaitIfRunning()
            .timeout(Config.getInt("otel.waitTimeoutMillis", 35_000), TimeUnit.MILLISECONDS)
            .buildAndRegisterGlobal();
    this.waiter = result.waiter();
    return result.sdk();
  }

  @Bean
  TelemetryWaiter telemetryWaiter(OpenTelemetry openTelemetry) {
    return waiter;   // OpenTelemetry param forces this to run after openTelemetry()
  }
}
```

In the handler:

```java
public class OrdersLambda {

  private final TelemetryWaiter waiter;
  // ... other deps

  public Response handle(Request request) {
    try {
      return process(request);
    } finally {
      waiter.waitIfRunning();
    }
  }
}
```

When OTEL is disabled (e.g. in a local dev profile that does not configure an
endpoint), inject `TelemetryWaiter.noop()` instead — the same handler code keeps
working with zero overhead.

---

## Step 5 — Verify

Enable DEBUG logging on the `io.avaje.metrics.otel` logger (or your application's
matching package) so you can see the export lifecycle. With `avaje-simple-logger`:

```properties
log.level.io.avaje.metrics.otel=DEBUG
```

You should see a sequence like this on a healthy warm invocation:

```
DEBUG io.avaje.metrics.otel - OTLP metric export starting count:90
DEBUG io.avaje.metrics.otel - OTLP metric export completed count:90 elapsedMs:219
```

On the first invocation after cold start (or after a quiet period):

```
DEBUG io.avaje.metrics.otel - OTLP metric forceFlush triggered (stale)
DEBUG io.avaje.metrics.otel - OTLP metric forceFlush completed elapsedMs:585
```

If `waitIfRunning()` had to wait for an in-flight tick:

```
DEBUG io.avaje.metrics.otel - Waiting up to 35000ms for in-flight OTLP metric export
```

Failures and timeouts are logged at WARN:

```
WARN  io.avaje.metrics.otel - OTLP metric export failed count:90 elapsedMs:5001 ...
WARN  io.avaje.metrics.otel - Timed out waiting 35000ms for OpenTelemetry metric export to complete
```

---

## Notes

### Diagnostics

- **No metrics in dashboard, no logs about exports**
  Check the OTEL endpoint is reachable from the Lambda (VPC/security groups). The
  handler will time out if `exportTimeout` is unset — set it explicitly to a value
  smaller than the Lambda timeout.

- **`Timed out waiting` lines**
  Bump `WaiterBuilder.timeout(...)`. 35 seconds is a good starting point for Lambdas
  configured with a 60-second timeout.

- **Cold-start metrics arrive but warm-invocation metrics are missing**
  The periodic reader is starved — set or shorten `flushIfStale` (default already
  60 s with the Lambda preset).

- **Multi-minute completion latencies**
  Almost always the freeze-on-exit problem. The fix is exactly this guide.

### Cold-start cost

Building `MetricsOpenTelemetry` and the SDK in `static` initializer or DI factory adds
to cold-start time. Typical cold start cost is in the order of 50-200 ms depending on
the configured exporters.

### Tradeoffs

- `flushIfStale` adds a synchronous export to the **first invocation after cold
  start** (because `lastSuccessAtMillis` starts at 0). This is usually desirable —
  startup metrics ship promptly — but it does add a few hundred ms to the first
  warm-up invocation. Pass `Duration.ZERO` to disable.
- `connectTimeout` and `exportTimeout` are passed through to the default OTLP
  HTTP/gRPC exporters only. They have no effect when a custom exporter is supplied
  via `metricExporter(...)` or `spanExporter(...)`.
- `TelemetryWaiter.noop()` is safe to use as a fallback when OTEL is disabled — it
  performs no waiting and no flushing.

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
