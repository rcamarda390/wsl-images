# agentmemory — WSL2 Docker Setup

Persistent memory MCP for Cline/VSCode, running fully in Docker on WSL2.
Based on [rohitg00/agentmemory](https://github.com/rohitg00/agentmemory) v0.9.21.

## Architecture

```
Windows VSCode (Cline)
  │
  │  stdio (wsl -e docker run --rm -i --network host)
  ▼
agentmemory MCP shim  ──── http://localhost:3111 ────►  iii-engine (Docker)
                                                              │
                                                    agentmemory-worker (Docker)
                                                    connects via iii-sdk WebSocket
                                                    ws://iii-engine:49134
```

### Containers

| Image | Purpose | Base |
|---|---|---|
| `busybox:1.36` | One-shot init — chowns `/data` volume to UID 65532 | busybox |
| `iii:0.11.2` | iii-engine backend — HTTP gateway, state, queue, pubsub, streams | distroless Rust |
| `agentmemory:0.9.21` | agentmemory worker + MCP shim | node:20-alpine |

The **MCP shim** and the **worker** are the same image — different `CMD` at runtime:
- Worker (docker-compose): `node /app/dist/index.mjs`
- MCP shim (Cline): `node /app/dist/cli.mjs mcp`

### Why iii-engine is pinned to 0.11.2

The upstream `docker-compose.yml` documents this explicitly: iii v0.11.6+ introduced a new sandbox model that agentmemory 0.9.x hasn't been refactored for. Bumping the version causes EPIPE reconnect loops and empty search results.

## Quick Start (Home / Internet)

```bash
# 1. Clone
git clone https://github.com/rcamarda390/wsl-images
cd wsl-images/agentmemory

# 2. Configure
cp .env.example .env
# Edit .env — set ANTHROPIC_API_KEY or OPENAI_API_KEY (or leave blank for noop mode)

# 3. Install (sets up systemd service + pulls images)
chmod +x scripts/install.sh
./scripts/install.sh

# 4. Configure Cline
#    Copy cline/cline_mcp_settings.json into your Cline MCP settings
#    See cline/README-cline.md for details
```

## Air-gapped Work Setup

### Step 1 — On an internet-connected machine

```bash
# Pull all images and save as tarballs
chmod +x scripts/pull-and-save.sh
./scripts/pull-and-save.sh ./images-to-transfer
```

Transfer the `.tar` files and the repo to your work machine.

### Step 2 — Import into Artifactory

Import the three `.tar` files into your internal Docker registry.
Tag them as:
```
your-artifactory.example.com/docker-local/busybox:1.36
your-artifactory.example.com/docker-local/iii:0.11.2
your-artifactory.example.com/docker-local/agentmemory:0.9.21
```

### Step 3 — Install in WSL2

```bash
# Set registry to your Artifactory host
export REGISTRY=your-artifactory.example.com/docker-local

# Load images from tarballs (skip if Artifactory pull works directly)
AGENTMEMORY_TAR_DIR=./images-to-transfer ./scripts/install.sh
```

### Step 4 — Configure LLM (AWS Bedrock via LiteLLM)

In `/opt/agentmemory/.env`:
```env
OPENAI_API_KEY=dummy-litellm-key
OPENAI_BASE_URL=http://litellm:4000/v1
OPENAI_MODEL=anthropic.claude-3-5-sonnet-20241022-v2:0
```

LiteLLM must be running and configured with your Bedrock credentials.
See the `litellm/` directory in this repo for that setup.

### Step 5 — Configure Cline

In `cline/cline_mcp_settings.json`, update the image tag:
```json
"your-artifactory.example.com/docker-local/agentmemory:0.9.21"
```

## Manual operation (no systemd)

```bash
# Start
docker compose up -d

# Stop
docker compose down

# View logs
docker compose logs -f agentmemory

# Health check
curl http://localhost:3111/livez
```

## Updating agentmemory

```bash
# Edit docker-compose.yml to change AGENTMEMORY_VERSION
# Pull new image
docker compose pull agentmemory
docker compose up -d agentmemory
```

Or re-run the GitHub Actions workflow with the new version number.

## Building locally

```bash
cd agentmemory
docker build \
  --build-arg AGENTMEMORY_VERSION=0.9.21 \
  -t agentmemory:0.9.21 \
  .
```

For local vector embeddings (air-gap semantic search without an embedding API):
```bash
docker build \
  --build-arg AGENTMEMORY_VERSION=0.9.21 \
  --build-arg ENABLE_LOCAL_EMBEDDINGS=1 \
  -t agentmemory:0.9.21-full \
  .
# Note: image size ~1GB vs ~250MB for slim
```
