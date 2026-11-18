# Spring Boot on Patched Corretto 21

A small Spring Boot starter that runs on Amazon Corretto 21.0.13.1.2, the
build that fixes Java4Shell (CVE-2026-114938). Both the build stage and the
runtime stage of the Dockerfile pin that exact build, by tag and by digest.

## Why this starter exists: Java4Shell

On 17 November 2026, Oracle and the OpenJDK project disclosed
CVE-2026-114938, nicknamed Java4Shell by the security firm Calif, which
found it. It is a memory corruption flaw in the Base64 decoder built into
the HotSpot JVM itself, in the AVX-512 accelerated decode routine reached
through `java.util.Base64`. It is not a flaw in any library or framework,
so dependency scanners do not flag it. The only complete fix is a patched
Java runtime and a restart of every JVM.

Calif demonstrated unauthenticated remote code execution against default
installs of Keycloak, Jira, Confluence, Artifactory, Jenkins and
PingFederate. Oracle scores it 8.1 under CVSS 3.1. Calif scores it 9.2
under CVSS 4.0. CISA published an alert on the day of disclosure urging
organizations to patch immediately. No exploitation in the wild had been
reported as of 18 November 2026.

You are exposed only when all three of these hold:

1. The runtime is OpenJDK 17.0.6 or later without the fix. The maintained
   lines 17, 21, 25 and 27 are all affected. Lines 18 to 20, 22 to 24 and
   26 are end of life and will not be fixed; move them to a fixed LTS line.
2. The CPU is x86-64 with AVX-512 VBMI support (Intel Ice Lake and later
   server parts, AMD Zen 4 and later). ARM64 is not affected.
3. Attacker controlled data reaches the Base64 decoder.

Standard Java 8 and Java 11 builds do not contain the vulnerable code.

Fixed builds released on 17 November 2026 include Oracle JDK 17.0.21.1,
21.0.13.1, 25.0.5.1 and 27.0.1.1, and Amazon Corretto 17.0.21.1.2,
21.0.13.1.2, 25.0.5.1.2 and 27.0.1.1.4. Azul Zulu and SAP SapMachine also
shipped fixed builds that day. As of 18 November 2026, Eclipse Temurin,
the Microsoft Build of OpenJDK, Red Hat OpenJDK and BellSoft Liberica had
not yet shipped fixed builds.

## Why Corretto, and why this pin

Most Java Docker images, including the ones in most Spring Boot guides,
are built on Eclipse Temurin. Temurin had no fixed build when this starter
was written, so a template pinned to Temurin today would ship the
vulnerable runtime by default. Corretto had its fixed builds out on
disclosure day, so this starter pins Corretto.

Docker Hub does not publish a `21.0.13.1.2` tag. Corretto Docker tags use
the first three version numbers, and the `21.0.13` tag was republished on
17 November 2026 carrying the fixed build. This was verified directly
against the published image on 18 November 2026: the release file inside
`amazoncorretto:21.0.13` reads `IMPLEMENTOR_VERSION="Corretto-21.0.13.1.2"`
and `JAVA_VERSION_DATE="2026-11-17"`. The Dockerfile pins the tag plus the
multi architecture image digest, so the build cannot silently drift to a
different image under the same tag.

## Verify a deployment

Run `java -version` in the environment. A patched Corretto 21 runtime
prints:

```text
openjdk version "21.0.13.1" 2026-11-17 LTS
OpenJDK Runtime Environment Corretto-21.0.13.1.2 (build 21.0.13.1+2-LTS)
OpenJDK 64-Bit Server VM Corretto-21.0.13.1.2 (build 21.0.13.1+2-LTS, mixed mode, sharing)
```

The version to look for is `21.0.13.1` or later in the first line, with
`Corretto-21.0.13.1.2` or later in the build lines. Anything at
`21.0.13` exactly, or `21.0.12` and below, is unpatched.

The running app also reports its own JVM at `GET /api/runtime`, which is
the quickest check on a live deployment.

## If you are stuck on another distribution

Until your JDK vendor ships a fixed build, start the JVM with:

```text
-XX:-UseBASE64Intrinsics
```

This disables the accelerated Base64 intrinsic, which removes the
vulnerable code path. Base64 work falls back to the plain Java
implementation, which is slower and still correct. Treat this as a
stopgap, not a fix. Upgrade to a patched build as soon as your vendor
publishes one, then remove the flag. In this starter you can pass the
flag without rebuilding, by setting the `JAVA_OPTS` variable.

## The app

A minimal REST API on Spring Boot 4.1.2 and Java 21:

| Endpoint | What it returns |
| --- | --- |
| `GET /actuator/health` | Actuator health. Railway polls this path. |
| `GET /api/hello` | A sample JSON greeting. |
| `GET /api/runtime` | The JVM version, vendor and architecture the app is running on. |

## Run it locally

You need a JDK 21. Any patched distribution works for development.

```bash
./mvnw spring-boot:run
./mvnw test
curl http://localhost:8080/actuator/health
curl http://localhost:8080/api/hello
curl http://localhost:8080/api/runtime
```

With Docker:

```bash
docker build -t spring-boot-corretto-patched .
docker run --rm -p 8080:8080 spring-boot-corretto-patched
```

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `PORT` | `8080` | Port the app listens on. Railway sets this automatically. |
| `JAVA_OPTS` | empty | Extra JVM flags passed at startup, for example `-Xmx512m`. |

See `.env.example` for a local `.env` template. It holds placeholders and
defaults only.

## Deploy on Railway

Create a project from this repository. Railway reads `railway.json`,
builds the `Dockerfile`, and health checks the service on
`/actuator/health`. No variables are required. Set `JAVA_OPTS` only if
you need JVM flags.

## Updating the JDK pin

When a newer patched Corretto build ships:

1. Pick the new Docker Hub tag under `amazoncorretto`.
2. Read its digest: `docker buildx imagetools inspect amazoncorretto:<tag>`
3. Update the tag and the digest together in both `FROM` lines of the
   `Dockerfile`.
4. Rebuild, then confirm `GET /api/runtime` reports the new build.

## Versions pinned in this starter

| Component | Version | Source checked |
| --- | --- | --- |
| Spring Boot | 4.1.2 | Maven Central, latest stable release as of 18 November 2026 |
| Amazon Corretto | 21.0.13.1.2, via tag `21.0.13` and digest | Docker Hub registry, release file read from the published image |
| Maven (via wrapper) | 3.9.16 | Maven Central |
| Java language level | 21 | `pom.xml` |

## Layout

```text
Dockerfile            Multi stage build, patched Corretto in both stages
railway.json          Railway build and health check config
pom.xml               Spring Boot 4.1.2, Java 21
mvnw, .mvn/           Maven wrapper, no local Maven install needed
src/main/java/        Application entry point and the two sample endpoints
src/main/resources/   Port, shutdown and actuator configuration
src/test/java/        Context load and endpoint tests
```
