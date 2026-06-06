#!/usr/bin/env bash
# =============================================================================
# pull-and-save.sh — download all agentmemory images and save as .tar files
# =============================================================================
# Run this on an INTERNET-CONNECTED machine to create tarballs you can
# transfer to your air-gapped work environment and import into Artifactory
# (or load directly with: docker load -i <file>.tar).
#
# Usage:
#   ./pull-and-save.sh [output-dir]
#   REGISTRY=ghcr.io/rcamarda390/wsl-images ./pull-and-save.sh ./images
#
# Output files:
#   <output-dir>/busybox-1.36.tar
#   <output-dir>/iii-0.11.2.tar
#   <output-dir>/agentmemory-0.9.21.tar
# =============================================================================

set -euo pipefail

OUTPUT_DIR="${1:-./agentmemory-images}"
REGISTRY="${REGISTRY:-ghcr.io/rcamarda390/wsl-images}"
III_VERSION="${AGENTMEMORY_III_VERSION:-0.11.2}"
AGENTMEMORY_VERSION="${AGENTMEMORY_VERSION:-0.9.21}"

mkdir -p "$OUTPUT_DIR"

echo "[pull-and-save] Pulling images from $REGISTRY..."

docker pull "${REGISTRY}/busybox:1.36"
docker pull "${REGISTRY}/iii:${III_VERSION}"
docker pull "${REGISTRY}/agentmemory:${AGENTMEMORY_VERSION}"

echo "[pull-and-save] Saving images to $OUTPUT_DIR..."

docker save "${REGISTRY}/busybox:1.36"                    -o "$OUTPUT_DIR/busybox-1.36.tar"
docker save "${REGISTRY}/iii:${III_VERSION}"               -o "$OUTPUT_DIR/iii-${III_VERSION}.tar"
docker save "${REGISTRY}/agentmemory:${AGENTMEMORY_VERSION}" -o "$OUTPUT_DIR/agentmemory-${AGENTMEMORY_VERSION}.tar"

echo "[pull-and-save] Done. Files in $OUTPUT_DIR:"
ls -lh "$OUTPUT_DIR"/*.tar

echo ""
echo "Transfer these files to your air-gapped machine, then run:"
echo "  AGENTMEMORY_TAR_DIR=./agentmemory-images ./install.sh"
