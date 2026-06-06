#!/usr/bin/env bash
# =============================================================================
# agentmemory WSL2 install script
# =============================================================================
# Run this ONCE inside your WSL2 distro to set up agentmemory as a systemd
# service that starts automatically at WSL2 boot.
#
# Usage:
#   chmod +x install.sh
#   ./install.sh
#
# What it does:
#   1. Verifies systemd and Docker are present
#   2. Copies compose files to /opt/agentmemory
#   3. Creates .env from template (if not already present)
#   4. Installs and enables the systemd service
#   5. Pulls / loads Docker images (internet or local tar)
#   6. Starts the stack and verifies health
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_DIR="$SCRIPT_DIR/.."     # agentmemory/ directory
INSTALL_DIR="/opt/agentmemory"
SERVICE_FILE="$COMPOSE_DIR/systemd/agentmemory.service"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[info]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }

# ---- preflight checks -------------------------------------------------------

if [ "$EUID" -eq 0 ]; then
  error "Do not run as root. Run as your normal WSL2 user (sudo will be used as needed)."
  exit 1
fi

if ! command -v docker &>/dev/null; then
  error "Docker is not installed. Install Docker Desktop on Windows and enable WSL2 integration."
  exit 1
fi

if ! systemctl --version &>/dev/null 2>&1; then
  error "systemd is not running. Add 'systemd=true' to /etc/wsl.conf, then run 'wsl --shutdown' and restart WSL2."
  exit 1
fi

info "Preflight checks passed."

# ---- copy files to install dir ----------------------------------------------

info "Installing compose files to $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR"
sudo cp "$COMPOSE_DIR/docker-compose.yml"    "$INSTALL_DIR/"
sudo cp "$COMPOSE_DIR/iii-config.wsl.yaml"  "$INSTALL_DIR/"
sudo chown -R "$USER:$USER" "$INSTALL_DIR"

# Create .env from template if not already present
if [ ! -f "$INSTALL_DIR/.env" ]; then
  cp "$COMPOSE_DIR/.env.example" "$INSTALL_DIR/.env"
  warn ".env created from template at $INSTALL_DIR/.env"
  warn "Edit it to configure your LLM provider before starting the service."
else
  info ".env already exists at $INSTALL_DIR/.env — not overwriting."
fi

# ---- install systemd service ------------------------------------------------

info "Installing systemd service..."
# Patch the COMPOSE_DIR in the service file to the actual install path
sed "s|/opt/agentmemory|$INSTALL_DIR|g" "$SERVICE_FILE" \
  | sudo tee /etc/systemd/system/agentmemory.service > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable agentmemory
info "agentmemory.service enabled."

# ---- pull or load images ----------------------------------------------------

# Check if a local tar directory was provided (for air-gapped import)
TAR_DIR="${AGENTMEMORY_TAR_DIR:-}"
if [ -n "$TAR_DIR" ] && [ -d "$TAR_DIR" ]; then
  info "Loading Docker images from $TAR_DIR..."
  for tar_file in "$TAR_DIR"/*.tar; do
    [ -f "$tar_file" ] || continue
    info "  Loading $tar_file"
    docker load -i "$tar_file"
  done
else
  info "Pulling Docker images from registry..."
  docker compose -f "$INSTALL_DIR/docker-compose.yml" pull
fi

# ---- start and verify -------------------------------------------------------

info "Starting agentmemory stack..."
sudo systemctl start agentmemory

info "Waiting for agentmemory to be healthy (up to 60s)..."
for i in $(seq 1 12); do
  if curl -sf http://localhost:3111/livez >/dev/null 2>&1; then
    echo
    info "agentmemory is running. REST API: http://localhost:3111"
    info ""
    info "Next step: configure Cline in VSCode."
    info "  Copy cline/cline_mcp_settings.json into your Cline MCP settings."
    info "  See the README for step-by-step instructions."
    exit 0
  fi
  printf "."
  sleep 5
done

echo
warn "agentmemory did not respond to /livez within 60s."
warn "Check status: sudo systemctl status agentmemory"
warn "View logs:    docker compose -f $INSTALL_DIR/docker-compose.yml logs -f"
exit 1
