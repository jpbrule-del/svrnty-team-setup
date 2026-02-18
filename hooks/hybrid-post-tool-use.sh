#!/usr/bin/env bash
# Hook: PostToolUse (matcher: Edit|Write) — Log file modifications async
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty' 2>/dev/null || true)

FILE_PATH=""
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || true)
fi

if [ -n "$FILE_PATH" ] && command -v overstory &>/dev/null && [ -d ".overstory" ]; then
    AGENT_NAME="${HYBRID_AGENT_NAME:-unknown}"
    overstory log "file_modified" --agent "$AGENT_NAME" --file "$FILE_PATH" --tool "$TOOL_NAME" &>/dev/null &
fi
