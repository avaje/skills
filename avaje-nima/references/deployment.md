# Avaje Bundle — Deployment (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `nima/add-jvm-docker-jib.md`

# Guide: Add a JVM Docker Image Build with Jib

## Purpose

This guide provides step-by-step instructions for adding a
[Jib](https://github.com/GoogleContainerTools/jib) Maven plugin configuration to an
**avaje-nima** project so that `mvn package` automatically builds a Docker image for
the JVM (non-native) application — without writing a `Dockerfile`.

When asked to *"add a Docker build"*, *"containerise this app"*, or *"add Jib"* to an
avaje-nima project, follow these steps exactly.

---

## Prerequisites

- Docker Desktop (or Docker Engine) running locally.
- JDK 21+ (the project uses Java 25 / virtual threads via Helidon SE).
- Maven 3.9+.

---

## Step 1 — Locate the insertion point in `pom.xml`

Find the `<build><plugins>` section. Identify the last existing `<plugin>` entry
before the closing `</plugins>` tag. The Jib plugin must be added **inside**
`<build><plugins>...</plugins></build>`.

If an `avaje-inject-maven-plugin` entry is present, insert the Jib plugin **after** it.

---

## Step 2 — Insert the Jib plugin XML

Insert the following XML block:

```xml
<plugin> <!-- build "normal jvm" docker image -->
  <groupId>com.google.cloud.tools</groupId>
  <artifactId>jib-maven-plugin</artifactId>
  <version>3.5.1</version>
  <executions>
    <execution>
      <goals>
        <goal>dockerBuild</goal>
      </goals>
      <phase>package</phase>
    </execution>
  </executions>
  <configuration>
    <container>
      <jvmFlags>
        <jvmFlag>-XX:MaxRAMPercentage=70</jvmFlag>
        <jvmFlag>-XX:+UseG1GC</jvmFlag>
        <!-- ZGC alternative (needs explicit heap bounds):
        <jvmFlag>-Xmx400m</jvmFlag>
        <jvmFlag>-Xms250m</jvmFlag>
        <jvmFlag>-XX:+UseZGC</jvmFlag>
        <jvmFlag>-XX:SoftMaxHeapSize=300m</jvmFlag>
        -->
      </jvmFlags>
      <ports>8080</ports>
    </container>
    <from>
      <image>amazoncorretto:25-al2023-headless</image>
    </from>
    <to>
      <image>${project.artifactId}:${project.version}</image>
    </to>
  </configuration>
</plugin>
```

---

## Step 3 — Adjust values if needed

| Setting | Default | When to change |
|---|---|---|
| `<version>3.5.1</version>` | `3.5.1` | Update to the latest stable Jib release if available |
| `amazoncorretto:25-al2023-headless` | Corretto 25 headless | Change the major version to match `maven.compiler.release` in the pom (e.g. `amazoncorretto:21-al2023-headless` for Java 21) |
| `-XX:MaxRAMPercentage=70` | 70% of container memory | Adjust if the service has unusual memory requirements |
| `<ports>8080</ports>` | 8080 | Change to match the application's actual HTTP port |
| `${project.artifactId}:${project.version}` | Maven artifact name + version | Override if a different image name/tag convention is in use |

### Configuration rationale

| Setting | Rationale |
|---|---|
| `<goal>dockerBuild</goal>` | Builds to local Docker daemon; use `build` instead to push directly to a registry |
| `<phase>package</phase>` | Runs on `mvn package` — keeps image build part of the standard lifecycle |
| `amazoncorretto:25-al2023-headless` | Amazon Corretto JDK 25 on Amazon Linux 2023; `headless` omits AWT/GUI libs |
| `-XX:MaxRAMPercentage=70` | Heap scales with container memory limit — no explicit `-Xmx` needed |
| `-XX:+UseG1GC` | Good general-purpose GC; low-pause, well-tuned for server workloads |
| `<ports>8080</ports>` | Matches Helidon's default HTTP port |

> **ZGC alternative:** Replace the G1GC flags with the commented-out ZGC block if
> ultra-low GC pause times are needed and you are comfortable setting explicit heap
> bounds. ZGC requires `-Xmx`.

---

## Step 4 — Verify the addition

Check that:
1. The `<plugin>` block is inside `<build><plugins>` and **not** inside any `<profile>`.
2. There is no duplicate `jib-maven-plugin` entry in the default build (a separate Jib
   entry may exist inside the `native` profile — that is expected and correct).
3. The XML is well-formed (no unclosed tags, correct nesting).

---

## Step 5 — Confirm the build works

```bash
mvn package
```

The build should complete and a Docker image named `<artifactId>:<version>` should
appear in the local daemon:

```bash
docker images | grep <artifactId>
```

Run the container to verify it starts:

```bash
docker run --rm -p 8080:8080 <artifactId>:<version>
```

Test with curl:

```bash
curl http://localhost:8080/health
```

---

## Controlling memory at runtime

Because the JVM flags use `MaxRAMPercentage` rather than a fixed heap size, you
control the actual heap size by setting the container's memory limit:

```bash
# Allow 512 MB → JVM uses up to ~358 MB heap
docker run --rm -p 8080:8080 --memory=512m <artifactId>:<version>
```

---

## Notes

- The `dockerBuild` goal pushes to the **local Docker daemon**. To push to a remote
  registry, replace `dockerBuild` with `build` and add
  `<to><image>registry.example.com/…</image></to>`.
- The JVM flags use `MaxRAMPercentage` so the heap scales with the container's memory
  limit — no explicit `-Xmx` is required.
- For GraalVM **native image** Docker builds, see
  [`add-native-docker-jib.md`](add-native-docker-jib.md) — that is handled separately
  via the `native` Maven profile.

---

## Version compatibility

| Component | Tested version |
|---|---|
| `jib-maven-plugin` | 3.5.1 |
| Base image | `amazoncorretto:25-al2023-headless` |
| Java | 25 |
| Helidon SE | 4.4.0 |
| avaje-nima | 1.8 |

---

## References

- Jib documentation: https://github.com/GoogleContainerTools/jib/tree/master/jib-maven-plugin
- Amazon Corretto images: https://hub.docker.com/_/amazoncorretto
- Native image Docker build: [`add-native-docker-jib.md`](add-native-docker-jib.md)

---

## Source: `nima/add-native-docker-jib.md`

# Guide: Add a Native Image Docker Build with Jib

## Purpose

This guide provides step-by-step instructions for adding a `native` Maven profile to
an **avaje-nima** project that:
1. Compiles the application to a **GraalVM native executable** (no JVM at runtime)
2. Packages that executable into a **Docker image** using [Jib](https://github.com/GoogleContainerTools/jib)

The result is a small, fast-starting container. Activate it with:

```bash
mvn package -Pnative
```

When asked to *"add a native Docker build"*, *"add GraalVM native image support"*, or
*"add the native profile"* to an avaje-nima project, follow these steps exactly.

---

## Prerequisites

- **GraalVM JDK 25** (or matching your `maven.compiler.release`). Install via [SDKMAN](https://sdkman.io/):

  ```bash
  sdk install java 25.0.2-graal
  sdk use java 25.0.2-graal
  ```

  Confirm GraalVM is active:

  ```bash
  mvn --version   # JVM line should mention GraalVM
  ```

- Docker Desktop (or Docker Engine) running locally.
- Maven 3.9+.
- The JVM Docker build is **not** required first, but the same `pom.xml` can contain both.

### Native vs. JVM image comparison

| | JVM image | Native image |
|---|---|---|
| Startup time | ~1–2 s | ~50–200 ms |
| Memory footprint | Higher (JIT profiling metadata) | Lower |
| Build time | Fast | Slow (3–10 minutes) |

Native image suits latency-sensitive or cost-sensitive deployments where fast startup
and low idle memory matter more than build time.

---

## Step 1 — Confirm GraalVM is available

The native build requires GraalVM JDK. Note this when generating instructions — the
developer must run `mvn package -Pnative` with GraalVM active (e.g. via
`sdk use java 25.0.2-graal`).

---

## Step 2 — Locate the insertion point in `pom.xml`

Find the `<profiles>` section (or the closing `</project>` tag if none exists). The
entire native configuration lives inside a single `<profile>` block:

```xml
<profiles>
  <profile>
    <id>native</id>
    ...
  </profile>
</profiles>
```

If `<profiles>` does not exist, add it before `</project>`.

---

## Step 3 — Insert the native profile XML

Insert the following complete profile. **Replace `com.example.Main`** with the
project's actual main class (find it by searching for `public static void main` or
`void main()` in the source tree, or look for an existing `<mainClass>` reference in
the pom).

```xml
<profile>
  <id>native</id>
  <build>
    <plugins>

      <plugin> <!-- compile to a native executable -->
        <groupId>org.graalvm.buildtools</groupId>
        <artifactId>native-maven-plugin</artifactId>
        <version>0.11.4</version>
        <extensions>true</extensions>
        <executions>
          <execution>
            <id>build-native</id>
            <goals>
              <goal>compile-no-fork</goal>
            </goals>
            <phase>package</phase>
            <configuration>
              <mainClass>com.example.Main</mainClass>
            </configuration>
          </execution>
        </executions>
        <configuration>
          <buildArgs>
            <buildArg>--emit build-report</buildArg>
            <buildArg>--no-fallback</buildArg>
            <buildArg>-march=compatibility</buildArg>
            <buildArg>--static-nolibc</buildArg>
          </buildArgs>
        </configuration>
      </plugin>

      <plugin> <!-- build the native image docker container -->
        <groupId>com.google.cloud.tools</groupId>
        <artifactId>jib-maven-plugin</artifactId>
        <version>3.5.1</version>
        <executions>
          <execution>
            <goals>
              <goal>dockerBuild</goal>
            </goals>
            <phase>package</phase>
          </execution>
        </executions>
        <dependencies>
          <dependency>
            <groupId>com.google.cloud.tools</groupId>
            <artifactId>jib-native-image-extension-maven</artifactId>
            <version>0.1.0</version>
          </dependency>
        </dependencies>
        <configuration>
          <pluginExtensions>
            <pluginExtension>
              <implementation>com.google.cloud.tools.jib.maven.extension.nativeimage.JibNativeImageExtension</implementation>
              <properties>
                <imageName>${project.artifactId}</imageName>
              </properties>
            </pluginExtension>
          </pluginExtensions>
          <container>
            <mainClass>com.example.Main</mainClass>
            <ports>8080</ports>
          </container>
          <from> <!-- UBI micro image with glibc support -->
            <image>redhat/ubi10-micro:10.1-1762215812</image>
          </from>
          <to>
            <image>${project.artifactId}-native:${project.version}</image>
          </to>
        </configuration>
      </plugin>

    </plugins>
  </build>
</profile>
```

---

## Step 4 — Adjust values if needed

| Setting | Default | When to change |
|---|---|---|
| `<mainClass>com.example.Main</mainClass>` | — | **Always replace** with the project's actual main class; appears in **both** plugins |
| `native-maven-plugin` version `0.11.4` | `0.11.4` | Update to the latest compatible release |
| `jib-maven-plugin` version `3.5.1` | `3.5.1` | Match the version used in the default JVM build |
| `redhat/ubi10-micro:10.1-1762215812` | UBI 10 micro | Use a newer digest tag if available; keep `ubi*-micro` for glibc support |
| `<ports>8080</ports>` | 8080 | Change to match the application's actual HTTP port |
| Image tag suffix `-native` | `-native` | Keep this suffix to distinguish from the JVM image |

### `native-maven-plugin` build args

| Arg | Purpose |
|---|---|
| `--no-fallback` | Fail the build if native compilation fails — do not silently fall back to JVM mode |
| `-march=compatibility` | Generate code compatible with a broad range of x86-64 CPU microarchitectures |
| `--static-nolibc` | Produce a mostly-static binary: all libraries linked statically **except** glibc, which is linked dynamically |
| `--emit build-report` | Write a `target/native/nativeCompile/build-report.html` for inspection |

### Jib configuration

| Setting | Rationale |
|---|---|
| `JibNativeImageExtension` | Tells Jib to package the native binary produced by `native-maven-plugin` instead of a JAR |
| `<imageName>${project.artifactId}</imageName>` | Name of the binary inside the container |
| `redhat/ubi10-micro` base image | Minimal RHEL UBI 10 image; provides glibc required by `--static-nolibc` binaries |
| `<mainClass>` in `<container>` | Must match the `mainClass` in `native-maven-plugin` |

> **Why UBI micro?** The `--static-nolibc` flag links everything statically except
> glibc. A distroless or `scratch` base would fail at runtime because glibc is missing.
> UBI micro provides glibc in a minimal footprint.

---

## Step 5 — Verify the addition

Check that:
1. The `<profile id="native">` block is inside `<profiles>` at the top level of
   `<project>`, **not** inside `<build>`.
2. `<mainClass>` is set to the same value in **both** `native-maven-plugin` and Jib's
   `<container>` section.
3. There is no duplicate `jib-maven-plugin` entry inside this profile.
4. The XML is well-formed.

---

## Step 6 — Confirm the build works

```bash
mvn package -Pnative
```

The build compiles a native binary and then builds a Docker image. This typically
takes **3–10 minutes**. Verify:

```bash
docker images | grep native
```

Run the container:

```bash
docker run --rm -p 8080:8080 <artifactId>-native:<version>
```

Test with curl:

```bash
curl http://localhost:8080/health
```

Startup should complete in under 200 ms.

---

## Relationship to the JVM Docker build

The `native` profile is **additive** — it does not replace the default JVM build.
Both coexist in the same `pom.xml`:

| Build command | Image produced | When to use |
|---|---|---|
| `mvn package` | `<artifactId>:<version>` | Development, fast iterations |
| `mvn package -Pnative` | `<artifactId>-native:<version>` | Production, low-latency deployments |

See [`add-jvm-docker-jib.md`](add-jvm-docker-jib.md) for the JVM build configuration.

---

## Notes

- The `native` profile is **additive** — it does not replace the default JVM build.
- The `--static-nolibc` build arg creates a mostly-static binary that links glibc
  dynamically. The `ubi10-micro` base image provides glibc, which is why it is chosen
  over `scratch` or distroless images.
- No `<jvmFlags>` are needed in the Jib container config — the container runs a native
  binary, not a JVM process.
- The `JibNativeImageExtension` locates the binary produced by `native-maven-plugin`
  automatically; the `<imageName>` property sets the binary's name inside the image.

---

## Version compatibility

| Component | Tested version |
|---|---|
| `native-maven-plugin` | 0.11.4 |
| `jib-maven-plugin` | 3.5.1 |
| `jib-native-image-extension-maven` | 0.1.0 |
| Base image | `redhat/ubi10-micro:10.1-1762215812` |
| GraalVM / Java | 25 |
| Helidon SE | 4.4.0 |
| avaje-nima | 1.8 |

---

## References

- Jib native image extension: https://github.com/GoogleContainerTools/jib-extensions/tree/master/first-party/jib-native-image-extension-maven
- GraalVM native build tools: https://graalvm.github.io/native-build-tools/latest/maven-plugin.html
- Red Hat UBI micro images: https://catalog.redhat.com/software/containers/ubi10/ubi-micro
- JVM Docker build: [`add-jvm-docker-jib.md`](add-jvm-docker-jib.md)

---

## Source: `nima/native-image.md`

# GraalVM Native Images

How to build nima applications as native images.

## Setup

Add native image plugin:

```xml
<plugin>
  <groupId>org.graalvm.buildtools</groupId>
  <artifactId>native-maven-plugin</artifactId>
  <version>0.10.0</version>
</plugin>
```

## Building Native Image

```bash
mvn -Pnative clean package
```

This produces `target/myapp` executable.

## Performance

Native images provide:

- **Startup**: < 50ms (vs 2-5 seconds for JVM)
- **Memory**: 30-50MB (vs 200-500MB for JVM)
- **No warm-up**: Full performance from first request

## Native Image Dockerfile

```dockerfile
FROM ghcr.io/graalvm/native-image:latest as build
WORKDIR /build
COPY . .
RUN mvn -Pnative clean package

FROM debian:bookworm-slim
COPY --from=build /build/target/myapp /app/myapp
EXPOSE 8080
ENTRYPOINT ["/app/myapp"]
```

## Configuration in Native Image

All configuration must be known at build time or via environment variables:

```yaml
server:
  port: ${SERVER_PORT:8080}
```

## Next Steps

- See [native image guide](../../../docs/guides/native-image.md) for detailed info
- See [troubleshooting](troubleshooting.md)

---

## Source: `nima/deployment.md`

# Deployment

How to deploy nima applications to Docker and Kubernetes.

## Docker Deployment

Create a `Dockerfile`:

```dockerfile
FROM openjdk:21-slim
WORKDIR /app
COPY target/myapp.jar app.jar
EXPOSE 8080
ENV JAVA_OPTS="-XX:+UseG1GC"
ENTRYPOINT ["java", "$JAVA_OPTS", "-jar", "app.jar"]
```

Build and run:

```bash
docker build -t myapp:latest .
docker run -p 8080:8080 myapp:latest
```

## Kubernetes Deployment

Create `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        ports:
        - containerPort: 8080
        env:
        - name: SERVER_PORT
          value: "8080"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```

Deploy:

```bash
kubectl apply -f deployment.yaml
```

## Environment-Specific Configuration

Use different profiles for each environment:

- `application-dev.yaml` - Development
- `application-staging.yaml` - Staging  
- `application-prod.yaml` - Production

Set via environment variable:

```bash
export CONFIG_PROFILE=prod
java -jar myapp.jar
```

## Health Checks

Implement health endpoints:

```java
@Controller
@Path("/health")
public class HealthController {
  
  @Get
  public HealthResponse health() {
    return new HealthResponse("UP");
  }
}
```

## Next Steps

- Build [native images](native-image.md) for faster startup
- See [troubleshooting](troubleshooting.md)

---

## Source: `nima/troubleshooting.md`

# Troubleshooting

Common issues and solutions for nima applications.

## Controller Routes Not Found

**Symptom**: 404 for controller endpoints

**Solution**:
1. Verify `@Controller` annotation present
2. Check `@Path` annotation spelling
3. Ensure HTTP method annotation (`@Get`, `@Post`, etc.)
4. Check path variable syntax: `:id` not `{id}`

## Dependency Injection Errors

**Symptom**: `No bean found for type X`

**Solution**:
1. Verify `@Singleton` or `@Bean` annotation
2. Check for circular dependencies
3. Ensure interfaces have implementations
4. Use `@Named` qualifier if multiple implementations

## Validation Not Working

**Symptom**: Invalid data accepted

**Solution**:
1. Add bean validation annotations to request class
2. Call `validator.validate()` in controller
3. Check exception handler catches `ConstraintViolationException`

## Filters Not Called

**Symptom**: Filter logic never executes

**Solution**:
1. Verify filter registered with server
2. Check filter path conditions
3. Ensure `chain.doFilter()` called (except for final response)
4. Check filter ordering

## Performance Issues

**Symptom**: Slow request handling

**Solution**:
1. Profile with JFR (Java Flight Recorder)
2. Check for blocking I/O in handlers
3. Use connection pooling for database
4. Enable async operations for I/O
5. Build native image for startup performance

## Getting Help

- GitHub: https://github.com/avaje/avaje-nima
- Discord: https://discord.gg/Qcqf9R27BR
- Docs: https://avaje.io/nima/
