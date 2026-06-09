# gnosis-mcp — Offline Documentation MCP Server

Serves pre-processed markdown documentation to air-gapped Cline agents
via the MCP protocol. Uses SQLite FTS5 full-text search. Zero cloud
dependencies at runtime. No embeddings. No API keys.

## How it works

```
[This Claude Chat]              [GitHub Actions]         [EC2 — air-gapped]
  │                                   │                        │
  │ Processes raw docs                │ Builds Docker image    │
  │ → clean markdown                  │ (pulls gnosis-mcp      │
  │                                   │  from PyPI)            │
  │                                   │ Pushes to ghcr.io      │
  │                                   │                        │
  └── SCP markdown ──────────────────────────────────────────►│
                                                               │
                                      docker pull ghcr.io/... ◄┘
                                                               │
                                              /opt/gnosis-mcp/docs/
                                                               │
                                            gnosis-mcp ingest → SQLite
                                            gnosis-mcp serve  → MCP
                                                               │
                                            Cline queries via MCP
```

## Folder Structure

```
gnosis-mcp/
├── Dockerfile                        # Container definition
├── .github/
│   └── workflows/
│       └── build.yml                 # GitHub Actions — manual trigger
├── docker/
│   └── entrypoint.sh                 # Ingest + serve on startup
└── README.md
```

## Build the Image

1. Go to **Actions** tab in this repo
2. Select **Build gnosis-mcp image**
3. Click **Run workflow**
4. Optionally enter a version tag (e.g. `0.13.3`)
5. Click **Run workflow**

Image is pushed to: `ghcr.io/rcamarda390/gnosis-mcp:latest`

## Deploy on EC2

```bash
# Pull image (run from network-accessible side)
docker pull ghcr.io/rcamarda390/gnosis-mcp:latest

# Create host directories for docs and database
sudo mkdir -p /opt/gnosis-mcp/docs
sudo mkdir -p /opt/gnosis-mcp/db

# SCP processed markdown docs into /opt/gnosis-mcp/docs/
# (see doc processing workflow below)

# Run container
docker run -d \
  --name gnosis-mcp \
  --restart unless-stopped \
  -v /opt/gnosis-mcp/docs:/docs:ro \
  -v gnosis-db:/db \
  ghcr.io/rcamarda390/gnosis-mcp:latest

# Check logs (ingest output)
docker logs -f gnosis-mcp
```

## Configure Cline (stdio mode — recommended)

Add to `~/.cline/mcp-settings.json`:

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

## Updating Docs

1. Process new docs via Claude Chat → download markdown
2. SCP markdown to `/opt/gnosis-mcp/docs/`
3. Restart container to re-ingest:

```bash
docker restart gnosis-mcp
docker logs -f gnosis-mcp
```

## Troubleshooting

```bash
# Check indexed chunk count
docker exec gnosis-mcp gnosis-mcp stats --db /db/docs.db

# Test a search manually
docker exec gnosis-mcp gnosis-mcp search "DAG authoring" --db /db/docs.db

# Shell into container
docker exec -it gnosis-mcp /bin/bash
```
