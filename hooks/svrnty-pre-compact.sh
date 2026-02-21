#!/usr/bin/env bash
# Hook: PreCompact
# Purpose: Reload critical context before conversation compaction

set -euo pipefail

# Env var migration: support both SVRNTY_ and legacy HYBRID_ prefixes
WORKTREE_PATH="${SVRNTY_WORKTREE_PATH:-${HYBRID_WORKTREE_PATH:-}}"

OUTPUT=""

# Reload in-progress Beads tasks
if command -v bd &>/dev/null && [ -d ".beads" ]; then
    IN_PROGRESS=$(bd list --status in_progress 2>/dev/null || true)
    if [ -n "$IN_PROGRESS" ]; then
        OUTPUT+="## Active Beads Tasks (restored after compaction)\n${IN_PROGRESS}\n\n"
    fi
fi

# Reload compact Mulch priming
if command -v mulch &>/dev/null && [ -d ".mulch" ]; then
    PRIMED=$(mulch prime --compact 2>/dev/null || mulch prime 2>/dev/null || true)
    if [ -n "$PRIMED" ]; then
        OUTPUT+="## Mulch Expertise (restored after compaction)\n${PRIMED}\n\n"
    fi
fi

# Reload Overstory agent status
if command -v overstory &>/dev/null && [ -d ".overstory" ]; then
    STATUS=$(overstory status 2>/dev/null || true)
    if [ -n "$STATUS" ]; then
        OUTPUT+="## Overstory Status (restored after compaction)\n${STATUS}\n\n"
    fi
fi

# Remind about worktree boundary if applicable
if [ -n "${WORKTREE_PATH:-}" ]; then
    OUTPUT+="## Worktree Boundary Reminder\n"
    OUTPUT+="You are a teammate. Your worktree is: ${WORKTREE_PATH}\n"
    OUTPUT+="Work ONLY within this directory. Do NOT modify files outside it.\n\n"
fi

if [ -n "$OUTPUT" ]; then
    echo -e "$OUTPUT"
fi
