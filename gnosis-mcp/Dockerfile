# ============================================================
# gnosis-mcp — Offline Documentation MCP Server
# ============================================================
# Purpose:  Serves pre-processed markdown documentation to
#           air-gapped Cline agents via the MCP protocol.
#           Uses SQLite FTS5 full-text search. Zero cloud
#           dependencies. No embeddings. No API keys.
#
# Base:     Python 3.11 slim (UBI9 from Artifactory)
# Runtime:  gnosis-mcp 0.13.3 via pip (wheel in docker/files/)
# Storage:  SQLite DB built at container startup from /docs/
#
# Build:    docker build -t gnosis-mcp-image .
# Run:      docker run -d \
#             --name gnosis-mcp \
#             -p 6333:6333 \
#             -v /opt/gnosis-mcp/docs:/docs:ro \
#             -v /opt/gnosis-mcp/db:/db \
#             gnosis-mcp-image
# ============================================================

FROM artifactory.foobar.com/feds-docker/feds-ubi9-python3.11:latest

# ============================================================
# Labels
# ============================================================
LABEL maintainer="datashift-team"
LABEL description="gnosis-mcp offline documentation MCP server"
LABEL version="0.13.3"

# ============================================================
# Environment
# ============================================================
ENV GNOSIS_MCP_DB_PATH=/db/docs.db \
    GNOSIS_MCP_DOCS_PATH=/docs \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# ============================================================
# Install OS packages
# ============================================================
RUN dnf install -y \
        findutils \
        shadow-utils \
    && dnf clean all \
    && rm -rf /var/cache/dnf /var/cache/yum /tmp/* /var/tmp/*

# ============================================================
# Create service user
# ============================================================
RUN getent group gnosis >/dev/null 2>&1 || groupadd -g 1100 gnosis \
    && useradd -m -u 1100 -g gnosis -s /bin/bash gnosis

# ============================================================
# Create runtime directories
# ============================================================
RUN mkdir -p /docs /db \
    && chown -R gnosis:gnosis /docs /db

# ============================================================
# Copy files directory for package installation
# Place gnosis_mcp-*.whl in docker/files/ before building.
# All other dependencies (mcp, click, aiofiles, anyio,
# starlette, httpx) resolve from Artifactory PyPI.
# ============================================================
COPY docker/files/ /opt/files/

# ============================================================
# Install pip dependencies
# ============================================================
RUN pip3 install --no-input --no-cache-dir --upgrade pip \
    && pip3 install \
        --no-input \
        --no-cache-dir \
        --index-url https://artifactory.foobar.com/artifactory/api/pypi/feds-pypi-local/simple/ \
        mcp \
        click \
        aiofiles \
        anyio \
        starlette \
        httpx \
    && echo "--- Installing gnosis-mcp from bundled wheel ---" \
    && wheel=$(ls /opt/files/gnosis_mcp-*.whl 2>/dev/null | head -1) \
    && if [ -n "$wheel" ]; then \
           echo "Installing: $(basename $wheel)"; \
           pip3 install --no-input --no-cache-dir "$wheel"; \
       else \
           echo "ERROR: gnosis-mcp wheel not found in docker/files/"; \
           echo "Download from: https://pypi.org/project/gnosis-mcp/#files"; \
           exit 1; \
       fi \
    && rm -rf /root/.cache /tmp/* /var/tmp/* /opt/files \
    && echo "--- Verifying gnosis-mcp installation ---" \
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

# ============================================================
# Expose MCP HTTP port
# ============================================================
EXPOSE 6333

# ============================================================
# Healthcheck
# ============================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD gnosis-mcp stats 2>/dev/null | grep -q "chunks" || exit 1

# ============================================================
# Entrypoint
# ============================================================
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
