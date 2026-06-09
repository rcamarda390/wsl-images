#!/bin/bash
# ============================================================
# gnosis-mcp entrypoint
# ============================================================
# 1. Ingest markdown docs from /docs/ into SQLite at /db/docs.db
# 2. Serve MCP endpoint (stdio or http)
#
# Mount points expected at runtime:
#   /docs  — markdown files (read-only bind mount from host)
#   /db    — SQLite database (persisted volume)
# ============================================================

set -e

DOCS_PATH="${GNOSIS_MCP_DOCS_PATH:-/docs}"
DB_PATH="${GNOSIS_MCP_DB_PATH:-/db/docs.db}"
PORT="${GNOSIS_MCP_PORT:-6333}"
TRANSPORT="${GNOSIS_MCP_TRANSPORT:-stdio}"

echo "============================================"
echo " gnosis-mcp starting"
echo "============================================"
echo " docs:      $DOCS_PATH"
echo " database:  $DB_PATH"
echo " transport: $TRANSPORT"
if [ "$TRANSPORT" = "http" ]; then
    echo " port:      $PORT"
fi
echo ""

# ============================================================
# Count available docs
# ============================================================
doc_count=$(find "$DOCS_PATH" -name "*.md" 2>/dev/null | wc -l)
echo "Found $doc_count markdown files in $DOCS_PATH"

if [ "$doc_count" -eq 0 ]; then
    echo ""
    echo "WARNING: No markdown files found in $DOCS_PATH"
    echo "Mount processed markdown to $DOCS_PATH and restart."
    echo ""
fi

# ============================================================
# Ingest docs into SQLite
# --prune removes chunks whose source file was deleted.
# Incremental: unchanged files are skipped automatically.
# ============================================================
if [ "$doc_count" -gt 0 ]; then
    echo ""
    echo "--- Ingesting documentation ---"
    gnosis-mcp ingest "$DOCS_PATH" \
        --db "$DB_PATH" \
        --prune
    echo ""
    echo "--- Index stats ---"
    gnosis-mcp stats --db "$DB_PATH" 2>/dev/null || true
    echo ""
fi

# ============================================================
# Start MCP server
# stdio:  Cline launches container with `docker exec -i`
# http:   Cline connects to http://localhost:6333/mcp
# ============================================================
echo "--- Starting MCP server (transport: $TRANSPORT) ---"

if [ "$TRANSPORT" = "http" ]; then
    exec gnosis-mcp serve \
        --db "$DB_PATH" \
        --transport http \
        --host 0.0.0.0 \
        --port "$PORT"
else
    exec gnosis-mcp serve \
        --db "$DB_PATH"
fi
