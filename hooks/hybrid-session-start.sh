#!/usr/bin/env bash
# Hook: SessionStart
# Purpose: Load Beads task context, Mulch expertise, and Overstory status into session

set -euo pipefail

OUTPUT=""

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
