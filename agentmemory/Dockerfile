# =============================================================================
# agentmemory Docker image
# =============================================================================
# Packages @agentmemory/agentmemory@0.9.21 into a Node 20 Alpine image.
#
# Two usage modes (controlled by CMD at runtime):
#
#   WORKER (default)
#     Connects to iii-engine via iii-sdk WebSocket.
#     docker compose handles this automatically.
#
#   MCP SHIM (for Cline/VSCode)
#     Stdio MCP proxy to the REST API at AGENTMEMORY_URL.
#     Invoked by Cline per the cline/cline_mcp_settings.json template.
#
# Build args:
#   AGENTMEMORY_VERSION  npm package version (default: 0.9.21)
#   NODE_VERSION         Node.js major version (default: 20)
# =============================================================================

ARG NODE_VERSION=20
ARG AGENTMEMORY_VERSION=0.9.21

FROM node:${NODE_VERSION}-alpine AS base

# Install only what's needed to run Node modules on Alpine
RUN apk add --no-cache tini

WORKDIR /app

# ---- install stage ----------------------------------------------------------
FROM base AS install

ARG AGENTMEMORY_VERSION

# Minimal package.json so npm has a manifest to work with
RUN echo "{\"name\":\"agentmemory-runner\",\"version\":\"1.0.0\",\"private\":true}" \
    > package.json

# --omit=optional skips the heavy Xenova/transformers local-embedding deps
# (~500 MB). If you want local (offline) vector embeddings, build with:
#   docker build --build-arg ENABLE_LOCAL_EMBEDDINGS=1 ...
# and remove the --omit=optional flag below.
ARG ENABLE_LOCAL_EMBEDDINGS=0
RUN if [ "$ENABLE_LOCAL_EMBEDDINGS" = "1" ]; then \
      npm install @agentmemory/agentmemory@${AGENTMEMORY_VERSION}; \
    else \
      npm install --omit=optional @agentmemory/agentmemory@${AGENTMEMORY_VERSION}; \
    fi

# ---- runtime stage ----------------------------------------------------------
FROM base AS runtime

# Non-root user for security (matches distroless convention)
RUN addgroup -S agentmemory && adduser -S -G agentmemory agentmemory

WORKDIR /app

COPY --from=install --chown=agentmemory:agentmemory /app/node_modules ./node_modules

# Convenience: put the dist at a short path
RUN ln -s /app/node_modules/@agentmemory/agentmemory/dist /app/dist

USER agentmemory

# Labels
ARG AGENTMEMORY_VERSION
LABEL org.opencontainers.image.title="agentmemory" \
      org.opencontainers.image.description="Persistent memory MCP for AI coding agents" \
      org.opencontainers.image.source="https://github.com/rcamarda390/wsl-images" \
      org.opencontainers.image.version="${AGENTMEMORY_VERSION}" \
      org.opencontainers.image.licenses="Apache-2.0"

# Default env — overridden in docker-compose.yml / at runtime
ENV III_ENGINE_URL=ws://iii-engine:49134 \
    AGENTMEMORY_URL=http://iii-engine:3111 \
    NODE_ENV=production

# Default: run as the persistent worker that registers with iii-engine.
# Override to "mcp" mode via:
#   docker run --rm -i <image> node /app/dist/cli.mjs mcp
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "/app/dist/index.mjs"]
