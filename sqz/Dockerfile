# =============================================================================
# sqz Docker image
# =============================================================================
# Compiles sqz-cli and sqz-mcp from crates.io using Cargo on Alpine.
# The resulting musl binaries are fully self-contained:
#   - SQLite bundled (rusqlite "bundled" feature)
#   - tree-sitter grammar parsers bundled
#   - No shared-library runtime dependencies
#
# Two usage modes:
#
#   MCP SHIM (default — for Cline/VSCode)
#     Spawned per session via Cline's MCP stdio transport.
#     docker run --rm -i -v sqz-data:/home/sqz/.sqz <image>
#
#   CLI (override entrypoint)
#     docker run --rm --entrypoint sqz <image> compress "..."
#     docker run --rm --entrypoint sqz <image> gain
#
# Build args:
#   SQZ_VERSION   crates.io version for sqz-cli and sqz-mcp (default: 1.2.0)
#   RUST_VERSION  Rust Alpine image tag (default: 1-alpine)
# =============================================================================

ARG RUST_VERSION=1-alpine
ARG SQZ_VERSION=1.2.0

# ── build stage ──────────────────────────────────────────────────────────────
FROM rust:${RUST_VERSION} AS build

ARG SQZ_VERSION

# musl-dev: C headers needed by bundled SQLite (rusqlite "bundled") and
# tree-sitter grammar parsers. The Rust toolchain in rust:alpine already
# provides a C compiler; only the musl dev headers are missing.
RUN apk add --no-cache musl-dev

# Compile both crates. First run is slow (~15 min); subsequent runs use the
# BuildKit layer cache (cache-from: type=gha in the GitHub Actions workflow).
RUN cargo install \
    sqz-cli@${SQZ_VERSION} \
    sqz-mcp@${SQZ_VERSION}

# ── runtime stage ─────────────────────────────────────────────────────────────
FROM alpine:3.20 AS runtime

# Static binaries — no additional packages needed at runtime
COPY --from=build /usr/local/cargo/bin/sqz     /usr/local/bin/sqz
COPY --from=build /usr/local/cargo/bin/sqz-mcp /usr/local/bin/sqz-mcp

# Non-root user for security
RUN addgroup -S sqz && adduser -S -G sqz sqz

USER sqz
WORKDIR /home/sqz

# SQLite database (sessions.db), compression cache, and custom presets.
# Create a named volume for persistence across container restarts:
#   docker volume create sqz-data
VOLUME ["/home/sqz/.sqz"]

# Labels
ARG SQZ_VERSION
LABEL org.opencontainers.image.title="sqz" \
      org.opencontainers.image.description="LLM context compressor — MCP stdio server and CLI" \
      org.opencontainers.image.source="https://github.com/rcamarda390/wsl-images" \
      org.opencontainers.image.version="${SQZ_VERSION}" \
      org.opencontainers.image.licenses="ELv2"

# Default: MCP stdio server for Cline/VSCode.
# For CLI mode: docker run --rm --entrypoint sqz <image> <command>
ENTRYPOINT ["sqz-mcp", "--transport", "stdio"]
