#!/usr/bin/env bash
# Hook: TeammateIdle — Warn about uncommitted changes in worktree
set -euo pipefail

if [ -n "${HYBRID_WORKTREE_PATH:-}" ] && [ -d "$HYBRID_WORKTREE_PATH" ]; then
    cd "$HYBRID_WORKTREE_PATH"
    DIRTY=$(git status --porcelain 2>/dev/null || true)
    if [ -n "$DIRTY" ]; then
        FILE_COUNT=$(echo "$DIRTY" | wc -l | tr -d ' ')
        echo "WARNING: Teammate has $FILE_COUNT uncommitted file(s) in worktree:"
        echo "$DIRTY" | head -10
        [ "$FILE_COUNT" -gt 10 ] && echo "... and $((FILE_COUNT - 10)) more"
        echo "Consider committing: git add -A && git commit -m 'wip: checkpoint'"
    fi
fi
