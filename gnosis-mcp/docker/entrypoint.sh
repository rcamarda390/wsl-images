#!/bin/bash
# ============================================================
# gnosis-mcp entrypoint
# ============================================================
# 1. Ingest markdown docs from /docs/ into SQLite at /db/docs.db
# 2. Serve MCP endpoint on port 6333
#
# Mount points:
#   /docs  — markdown files (read-only, bind-mounted from host)
#   /db    — SQLite database (read-write, persisted volume)
# ============================================================

set -e

DOCS_PATH="${GNOSIS_MCP_DOCS_PATH:-/docs}"
DB_PATH="${GNOSIS_MCP_DB_PATH:-/db/docs.db}"
PORT="${GNOSIS_MCP_PORT:-6333}"

echo "============================================"
echo " gnosis-mcp starting"
echo "============================================"
echo " docs:     $DOCS_PATH"
echo " database: $DB_PATH"
echo " port:     $PORT"
echo ""

# ============================================================
# Verify docs directory has content
# ============================================================
doc_count=$(find "$DOCS_PATH" -name "*.md" 2>/dev/null | wc -l)
echo "Found $doc_count markdown files in $DOCS_PATH"

if [ "$doc_count" -eq 0 ]; then
    echo ""
    echo "WARNING: No markdown files found in $DOCS_PATH"
    echo "The server will start but searches will return no results."
    echo "Mount your docs directory to $DOCS_PATH and restart."
    echo ""
fi

# ============================================================
# Ingest docs into SQLite
# Always re-ingest on startup so doc updates are picked up
# when the container restarts. Uses gnosis-mcp's built-in
# incremental indexing -- unchanged files are skipped quickly.
# ============================================================
if [ "$doc_count" -gt 0 ]; then
    echo ""
    echo "--- Ingesting documentation ---"
    gnosis-mcp ingest "$DOCS_PATH" \
        --db "$DB_PATH" \
        --prune
    echo "--- Ingest complete ---"
    echo ""

    echo "--- Index stats ---"
    gnosis-mcp stats --db "$DB_PATH" 2>/dev/null || true
    echo ""
fi

# ============================================================
# Start MCP server
# Serves stdio (default) or HTTP depending on transport.
# Cline connects via stdio launched by the MCP config.
# For HTTP mode set GNOSIS_MCP_TRANSPORT=http
# ============================================================
TRANSPORT="${GNOSIS_MCP_TRANSPORT:-stdio}"

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
