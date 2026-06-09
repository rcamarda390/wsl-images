# gnosis-mcp — Offline Documentation MCP Server

Serves pre-processed markdown documentation to air-gapped Cline agents
via the MCP protocol. Uses SQLite FTS5 full-text search. Zero cloud
dependencies, no embeddings, no API keys.

## Architecture

```
[Claude Chat (internet)]          [EC2 — air-gapped]
  │                                     │
  │  Claude processes raw docs           │
  │  → clean markdown files             │
  │                                     │
  └──── SCP markdown tarball ──────────►│
                                        │
                              /opt/gnosis-mcp/docs/
                                        │
                              Docker container
                              gnosis-mcp ingest → SQLite
                              gnosis-mcp serve  → MCP
                                        │
                              Cline queries via MCP
```

## Folder Structure

```
gnosis-mcp/
├── Dockerfile              # Container definition
├── docker-compose.yml      # For local EC2 testing
├── .gitignore
├── docker/
│   ├── entrypoint.sh       # Ingest + serve on startup
│   └── files/
│       ├── README.md       # Instructions for wheel placement
│       └── gnosis_mcp-*.whl  ← download this, do not commit
└── docs/                   # (gitignored) example doc structure
```

## Quick Start

### Step 1 — Get the gnosis-mcp wheel (internet machine)

Download from https://pypi.org/project/gnosis-mcp/#files

Place in `docker/files/gnosis_mcp-0.13.3-py3-none-any.whl`

### Step 2 — Build the image (on EC2)

```bash
cd gnosis-mcp
docker build -t gnosis-mcp-image .
```

### Step 3 — Prepare docs directory (on EC2)

```bash
sudo mkdir -p /opt/gnosis-mcp/docs
sudo mkdir -p /opt/gnosis-mcp/db
```

SCP your processed markdown files into `/opt/gnosis-mcp/docs/`.

Recommended structure:
```
/opt/gnosis-mcp/docs/
├── airflow/
│   ├── operators.md
│   ├── hooks.md
│   └── dag-authoring.md
├── redshift/
│   ├── sql-reference.md
│   └── data-types.md
├── sqlglot/
│   └── api-reference.md
└── ...
```

### Step 4 — Run (on EC2)

```bash
docker compose up -d
docker compose logs -f
```

### Step 5 — Configure Cline

Add to your Cline MCP config (`~/.cline/mcp-settings.json`):

```json
{
  "mcpServers": {
    "gnosis-docs": {
      "command": "docker",
      "args": [
        "exec", "-i", "gnosis-mcp",
        "gnosis-mcp", "serve", "--db", "/db/docs.db"
      ]
    }
  }
}
```

Or if running in HTTP mode:

```json
{
  "mcpServers": {
    "gnosis-docs": {
      "url": "http://localhost:6333/mcp"
    }
  }
}
```

## Updating Docs

1. Process new/updated docs via Claude Chat → download markdown
2. SCP to `/opt/gnosis-mcp/docs/`
3. Restart the container — it re-ingests automatically on startup,
   skipping unchanged files (incremental indexing)

```bash
docker compose restart gnosis-mcp
```

## Troubleshooting

```bash
# Check container status
docker compose ps

# View startup logs (ingest output)
docker compose logs gnosis-mcp

# Check how many chunks are indexed
docker exec gnosis-mcp gnosis-mcp stats --db /db/docs.db

# Test a search manually
docker exec gnosis-mcp gnosis-mcp search "DAG authoring" --db /db/docs.db

# Shell into container
docker exec -it gnosis-mcp /bin/bash
```

## Dependencies

All resolved from Artifactory during build (confirmed present):
- `mcp` — MCP Python SDK
- `click` — CLI framework
- `aiofiles` — async file I/O
- `anyio` — async runtime
- `starlette` — ASGI transport
- `httpx` — HTTP client

Not in Artifactory (bundled as wheel in `docker/files/`):
- `gnosis-mcp` — the MCP server itself
