# Use a small base image with /bin/sh available for ENTRYPOINT wrapper
# Build with: docker build --build-arg PLATFORM=linux-amd64 -t ppanel:latest .
# PLATFORM may be: darwin-amd64, darwin-arm64, linux-amd64, linux-arm64

FROM alpine:3.18

# Build-time argument to choose platform (default linux-amd64)
ARG PLATFORM=linux-amd64
ENV PLATFORM=${PLATFORM}

# Create app directories
WORKDIR /app
RUN mkdir -p /app/modules /app/etc

# Copy gateway binary from host ./bin/gateway-<PLATFORM> -> /app/
# Copy server binary from ./modules/<PLATFORM>/ppanel-server -> /app/modules/
# Copy config folder from ./modules/<PLATFORM>/etc -> /app/etc/
# Note: Docker expands ARG/ENV in COPY at build time for the source path.

# Copy gateway
COPY --chmod=0755 "bin/gateway-${PLATFORM}" "/app/gateway-${PLATFORM}"

# Copy server binary
COPY --chmod=0755 "modules/${PLATFORM}/ppanel-server" "/app/modules/ppanel-server"

# Copy etc folder (if exists)
COPY "modules/${PLATFORM}/etc" "/app/etc"

# Ensure permissions
RUN chmod +x "/app/gateway-${PLATFORM}" || true && \
    chmod +x /app/modules/ppanel-server || true

# Expose any port the gateway/server uses (optional, adjust as needed)
# Expose the port (optional)
EXPOSE 8080

# Run the gateway binary for the chosen platform. Note: darwin-* binaries will NOT run in a Linux container.
ENTRYPOINT ["/bin/sh", "-c", "/app/gateway-${PLATFORM}"]
CMD []

