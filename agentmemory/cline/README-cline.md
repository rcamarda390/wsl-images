# Connecting Cline to agentmemory

## How it works

Cline spawns the agentmemory MCP shim as a stdio subprocess each time a
conversation starts. The shim is a lightweight proxy that forwards MCP calls
to the agentmemory REST API running at `http://localhost:3111` (inside WSL2,
forwarded to Windows localhost automatically by WSL2).

The MCP shim is run via `docker run --rm -i --network host` so it shares the
WSL2 network stack and can reach `localhost:3111` directly.

## Setup steps

### 1. Verify agentmemory is running

In WSL2:
```bash
curl http://localhost:3111/livez
# Expected: {"status":"ok"} or similar
```

If it isn't running:
```bash
sudo systemctl start agentmemory
# or manually:
docker compose -f /opt/agentmemory/docker-compose.yml up -d
```

### 2. Open Cline MCP settings in VSCode

In VSCode: `Ctrl+Shift+P` → "Cline: Open MCP Settings" (or edit `cline_mcp_settings.json` directly).

The settings file is typically at:
- Windows: `%APPDATA%\Code\User\globalStorage\saoudrizwan.claude-dev\settings\cline_mcp_settings.json`

### 3. Merge the config

Copy the contents of `cline_mcp_settings.json` from this directory into
your Cline MCP settings. If you already have other MCP servers configured,
add the `"agentmemory"` block inside the existing `"mcpServers"` object.

### 4. Update the image tag for Artifactory (work)

Replace `ghcr.io/rcamarda390/wsl-images/agentmemory:0.9.21` with your
internal Artifactory path, e.g.:
```
your-artifactory.example.com/docker-local/agentmemory:0.9.21
```

### 5. Test it

Reload VSCode window (`Ctrl+Shift+P` → "Developer: Reload Window"), then
start a new Cline conversation. You should see agentmemory tools available:
- `memory_save`
- `memory_recall`
- `memory_smart_search`
- `memory_sessions`
- `memory_export`
- `memory_audit`
- `memory_governance_delete`

## Troubleshooting

**MCP shim shows "no server reachable"**
The shim fell back to local InMemoryKV (still functional, just not persistent).
Check: `curl http://localhost:3111/livez` — is agentmemory up?

**`wsl` command not found in PATH**
Ensure `C:\Windows\System32` is in your Windows PATH, or use the full path
`C:\Windows\System32\wsl.exe` in the Cline command.

**Container starts slowly on first call**
Docker image cold-start adds ~2s per conversation. After the first start,
subsequent calls in the same conversation are fast (container stays running
for the conversation duration).
