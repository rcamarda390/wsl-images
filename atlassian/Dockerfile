ARG MCP_ATLASSIAN_VERSION=0.21.1

# ── build: install package into an isolated venv via uv ─────────────────────
FROM ghcr.io/astral-sh/uv:python3.13-alpine AS build
ARG MCP_ATLASSIAN_VERSION

RUN uv venv /venv
RUN uv pip install --python /venv/bin/python \
        --no-cache \
        "mcp-atlassian=${MCP_ATLASSIAN_VERSION}"

# ── runtime ──────────────────────────────────────────────────────────────────
FROM python:3.13-alpine AS runtime
COPY --from=build /venv /venv
ENV PATH="/venv/bin:$PATH"

RUN adduser -D -h /home/app -s /bin/sh app
USER app
WORKDIR /home/app

# Required for proper stdio MCP communication.
# Transport defaults to stdio; override via --transport sse|streamable-http.
#
# Auth env vars (set at runtime — never bake credentials into the image):
#   Cloud:           JIRA_URL, JIRA_USERNAME, JIRA_API_TOKEN
#                    CONFLUENCE_URL, CONFLUENCE_USERNAME, CONFLUENCE_API_TOKEN
#   Server/DC:       JIRA_URL, JIRA_PERSONAL_TOKEN, JIRA_SSL_VERIFY=false
#                    CONFLUENCE_URL, CONFLUENCE_PERSONAL_TOKEN, CONFLUENCE_SSL_VERIFY=false
#
# Custom CA (air-gapped):
#   Mount your CA bundle into the container and set
#   SSL_CERT_FILE=/path/to/ca-bundle.crt or disable verify per above.
ENV PYTHONUNBUFFERED=1

ARG MCP_ATLASSIAN_VERSION
LABEL org.opencontainers.image.title="mcp-atlassian" \
      org.opencontainers.image.description="Atlassian Jira + Confluence MCP server — Cloud and Server/Data Center" \
      org.opencontainers.image.source="https://github.com/rcamarda390/wsl-images" \
      org.opencontainers.image.version="${MCP_ATLASSIAN_VERSION}" \
      org.opencontainers.image.licenses="MIT"

ENTRYPOINT ["mcp-atlassian"]
