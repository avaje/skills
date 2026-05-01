# Avaje Bundle — Setup (Flattened)

> Flattened bundle. Content from source markdown guides is inlined below.

---

## Source: `nima/archetype-getting-started.md`

# Avaje Nima Archetype Guide for AI Agents

**Target Audience:** AI systems (Claude, Copilot, ChatGPT, etc.)
**Purpose:** Scaffold new avaje-nima REST services programmatically
**Last Updated:** 2026-04-12
**Archetype Version:** 1.9-RC1

---

## Quick Reference

| Action | Command |
|--------|---------|
| **Generate interactively** | `mvn archetype:generate -DarchetypeGroupId=io.avaje.archetype -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest -DarchetypeVersion=1.9-RC1` |
| **Generate in batch mode** | See [Batch Generation](#batch-generation) section |
| **Compile generated project** | `cd <project-dir> && mvn compile` |
| **Run tests** | `mvn test` |
| **Start server** | `mvn exec:java -Dexec.mainClass=<package>.Main` |
| **Expected port** | 8080 (configurable) |

---

## What This Archetype Provides

The `io.avaje.archetype:avaje-nima-archetype-minimal-rest` archetype generates a minimal, working REST service with:

- **Framework**: Helidon Níma web server + avaje-inject dependency injection
- **Included Libraries**: avaje-jsonb for JSON serialization, avaje-logger for logging
- **Annotation Processing**: avaje-nima-generator automatically wires dependency injection and HTTP routing
- **Generated Endpoints**:
  - `GET /hi` → Returns `"hi"` as `text/plain`
  - `GET /hi/data` → Returns JSON `{"message":"...", "timestamp":...}`
- **Test Framework**: Integration tests using `@InjectTest` with embedded server
- **Build Profiles**: Native executable (`-Pnative`) and fat-jar (`-Pfat-jar`) support
- **Java Version**: 25 (minimum)

---

## Prerequisites

Before using this archetype, verify:

| Requirement | Minimum Version | How to Verify |
|-------------|-----------------|---------------|
| Maven | 3.9 | `mvn --version` |
| Java JDK | 25 | `java -version` |
| Git (optional) | Any | `git --version` |

**Installation:**
- Maven: https://maven.apache.org/install.html
- Java 25: https://www.oracle.com/java/technologies/ or use SDKMAN (`sdk install java 25`)

### Check for Latest Archetype Version

Before generating, verify latest available version:

**Option 1 - Recommended for AI Agents:** Simply omit the version parameter and Maven will use the latest:

```bash
mvn archetype:generate \
  -DarchetypeGroupId=io.avaje.archetype \
  -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest \
  -DgroupId=com.example \
  -DartifactId=my-service \
  -Dpackage=com.example.service \
  -B
```

**Option 2 - Check available versions:** Run interactive generation, which will show available versions:

```bash
mvn archetype:generate \
  -DarchetypeGroupId=io.avaje.archetype \
  -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest
```

When prompted, review the suggested version (usually latest) or select a different one.

**Option 3 - Search Maven Central (for published versions):**

```bash
# Simpler version detection
mvn dependency:tree -q 2>/dev/null | grep avaje-nima-archetype || \
  echo "No local cache. Run interactive generation to see available versions."
```

**Available Versions Summary (as of 2026-04-12):**
- `1.9-RC1` (latest, release candidate)

**Recommendation:** For new projects, omit `-DarchetypeVersion` to automatically use the latest available version.

---

## Generation Methods

### Interactive Generation

Run the archetype and respond to prompts:

```bash
mvn archetype:generate \
  -DarchetypeGroupId=io.avaje.archetype \
  -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest \
  -DarchetypeVersion=1.9-RC1
```

**Or omit version to use latest:**

```bash
mvn archetype:generate \
  -DarchetypeGroupId=io.avaje.archetype \
  -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest
```

**Prompts:**
```
Define value for property 'groupId': com.example
Define value for property 'artifactId': my-service
Define value for property 'version' [1.0-SNAPSHOT]: 1.0-SNAPSHOT
Define value for property 'package' [com.example]: com.example.service
```

**Output:**
```
Project created from Archetype in dir: /path/to/my-service
```

### Batch Generation (Non-Interactive)

Use the `-B` (batch) flag with all parameters defined:

```bash
mvn archetype:generate \
  -DarchetypeGroupId=io.avaje.archetype \
  -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest \
  -DarchetypeVersion=1.9-RC1 \
  -DgroupId=com.example \
  -DartifactId=my-service \
  -Dversion=1.0-SNAPSHOT \
  -Dpackage=com.example.service \
  -B
```

**Key Parameters:**
- `groupId`: Reverse-domain package prefix (e.g., `com.company`)
- `artifactId`: Project directory name and JAR name (e.g., `my-service`)
- `version`: Semantic version (e.g., `1.0.0`, `1.0-SNAPSHOT`)
- `package`: Java package for generated classes (defaults to `groupId` if omitted)
- `-B`: Batch mode flag (no interactive prompts)

---

## Generated Project Structure

After generation, the project structure is:

```
my-service/
├── pom.xml                                 # Maven configuration
├── README.md                               # Project-specific README
└── src/
    ├── main/
    │   ├── java/
    │   │   └── com/example/service/        # <package> directory
    │   │       ├── Main.java               # Bootstraps Nima server (main entry point)
    │   │       ├── web/
    │   │       │   └── HelloController.java # REST controller with 2 sample endpoints
    │   │       └── model/
    │   │           └── GreetingResponse.java # JSON response record (@Json annotated)
    │   └── resources/
    │       ├── application.properties      # Server configuration (port, shutdown)
    │       └── avaje-logger.properties     # Logging configuration
    └── test/
        ├── java/
        │   └── com/example/service/
        │       └── HelloControllerTest.java # Integration tests (@InjectTest)
        └── resources/
            └── avaje-logger-test.properties # Logging config for tests
```

### Key Generated Files Explained

**1. `Main.java`**
- Entry point for the application
- Starts the Nima web server on port 8080
- Uses `Nima.builder()` fluent API to configure and bootstrap

**2. `HelloController.java`**
- REST controller with `@Controller` and `@Path("/hi")` annotations
- Contains two sample methods:
  - `hi()`: Returns plain text "hi"
  - `data()`: Returns JSON-serialized `GreetingResponse` object
- Demonstrates HTTP routing with `@Get`, `@Produces` annotations

**3. `GreetingResponse.java`**
- Java record with `@Json` annotation
- Fields: `message` (String), `timestamp` (long)
- Automatically serialized to/from JSON by avaje-jsonb

**4. `HelloControllerTest.java`**
- Integration test using `@InjectTest` annotation
- Starts embedded server, executes HTTP requests, verifies responses
- Uses `HttpClient` injected from avaje-inject
- Tests both endpoints: text and JSON responses

**5. `application.properties`**
- Server configuration (commented by default):
  - `server.port=8080` - HTTP port (environment: `NIMA_PORT`)
  - `server.shutdownGraceMillis=5000` - Shutdown timeout

**6. `pom.xml`**
- Maven build configuration
- Key dependencies: avaje-nima, avaje-nima-test, avaje-jsonb
- Annotation processors: avaje-nima-generator (code generation)
- Profiles: `native` (GraalVM native image), `fat-jar` (shaded JAR)

---

## Quick Start: Build and Run

### Step 1: Generate Project

```bash
mvn archetype:generate \
  -DarchetypeGroupId=io.avaje.archetype \
  -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest \
  -DgroupId=com.example \
  -DartifactId=my-service \
  -Dpackage=com.example.service \
  -B
```

**Note:** Version parameter omitted to use latest available. To specify a specific version, add: `-DarchetypeVersion=1.9-RC1`

### Step 2: Enter Project Directory

```bash
cd my-service
```

### Step 3: Compile

```bash
mvn compile
```

**What happens:**
- Maven runs `javac` with annotation processors
- `avaje-nima-generator` generates DI wiring classes (in `target/`)
- `avaje-inject-maven-plugin` generates service provider interfaces

### Step 4: Run Tests

```bash
mvn test
```

**Expected output:**
```
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
```

Both tests should pass:
- `hi_returnsPlainText()` - Verifies GET /hi returns "hi"
- `data_returnsJson()` - Verifies GET /hi/data returns JSON

### Step 5: Start the Application

**Option A: Using Maven exec plugin**

```bash
mvn exec:java -Dexec.mainClass=com.example.service.Main
```

**Option B: Direct IDE execution**

Run `Main.java` from your IDE.

**Expected output:**
```
[main] INFO io.helidon.webserver.HelidonWebServer - Started on http://localhost:8080
```

### Step 6: Test Endpoints

**In a separate terminal:**

```bash
# Plain text endpoint
curl http://localhost:8080/hi
# Response: hi

# JSON endpoint
curl http://localhost:8080/hi/data
# Response: {"message":"hello from avaje-nima","timestamp":1712961787123}
```

---

## Generation Parameters Reference

### `groupId` (Required)

Reverse-domain notation for your organization.

| Example | Meaning |
|---------|---------|
| `com.example` | Example organization |
| `com.company` | Company-owned package |
| `io.github.username` | GitHub-based project |
| `org.myorg` | Non-profit organization |

**Effect**: Becomes part of the package hierarchy and JAR coordinates.

### `artifactId` (Required)

Project name (used as directory name and JAR name).

| Example | Notes |
|---------|-------|
| `my-service` | Kebab-case (recommended for Maven) |
| `myservice` | Lowercase (valid) |
| `MyService` | PascalCase (valid but not conventional) |

**Constraints:**
- Must be lowercase letters, numbers, hyphens
- No spaces or special characters
- Becomes directory name: `my-service/`

### `version` (Optional)

Project version following semantic versioning.

| Example | Meaning |
|---------|---------|
| `1.0.0` | Release version |
| `1.0-SNAPSHOT` | Development version (default) |
| `0.1.0` | Pre-release |
| `1.0.0-RC1` | Release candidate |

**Default**: `1.0-SNAPSHOT`

### `package` (Optional)

Java package root for generated classes.

| Example | Generated Path |
|---------|-----------------|
| `com.example.service` | `src/main/java/com/example/service/` |
| `com.example` | `src/main/java/com/example/` |

**Default**: Same as `groupId`

---

## Common Customization Patterns

### 1. Change Server Port

**Before running:**

Edit `src/main/resources/application.properties`:

```properties
server.port=9000
server.shutdownGraceMillis=5000
```

**Or override at runtime:**

```bash
mvn exec:java \
  -Dexec.mainClass=com.example.service.Main \
  -Dserver.port=9000
```

### 2. Add New REST Endpoint

Create a new controller file: `src/main/java/com/example/service/web/StatusController.java`

```java
package com.example.service.web;

import io.avaje.http.api.Controller;
import io.avaje.http.api.Get;
import io.avaje.http.api.Path;

@Controller
@Path("/status")
public class StatusController {

  @Get
  String status() {
    return "OK";
  }
}
```

Then recompile:

```bash
mvn compile
```

New endpoint available: `GET /status` → `"OK"`

### 3. Add JSON Request Body

Create a request DTO: `src/main/java/com/example/service/model/EchoRequest.java`

```java
package com.example.service.model;

import io.avaje.jsonb.Json;

@Json
public record EchoRequest(String message) {
}
```

Update controller: `src/main/java/com/example/service/web/EchoController.java`

```java
package com.example.service.web;

import io.avaje.http.api.Controller;
import io.avaje.http.api.Post;
import io.avaje.http.api.Path;
import com.example.service.model.EchoRequest;

@Controller
@Path("/echo")
public class EchoController {

  @Post
  EchoRequest echo(EchoRequest request) {
    return request;
  }
}
```

Test:

```bash
curl -X POST http://localhost:8080/echo \
  -H "Content-Type: application/json" \
  -d '{"message":"hello"}'
# Response: {"message":"hello"}
```

### 4. Add Dependency Injection

Add a service: `src/main/java/com/example/service/service/GreetingService.java`

```java
package com.example.service.service;

public class GreetingService {
  public String greet(String name) {
    return "Hello, " + name + "!";
  }
}
```

Inject into controller:

```java
package com.example.service.web;

import io.avaje.http.api.Controller;
import io.avaje.http.api.Get;
import io.avaje.http.api.Path;
import io.avaje.http.api.QueryParam;
import jakarta.inject.Inject;
import com.example.service.service.GreetingService;

@Controller
@Path("/greet")
public class GreetController {

  @Inject
  private GreetingService greetingService;

  @Get
  String greet(@QueryParam String name) {
    return greetingService.greet(name);
  }
}
```

Test:

```bash
curl "http://localhost:8080/greet?name=Alice"
# Response: Hello, Alice!
```

### 5. Add Database Entity

Generate archetype creates no database dependencies by default. To add JPA/database:

**Edit `pom.xml` and add dependency:**

```xml
<dependency>
  <groupId>io.ebean</groupId>
  <artifactId>ebean</artifactId>
  <version>17.4.0</version>
</dependency>
```

Recompile to use Ebean ORM.

---

## Build Profiles

### Native Executable Profile

Build as a standalone native binary (requires GraalVM):

```bash
mvn package -Pnative
```

**Output:**
```
./target/my-service
```

**Run directly (no Java required):**

```bash
./target/my-service
```

**Advantages:**
- Instant startup (<100ms)
- Low memory footprint
- No JVM required
- Single executable file

**Requirements:**
- GraalVM 23+ installed
- Native build tools (gcc on macOS/Linux)
- 10+ minutes build time

### Fat JAR Profile

Bundle all dependencies into a single executable JAR:

```bash
mvn package -Pfat-jar
```

**Output:**
```
./target/my-service-1.0-SNAPSHOT.jar
```

**Run:**

```bash
java -jar target/my-service-1.0-SNAPSHOT.jar
```

**Advantages:**
- All dependencies self-contained
- Easy distribution
- Works anywhere Java 25+ is installed
- Faster build than native

---

## File Locations Reference

| File | Path | Purpose |
|------|------|---------|
| Main entry point | `src/main/java/<package>/Main.java` | Server bootstrap |
| Controllers | `src/main/java/<package>/web/*.java` | HTTP endpoints |
| Models/DTOs | `src/main/java/<package>/model/*.java` | JSON request/response objects |
| Application config | `src/main/resources/application.properties` | Server configuration |
| Test suite | `src/test/java/<package>/*Test.java` | Integration tests |
| Compiled classes | `target/classes/` | Compiled bytecode |
| Generated code | `target/generated-sources/` | Annotation processor output |
| Build artifacts | `target/*.jar` | Packaged application |

---

## Troubleshooting

### Issue: "archetype not found"

**Symptom:** `Unknown archetype repository: archetype.repository` or `The desired archetype does not exist`

**Cause:** Maven cannot locate the archetype or specified version doesn't exist.

**Solution 1 (Recommended):** Omit version to use latest available:

```bash
mvn archetype:generate \
  -DarchetypeGroupId=io.avaje.archetype \
  -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest \
  -DgroupId=com.example \
  -DartifactId=my-service \
  -Dpackage=com.example.service \
  -B
```

**Solution 2:** Use interactive mode to see available versions:

```bash
mvn archetype:generate \
  -DarchetypeGroupId=io.avaje.archetype \
  -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest
```

**Solution 3:** Specify a known version:

```bash
mvn archetype:generate \
  -DarchetypeGroupId=io.avaje.archetype \
  -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest \
  -DarchetypeVersion=1.9-RC1
```

### Issue: Java version mismatch

**Symptom:** `[ERROR] Maven Compiler Plugin could not be configured: java.lang.UnsupportedClassVersionError`

**Cause:** System Java version < 25

**Solution:** Verify and upgrade Java:

```bash
java -version
# Should show: Java 25+

# Or set JAVA_HOME
export JAVA_HOME=/path/to/java25
```

### Issue: Annotation processors not running

**Symptom:** Generated classes not found, compilation fails

**Cause:** `avaje-nima-generator` not invoked during compile

**Solution:** Verify `pom.xml` has annotation processor configuration:

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-compiler-plugin</artifactId>
  <configuration>
    <annotationProcessorPaths>
      <path>
        <groupId>io.avaje</groupId>
        <artifactId>avaje-nima-generator</artifactId>
        <version>${avaje.nima.version}</version>
      </path>
    </annotationProcessorPaths>
  </configuration>
</plugin>
```

Then run: `mvn clean compile`

### Issue: Port 8080 already in use

**Symptom:** `Exception: java.net.BindException: Address already in use`

**Solution A:** Kill process using port 8080

```bash
# macOS/Linux
lsof -i :8080 | grep LISTEN | awk '{print $2}' | xargs kill -9

# Or use different port
mvn exec:java -Dexec.mainClass=com.example.service.Main -Dserver.port=9000
```

**Solution B:** Uncomment and change port in `application.properties`:

```properties
server.port=9000
```

### Issue: Tests fail during compilation

**Symptom:** `[ERROR] Tests run: N, Failures: X`

**Cause:** Embedded server setup issue or missing dependencies

**Solution:** Clean and rebuild:

```bash
mvn clean test
```

Or run with verbose output:

```bash
mvn test -X
```

---

## For AI Agents: Command Patterns

### Pattern 1: Generate and Build

AI agents should use this sequence to ensure successful project creation:

```bash
# 1. Generate project in batch mode
mvn archetype:generate \
  -DarchetypeGroupId=io.avaje.archetype \
  -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest \
  -DarchetypeVersion=1.9-RC1 \
  -DgroupId=<GROUP> \
  -DartifactId=<ARTIFACT> \
  -Dversion=<VERSION> \
  -Dpackage=<PACKAGE> \
  -B

# 2. Enter project directory
cd <ARTIFACT>

# 3. Verify compilation
mvn compile

# 4. Run tests to verify setup
mvn test

# 5. Optionally: Run application
mvn exec:java -Dexec.mainClass=<PACKAGE>.Main
```

### Pattern 2: Verify Generated Project

To verify a generated project is valid:

```bash
# Test compilation
mvn compile

# Test execution
mvn test

# Check for generated files
ls target/generated-sources/
```

**Expected files in `target/generated-sources/`:**
- `AppProvides.java` - Dependency injection wiring
- `$Controller*.java` - HTTP routing annotations

### Pattern 3: Extract Project Information

To read configuration from generated project:

```bash
# Get project group, artifact, version, package
cd <project-dir>
mvn help:describe -Ddetail=true | grep -E "group|artifact|version|package"

# Or parse pom.xml
grep -E "<groupId>|<artifactId>|<version>|<package>" pom.xml
```

### Pattern 4: Add Dependencies Programmatically

To add a dependency to the generated project:

```bash
mvn dependency:tree  # Show current dependencies

# Manually add to pom.xml <dependencies> section or use:
mvn install:install-file -Dfile=<jar> -DgroupId=<group> ...
```

### Pattern 5: Custom Build Instructions

For custom build steps after generation:

```bash
# 1. Compile and generate code
mvn compile

# 2. Copy generated sources to main
mvn exec:exec -Dexec.executable="cp -r"

# 3. Re-compile with generated code
mvn clean compile
```

---

## Integration with IDE/Tools

### VS Code

1. Install "Extension Pack for Java" by Microsoft
2. Open project folder
3. Open `src/main/java/<package>/Main.java`
4. Click "Run" button above main() method
5. Application starts on port 8080

### IntelliJ IDEA

1. File → Open → Select project directory
2. Maven should auto-detect `pom.xml`
3. Right-click `Main.java` → Run 'Main.main()'
4. Application starts on port 8080

### Eclipse

1. File → Import → Existing Maven Projects
2. Select project directory
3. Eclipse imports and indexes automatically
4. Right-click project → Run As → Java Application
5. Select `Main` class to run

---

## Reference Links

| Resource | URL |
|----------|-----|
| Avaje Nima Docs | https://avaje.io/nima/ |
| Avaje Archetypes | https://avaje.io/nima/archetypes |
| Maven Archetype Plugin | https://maven.apache.org/archetype/ |
| Helidon Níma | https://helidon.io/ |
| Avaje Inject | https://avaje.io/inject/ |
| Java 25 Release | https://www.oracle.com/java/technologies/ |

---

## Version Information

| Component | Version | Notes |
|-----------|---------|-------|
| Archetype | 1.9-RC1 | Latest as of 2026-04-12 |
| Avaje Nima | 1.8 | Latest compatible with archetype 1.9-RC1 |
| Avaje HTTP | 3.8 | Included in avaje-nima |
| Helidon | 4.4.0 | Virtual-thread HTTP server |
| Java Target | 25 | Minimum Java version for generated projects |
| Maven Minimum | 3.9 | Minimum Maven version required |

### Best Practice for Version Management

**For AI Agents: Always omit `-DarchetypeVersion` to use the latest available version:**

```bash
mvn archetype:generate \
  -DarchetypeGroupId=io.avaje.archetype \
  -DarchetypeArtifactId=avaje-nima-archetype-minimal-rest \
  -DgroupId=com.example \
  -DartifactId=my-service \
  -Dpackage=com.example.service \
  -B
```

This ensures:
- ✅ New projects always get the latest features and bug fixes
- ✅ No need to track version updates
- ✅ Compatible with Maven's automatic version resolution
- ✅ Simpler command syntax

**When to specify a version:** Only specify `-DarchetypeVersion` when you need a specific, older version for compatibility or testing purposes.

The example commands throughout this guide show `1.9-RC1` for reference, but should be omitted for production usage to always get latest.

---

## Document Information

**Intended for:** AI agents (Claude, GPT, Copilot)
**Format:** Markdown with code blocks
**Refresh Cadence:** Updated with new archetype versions
**Last Generated:** 2026-04-12
**Maintenance:** Keep in sync with archetype README and avaje.io docs

---

---

## Source: `nima/multi-module-architecture.md`

# Guide: Multi-Module Architecture (Model + Server + Client)

## Purpose

This guide describes a production-grade multi-module Maven architecture for REST APIs
that will be consumed by multiple Java clients. It separates public API models (DTOs)
from internal server and database details, keeping clients lightweight and decoupled from
server implementation.

When asked to:
- *"Create a new entity and endpoint"*
- *"Add support for another client variant"*
- *"Refactor the project for reusability"*
- *"Consume this API from an external Java app"*

...follow the patterns and module layout described here.

---

## When This Pattern Applies

✅ **Use this architecture if:**
- You're building a REST API that will be consumed by multiple independent Java clients
- You want clients to never depend on server logic, database code, or ORM configuration
- You need to support multiple Java versions (8 + modern) without duplicating logic
- You want type-safe HTTP clients (generated from models) instead of generic HTTP tools
- You prefer immutable Java Records over mutable POJOs

❌ **You probably don't need this if:**
- You're building a small CLI tool or internal utility
- Your API is server-only with no external consumers
- You're not planning multiple client variants

---

## Architecture Overview

The pattern uses **7 modules** organized in layers:

```
project (parent pom)
│
├── Model Layer          [PUBLIC API]
│   └── project-model
│       ├── Java Records (DTOs) — no persistence annotations
│       ├── Package: org.project.model
│       ├── Examples: Device, Driver, Fleet, OrgMachine, User
│       ├── Naming: [Noun], [Noun]Summary, [Noun]Status/Type
│       └── Consumed by: Service + all clients
│
├── Data Access Layer    [INTERNAL]
│   └── project-repository
│       ├── Ebean @Entity classes — ORM configuration
│       ├── Package: org.project.repository.data
│       ├── Naming: D* prefix (Hungarian notation for "Domain")
│       │   E.g., DOrganisationMachine (entity) vs. OrgMachine (model)
│       └── Consumed by: Service only
│
├── Business Logic Layer [INTERNAL]
│   └── project-service
│       ├── REST controllers (@RestController)
│       ├── Service layer (business logic, transactions)
│       ├── Converters (Entity ↔ Model translation)
│       ├── Query builders, validators
│       ├── Main: embedded Helidon SE server
│       └── Depends on: Repository + Model
│
└── Client Layers        [PUBLIC API]
    ├── project-client (Java 17+)
    │   ├── Generated HTTP client API
    │   ├── Package: org.project.client
    │   ├── Depends on: Model only (no server logic, no DB)
    │   └── Safe for external consumption
    │
    ├── project-client-java8 (Java 8)
    │   ├── Same API as Java 17+ client, Java 8 compatible
    │   ├── Useful for legacy codebases
    │   └── Identical logic to modern variant
    │
    └── project-device-client (optional domain-specific)
        └── Specialized client for device-only operations
```

### Dependency Flow (What imports what)

```
Clients     → Model (only)
            ↗
Service     → Model + Repository

Repository  → (Ebean, PostgreSQL, no upstream deps)

Model       → (standalone: @RecordBuilder, @Json only)
```

**Critical rule:** Clients NEVER import Repository. Repository is an implementation detail.

---

## The 4 Core Modules Explained

### 1. Model Module — The Public API Contract

**File:** `project-model/pom.xml`

**Purpose:** Define the data transfer objects (DTOs) that represent your API.

**Characteristics:**
- ✅ Java Records (immutable, no getters/setters)
- ✅ Annotated with `@RecordBuilder` (Avaje) + `@Json` (Avaje JSONB)
- ✅ No persistence annotations (`@Entity`, `@Column`, etc.)
- ✅ No database dependencies
- ✅ Can be used standalone in any Java project

**Naming Conventions:**

| Pattern | Purpose | Examples |
|---------|---------|----------|
| `[Noun]` | Full domain model | `Device`, `Driver`, `Fleet`, `User`, `OrgMachine`, `Terminal` |
| `[Noun]Summary` | Lightweight view (3–8 fields) | `DriverSummary`, `OrgMachineSummary` |
| `[Noun]Status` or `[Noun]Type` | Reference/enum data | `DeviceStatus`, `OrgMachineAssetType` |
| `[Model1][Model2]` | Association/relationship | `DeviceMachine`, `OrgMachineDevice`, `DeviceFirmware` |

**Example:**

```java
package project.model;

import io.avaje.jsonb.Json;
import io.avaje.nima.core.record.RecordBuilder;
import java.time.Instant;
import java.util.UUID;

@RecordBuilder
@Json
public record Device(
    long id,
    UUID gid,
    int version,
    String description,
    DeviceStatus status,
    Instant created,
    Instant lastModified
) {
    public static DeviceBuilder builder() {
        return DeviceBuilder.builder();
    }

    public static DeviceBuilder builder(Device from) {
        return DeviceBuilder.builder(from);
    }
}
```

**Boilerplate for every Record:**
- `public static [Record]Builder builder()` — for construction
- `public static [Record]Builder builder([Record] from)` — for copying (optional)

---

### 2. Repository Module — Internal Data Access (Hidden from Clients)

**File:** `project-repository/pom.xml`

**Purpose:** Define Ebean `@Entity` classes for database mapping.

**Characteristics:**
- ✅ Ebean `@Entity` classes with full ORM configuration
- ✅ Database-specific logic (queries, lifecycle callbacks)
- ✅ **D* prefix naming (Hungarian notation)** to distinguish from public API models
- ✅ No REST annotations; server-side only
- ✅ Consumed exclusively by the Service layer

**Naming Convention — D* Prefix (Recommended Default):**

D stands for "Domain" (entity classes represent domain data at the database level).

| Public Model | Internal Entity |
|--------------|-----------------|
| `OrgMachine` | `DOrganisationMachine` |
| `Device` | `DDevice` |
| `User` | `DUser` |

**Why the prefix?**
- Avoids name clashing: `OrgMachine` (DTO) vs. `DOrganisationMachine` (JPA entity)
- Makes it immediately clear which is safe to expose to clients (unprefixed) vs. internal (D* prefix)
- Prevents accidental leakage of ORM implementation details

*Note:* D* is the recommended default prefix for entity classes, but you can use other prefixes as desired.

**Example:**

```java
package project.repository.data;

import io.ebean.annotation.DbDefault;
import io.ebean.annotation.WhenCreated;
import io.ebean.annotation.WhenModified;
import jakarta.persistence.*;
import lombok.Data;
import java.time.Instant;

@Data
@Entity
@Table(name = "device")
public class DDevice {

    @Id
    private long id;

    @Version
    private int version;

    @Column(length = 255)
    private String description;

    @DbDefault("'ACTIVE'")
    @Column(length = 20)
    private String status;

    @WhenCreated
    private Instant created;

    @WhenModified
    private Instant lastModified;
}
```

**Key Differences from Model:**
- ✅ Has `@Entity`, `@Table`, `@Column` annotations
- ✅ Uses Lombok for getters/setters
- ✅ Includes ORM lifecycle hints (`@WhenCreated`, `@WhenModified`, `@DbDefault`)
- ✅ Tailored to database schema

---

### 3. Service Module — Business Logic & REST API

**File:** `project-service/pom.xml`

**Purpose:** Implement the REST API, orchestrate Repository + Model layers.

**Characteristics:**
- ✅ REST controllers (`@RestController`) with endpoints
- ✅ Service classes (business logic, transactions)
- ✅ Converters (translate Entity → Model for clients)
- ✅ Query builders, validators, custom logic
- ✅ Main application entry point

**Layout:**

```
project-service/
├── src/main/java/nz/co/eroad/central/access/
│   ├── Main.java                          # App entry point
│   ├── web/
│   │   ├── DeviceController.java          # REST endpoints
│   │   ├── DriverController.java
│   │   └── FleetController.java
│   ├── service/
│   │   ├── DeviceService.java             # Business logic
│   │   ├── DriverService.java
│   │   └── FleetService.java
│   ├── converter/
│   │   ├── DeviceConverter.java           # Entity → Model
│   │   ├── DriverConverter.java
│   │   └── FleetConverter.java
│   ├── query/
│   │   └── [query builders, search criteria]
│   ├── repository/
│   │   └── [Spring/Ebean data access]
│   └── configuration/
│       └── [beans, security, etc.]
└── pom.xml
```

**Example Controller:**

```java
package project.service.web;

import io.avaje.nima.core.inject.Container;
import io.avaje.nima.core.http.*;
import org.project.model.Device;
import org.project.service.DeviceService;
import jakarta.inject.Inject;

@RestController
@Path("/devices")
public class DeviceController {

    private final DeviceService deviceService;

    @Inject
    DeviceController(DeviceService deviceService) {
        this.deviceService = deviceService;
    }

    @Get("/:id")
    public Device getDevice(long id) {
        return deviceService.findById(id);
    }

    @Get
    public List<Device> listDevices() {
        return deviceService.list();
    }

    @Post
    public Device createDevice(Device device) {
        return deviceService.save(device);
    }
}
```

**Example Converter:**

```java
package project.service.converter;

import org.project.model.Device;
import org.project.repository.data.DDevice;

public class DeviceConverter {

    public static Device toModel(DDevice entity) {
        if (entity == null) return null;
        return new Device(
            entity.getId(),
            entity.getGid(),
            entity.getVersion(),
            entity.getDescription(),
            DeviceStatus.valueOf(entity.getStatus()),
            entity.getCreated(),
            entity.getLastModified()
        );
    }

    public static DDevice toEntity(Device model) {
        if (model == null) return null;
        DDevice entity = new DDevice();
        entity.setId(model.id());
        entity.setDescription(model.description());
        entity.setStatus(model.status().name());
        return entity;
    }
}
```

---

### 4. Client Modules — Generated HTTP Clients

**Files:**
- `project-client/pom.xml` (Java 17+)
- `project-client-java8/pom.xml` (Java 8)

**Purpose:** Provide a type-safe HTTP client for consuming the API.

**Characteristics:**
- ✅ Auto-generated from the REST API (via Maven plugin or manual)
- ✅ Depends on Model only (zero coupling to Server/Repository)
- ✅ Type-safe methods matching endpoints (e.g., `api.devices().get(id)`)
- ✅ Immutable Java Records for responses (Java 17+) or equivalent (Java 8)
- ✅ Can be used in any external Java application

**Example Client Usage:**

```java
package com.example;

import io.avaje.http.client.HttpClient;
import org.project.client.CentralAccessApi;
import org.project.model.Device;

public class MyApp {

    public static void main(String[] args) {
        HttpClient httpClient = HttpClient.builder()
            .baseUrl("http://localhost:8080")
            .build();

        CentralAccessApi api = new CentralAccessApi(httpClient);

        // Type-safe API calls
        Device device = api.devices().get(123L);
        System.out.println("Device: " + device.description());

        List<Device> all = api.devices().list();
        System.out.println("Found " + all.size() + " devices");
    }
}
```

**How to use the client in external projects:**

1. Add dependency to `pom.xml`:

```xml
<dependency>
    <groupId>org.project</groupId>
    <artifactId>project-client</artifactId>
    <version>1.0.0</version>
</dependency>
```

2. Create `HttpClient` configured with your server URL
3. Instantiate the generated API class
4. Call type-safe methods — no manual JSON parsing needed

---

## Step-by-Step Recipes

### Recipe 1: Add a New Entity + Endpoint + Model

**Scenario:** You want to add support for a new resource, e.g., "Geofence".

**Step 1: Create the public Model** (in `project-model`)

```java
package org.project.model;

import io.avaje.jsonb.Json;
import io.avaje.nima.core.record.RecordBuilder;
import java.time.Instant;
import java.util.UUID;

@RecordBuilder
@Json
public record Geofence(
    long id,
    UUID gid,
    int version,
    String name,
    String wktGeometry,
    Instant created,
    Instant lastModified
) {
    public static GeofenceBuilder builder() {
        return GeofenceBuilder.builder();
    }

    public static GeofenceBuilder builder(Geofence from) {
        return GeofenceBuilder.builder(from);
    }
}
```

**Step 2: Create the internal Entity** (in `project-repository`)

```java
package org.project.repository.data;

import io.ebean.annotation.WhenCreated;
import io.ebean.annotation.WhenModified;
import jakarta.persistence.*;
import lombok.Data;
import java.time.Instant;

@Data
@Entity
@Table(name = "geofence")
public class DGeofence {

    @Id
    private long id;

    @Version
    private int version;

    @Column(length = 255)
    private String name;

    @Column(columnDefinition = "geometry")
    private String wktGeometry;

    @WhenCreated
    private Instant created;

    @WhenModified
    private Instant lastModified;
}
```

**Step 3: Create the Converter** (in `project-service`)

```java
package org.project.converter;

import org.project.model.Geofence;
import org.project.repository.data.DGeofence;

public class GeofenceConverter {

    public static Geofence toModel(DGeofence entity) {
        if (entity == null) return null;
        return new Geofence(
            entity.getId(),
            entity.getGid(),
            entity.getVersion(),
            entity.getName(),
            entity.getWktGeometry(),
            entity.getCreated(),
            entity.getLastModified()
        );
    }

    public static DGeofence toEntity(Geofence model) {
        if (model == null) return null;
        DGeofence entity = new DGeofence();
        entity.setId(model.id());
        entity.setName(model.name());
        entity.setWktGeometry(model.wktGeometry());
        return entity;
    }
}
```

**Step 4: Create the Controller** (in `project-service`)

```java
package org.project.web;

import io.avaje.nima.core.http.*;
import org.project.model.Geofence;
import org.project.service.GeofenceService;
import jakarta.inject.Inject;

@RestController
@Path("/geofences")
public class GeofenceController {

    private final GeofenceService geofenceService;

    @Inject
    GeofenceController(GeofenceService geofenceService) {
        this.geofenceService = geofenceService;
    }

    @Get("/:id")
    public Geofence get(long id) {
        return geofenceService.findById(id);
    }

    @Get
    public List<Geofence> list() {
        return geofenceService.list();
    }

    @Post
    public Geofence create(Geofence geofence) {
        return geofenceService.save(geofence);
    }
}
```

**Step 5: Create the Service** (in `project-service`)

```java
package org.project.service;

import io.ebean.Database;
import org.project.converter.GeofenceConverter;
import org.project.model.Geofence;
import org.project.repository.data.DGeofence;
import jakarta.inject.Inject;
import java.util.List;

public class GeofenceService {

    private final Database database;

    @Inject
    GeofenceService(Database database) {
        this.database = database;
    }

    public Geofence findById(long id) {
        DGeofence entity = database.find(DGeofence.class, id);
        return GeofenceConverter.toModel(entity);
    }

    public List<Geofence> list() {
        return database.find(DGeofence.class)
            .findList()
            .stream()
            .map(GeofenceConverter::toModel)
            .toList();
    }

    public Geofence save(Geofence geofence) {
        DGeofence entity = GeofenceConverter.toEntity(geofence);
        database.save(entity);
        return GeofenceConverter.toModel(entity);
    }
}
```

**Step 6: Regenerate Clients** (Maven plugin or manual generation)

Run:
```bash
mvn clean generate-sources
```

The generated `CentralAccessApi` will now include `geofences()` methods.

**Step 7: Update integration tests** (in `project-integration-test`)

```java
@InjectTest
class GeofenceControllerTest {

    @Inject CentralAccessApi api;

    @Test
    void testCreateAndRetrieveGeofence() {
        Geofence created = api.geofences().create(
            new Geofence(0, UUID.randomUUID(), 0, "Test", "POLYGON(...)", null, null)
        );
        assertThat(created.id()).isGreaterThan(0);

        Geofence fetched = api.geofences().get(created.id());
        assertThat(fetched.name()).isEqualTo("Test");
    }
}
```

---

### Recipe 2: Add a New Client Variant (e.g., Java 11)

**Scenario:** You want to provide a client for Java 11 (between Java 8 and Java 17+).

**Step 1: Create a new Maven module**

```
project-client-java11/
├── pom.xml
├── src/main/java/nz/co/eroad/central/access/client/
│   ├── CentralAccessApi.java
│   ├── MachinesApi.java
│   └── ...
└── src/test/java/nz/co/eroad/central/access/client/
```

**Step 2: Add the module to parent `pom.xml`**

```xml
<modules>
    ...
    <module>project-client-java11</module>
</modules>
```

**Step 3: Set Java version and dependencies in `pom.xml`**

```xml
<properties>
    <maven.compiler.release>11</maven.compiler.release>
</properties>

<dependencies>
    <dependency>
        <groupId>org.project</groupId>
        <artifactId>project-model</artifactId>
        <version>1.0.0</version>
    </dependency>
    <!-- Same as Java 8 client but targeting Java 11 -->
</dependencies>
```

**Step 4: Copy client source code from Java 8 variant**

Make minimal adjustments for Java 11 features (e.g., `var` keyword if desired, local class syntax).

**Step 5: Publish to Maven repo**

```bash
mvn deploy
```

**Step 6: Update documentation**

Add reference to the new client variant in README and architecture guide.

---

## Key Principles for AI Agents

When working with this architecture, ask yourself:

1. **Is this a public API class or internal database class?**
   - Public: No prefix, lives in `project-model` package
   - Internal: D* prefix (or project-specific like C*), lives in `project-repository` package

2. **Where should this code go?**
   - Model (DTOs, immutable data): `project-model`
   - Entity mapping, queries: `project-repository`
   - Business logic, conversion, controllers: `project-service`
   - HTTP client, call orchestration: `project-client*`

3. **Should I add both a public model AND an @Entity?**
   - **Yes**, almost always. The public model is the API contract; the entity is the database representation.
   - They may have different fields, naming, or structure.
   - The Service layer translates between them.

4. **Who should import Repository?**
   - **Only the Service module.** Clients, models, and external apps should never reference the repository.

5. **How do I test this?**
   - Use the generated client API (Approach 2 from the controller testing guide).
   - Inject the generated API (`@Inject CentralAccessApi`) into tests.
   - Call type-safe methods; no manual HTTP construction.

---

## Troubleshooting

### "Cannot find CentralAccessApi"

**Cause:** Client code was not generated or dependencies are missing.

**Fix:**
1. Ensure `project-model` is in the classpath
2. Run `mvn clean generate-sources` to regenerate
3. Check that the REST controller exists and is properly annotated

### "Import DOrganisationMachine in my client"

**Cause:** Trying to use internal @Entity class in external code.

**Fix:**
- Import `OrgMachine` from `project-model` instead
- Use the converter in the service to translate between @Entity and model

### "My client can't connect to the server"

**Cause:** Wrong base URL or server not running.

**Fix:**
```java
HttpClient httpClient = HttpClient.builder()
    .baseUrl("http://localhost:8080")  // ← Correct URL + port
    .build();
```

---

## Summary Table

| Aspect | Model | Repository | Service | Client |
|--------|-------|------------|---------|--------|
| **Naming** | [Noun] | D[Noun] | (business logic) | Generated API |
| **Annotations** | @RecordBuilder, @Json | @Entity, @Table, @Column | @RestController, @Service | (generated) |
| **Database code?** | No | Yes | Yes (via Repository) | No |
| **Mutable?** | No (Records) | Yes (Lombok) | Mixed | No (Records) |
| **Imported by** | Service + Clients | Service only | (standalone) | External apps |
| **Safe to expose?** | ✅ Yes | ❌ No | ❌ No | ✅ Yes |

---

## See Also

- [Guide: Add a Controller Test](add-controller-test.md) — write integration tests using the generated client API
- [Model Naming Conventions](../../README.md) — detailed naming conventions for Records and types
- Ebean documentation — entity mapping, queries, transactions
