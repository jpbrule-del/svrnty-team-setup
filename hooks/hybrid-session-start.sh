#!/usr/bin/env bash
# Hook: SessionStart
# Purpose: Auto-update plugin + deps, then load context into session

set -euo pipefail

# Auto-update check (throttled, runs at most once per hour)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
if [ -f "$PLUGIN_ROOT/hooks/auto-update.sh" ]; then
    UPDATE_MSG=$(bash "$PLUGIN_ROOT/hooks/auto-update.sh" 2>/dev/null || true)
fi

OUTPUT=""

# Show update results if anything was updated
if [ -n "${UPDATE_MSG:-}" ]; then
    OUTPUT+="${UPDATE_MSG}\n\n"
fi

# Load Mulch priming context
if command -v mulch &>/dev/null && [ -d ".mulch" ]; then
    PRIMED=$(mulch prime 2>/dev/null || true)
    if [ -n "$PRIMED" ]; then
        OUTPUT+="${PRIMED}\n\n"
    fi
fi

# Load Overstory agent status
if command -v overstory &>/dev/null && [ -d ".overstory" ]; then
    STATUS=$(overstory status 2>/dev/null || true)
    if [ -n "$STATUS" ]; then
        OUTPUT+="## Overstory Status\n${STATUS}\n\n"
    fi
fi

# Load ready and in-progress Beads tasks
if command -v bd &>/dev/null; then
    READY=$(bd list --status ready 2>/dev/null || true)
    IN_PROGRESS=$(bd list --status in_progress 2>/dev/null || true)
    if [ -n "$READY" ] || [ -n "$IN_PROGRESS" ]; then
        OUTPUT+="## Beads Tasks\n"
        if [ -n "$IN_PROGRESS" ]; then
            OUTPUT+="### In Progress:\n${IN_PROGRESS}\n\n"
        fi
        if [ -n "$READY" ]; then
            OUTPUT+="### Ready:\n${READY}\n\n"
        fi
    fi
fi

# Output as context injection
if [ -n "$OUTPUT" ]; then
    echo -e "$OUTPUT"
fi
