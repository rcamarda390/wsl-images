# ============================================================
# gnosis-mcp — Offline Documentation MCP Server
# ============================================================
# Purpose:  Serves pre-processed markdown documentation to
#           air-gapped Cline agents via the MCP protocol.
#           Uses SQLite FTS5 full-text search. Zero cloud
#           dependencies at runtime. No embeddings. No API keys.
#
# Build:    Built by GitHub Actions with internet access.
#           gnosis-mcp pulled from PyPI at build time.
#           Image pushed to ghcr.io for pull into Artifactory.
#
# Runtime:  No internet required. All dependencies baked in.
#
# Ports:    6333 (MCP HTTP) — only needed if TRANSPORT=http
#           Default transport is stdio (Cline exec mode)
#
# Volumes:
#   /docs   read-only bind mount — markdown files from host
#   /db     read-write volume    — SQLite database
# ============================================================

FROM python:3.11-slim

# ============================================================
# Labels
# ============================================================
LABEL org.opencontainers.image.title="gnosis-mcp"
LABEL org.opencontainers.image.description="Offline documentation MCP server for air-gapped Cline agents"
LABEL org.opencontainers.image.source="https://github.com/rcamarda390/wsl-images"

# ============================================================
# Environment
# ============================================================
ENV GNOSIS_MCP_DB_PATH=/db/docs.db \
    GNOSIS_MCP_DOCS_PATH=/docs \
    GNOSIS_MCP_PORT=6333 \
    GNOSIS_MCP_TRANSPORT=stdio \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# ============================================================
# Create service user and runtime directories
# ============================================================
RUN groupadd -g 1100 gnosis \
    && useradd -m -u 1100 -g gnosis -s /bin/bash gnosis \
    && mkdir -p /docs /db \
    && chown -R gnosis:gnosis /docs /db

# ============================================================
# Install gnosis-mcp and all dependencies from PyPI
# This runs at GitHub Actions build time — internet available.
# At runtime on air-gapped EC2, no network calls are made.
# ============================================================
RUN pip install --no-cache-dir \
        gnosis-mcp==0.13.3 \
    && echo "--- Verifying installation ---" \
    && gnosis-mcp --version

# ============================================================
# Copy entrypoint
# ============================================================
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

# ============================================================
# Switch to service user
# ============================================================
USER gnosis
WORKDIR /home/gnosis

# ============================================================
# Expose MCP HTTP port (only used if TRANSPORT=http)
# ============================================================
EXPOSE 6333

# ============================================================
# Entrypoint
# ============================================================
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
