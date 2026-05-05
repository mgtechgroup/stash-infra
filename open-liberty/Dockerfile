# Open Liberty Application Server - Production Dockerfile
# Multi-stage build with security hardening

FROM open-liberty:latest as base
LABEL maintainer="Your Organization" \
      description="Open Liberty Java Application Server"

# Enable necessary features
RUN features.sh \
    && featureUtility installFeatures --acceptLicense \
        servlet-6.0 \
        webProfile-10.0 \
        openapi-3.1 \
        mpMetrics-5.0 \
        mpConfig-3.0 \
        mpRestClient-3.0 \
        jwtSso-1.0 \
        json-2.0 \
        jsonp-2.1 \
        jpa-3.1 \
        jdbc-4.3 \
        appClientSupport-2.0 \
        transportSecurity-1.0

# Build stage - application packaging
FROM base as build
WORKDIR /app
COPY . .

# Compile if needed (adjust based on your app structure)
# RUN mvn clean package -DskipTests

# Runtime stage
FROM open-liberty:latest as runtime

# Set labels
LABEL maintainer="Your Organization" \
      version="1.0" \
      description="Open Liberty Application Server (Production)"

# Environment
ENV TZ=UTC \
    LANG=en_US.UTF-8 \
    JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseStringDeduplication -XX:+ParallelRefProcEnabled" \
    WLP_OUTPUT_DIR=/opt/ol/wlp/output

# Create non-root user for Liberty
RUN groupadd -r liberty && useradd -r -g liberty liberty || true

# Health check script
COPY --from=base /opt/ol/wlp/bin/health* /opt/ol/healthcheck/
RUN chmod +x /opt/ol/healthcheck/health* || true

EXPOSE 9080 9443 9011

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=30s \
    CMD curl -f http://localhost:9080/health || exit 1

# Set working directory
WORKDIR /opt/ol/wlp

# Ownership
RUN chown -R liberty:liberty /opt/ol/wlp

# Drop capabilities
RUN setcap -r /opt/ol/jdk/bin/java 2>/dev/null || true

# Run as non-root
USER liberty

# Default command
CMD ["/opt/ol/helpers/runtime/docker-server.sh"]
