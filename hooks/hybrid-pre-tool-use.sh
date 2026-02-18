#!/usr/bin/env bash
# Hook: PreToolUse (matcher: Edit|Write|Bash)
# Block dangerous git ops + enforce worktree boundary for teammates
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty' 2>/dev/null || true)

# --- Block dangerous git operations ---
if [ "$TOOL_NAME" = "Bash" ]; then
    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null || true)

    if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f|--force)'; then
        echo '{"decision": "block", "reason": "Force push is forbidden."}'
        exit 0
    fi
    if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
        echo '{"decision": "block", "reason": "Hard reset is forbidden."}'
        exit 0
    fi
    if echo "$COMMAND" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
        echo '{"decision": "block", "reason": "git clean -f is forbidden."}'
        exit 0
    fi
    if echo "$COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f.*(/|\./)'; then
        echo '{"decision": "block", "reason": "Recursive force-delete on directories is forbidden."}'
        exit 0
    fi
fi

# --- Enforce worktree boundary for teammates ---
if [ -n "${HYBRID_WORKTREE_PATH:-}" ]; then
    FILE_PATH=""
    if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
        FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null || true)
    elif [ "$TOOL_NAME" = "Bash" ]; then
        COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null || true)
        if echo "$COMMAND" | grep -qE '^(cat|head|tail|less|ls|find|grep|rg|git\s+(status|log|diff|show|branch))'; then
            echo '{"decision": "allow"}'
            exit 0
        fi
    fi

    if [ -n "$FILE_PATH" ]; then
        RESOLVED=$(cd "$(dirname "$FILE_PATH")" 2>/dev/null && pwd)/$(basename "$FILE_PATH") || RESOLVED="$FILE_PATH"
        WORKTREE_RESOLVED=$(cd "$HYBRID_WORKTREE_PATH" 2>/dev/null && pwd) || WORKTREE_RESOLVED="$HYBRID_WORKTREE_PATH"
        if [[ ! "$RESOLVED" == "$WORKTREE_RESOLVED"* ]]; then
            echo "{\"decision\": \"block\", \"reason\": \"Teammate boundary violation: file '$FILE_PATH' is outside your worktree at '$HYBRID_WORKTREE_PATH'.\"}"
            exit 0
        fi
    fi
fi

echo '{"decision": "allow"}'
