# Both stages pin the same patched Corretto build by tag and digest.
# Tag 21.0.13 on Docker Hub carries Corretto 21.0.13.1.2, the build whose
# changelog names CVE-2026-114938 (Java4Shell). Verified 2026-11-18 by
# reading the release file inside the published image:
# IMPLEMENTOR_VERSION="Corretto-21.0.13.1.2", JAVA_VERSION_DATE="2026-11-17".
# To move to a newer patched build, update the tag and the digest together.
# Get the digest with: docker buildx imagetools inspect amazoncorretto:<tag>

FROM amazoncorretto:21.0.13@sha256:3284a05cb82e9bceb4857f9d70788a6f72681d9070b550ae5f477b5e3dc81a5c AS build
WORKDIR /app

# Maven wrapper first, so the dependency layer stays cached between builds.
# The wrapper jar is committed, so this step needs no curl or wget.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
# Some push routes drop the executable bit on mvnw; set it explicitly.
# Found by the first live Railway deploy test on 2026-11-19, which failed
# with "./mvnw: Permission denied" (exit 126).
RUN chmod +x ./mvnw
RUN ./mvnw -B dependency:go-offline

COPY src/ src/
RUN ./mvnw -B package -DskipTests

FROM amazoncorretto:21.0.13@sha256:3284a05cb82e9bceb4857f9d70788a6f72681d9070b550ae5f477b5e3dc81a5c AS runtime
WORKDIR /app

# The Corretto runtime image ships no groupadd/useradd (shadow-utils is
# absent); the first live Railway deploy test on 2026-11-19 failed with
# "groupadd: command not found". Run as a fixed numeric UID instead, which
# needs no passwd entry. app.jar is copied world-readable, so this works.
COPY --from=build /app/target/app.jar app.jar
USER 10001

# Railway sets PORT, and the app reads it. 8080 is the local default.
EXPOSE 8080

# JAVA_OPTS is empty by default. It exists so an operator can pass JVM flags
# without rebuilding the image.
ENV JAVA_OPTS=""
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
