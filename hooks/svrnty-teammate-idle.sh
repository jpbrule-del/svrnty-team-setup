#!/usr/bin/env bash
# Hook: TeammateIdle — Warn about uncommitted changes in worktree
set -euo pipefail

# Env var migration: support both SVRNTY_ and legacy HYBRID_ prefixes
WORKTREE_PATH="${SVRNTY_WORKTREE_PATH:-${HYBRID_WORKTREE_PATH:-}}"

if [ -n "${WORKTREE_PATH:-}" ] && [ -d "$WORKTREE_PATH" ]; then
    cd "$WORKTREE_PATH"
    DIRTY=$(git status --porcelain 2>/dev/null || true)
    if [ -n "$DIRTY" ]; then
        FILE_COUNT=$(echo "$DIRTY" | wc -l | tr -d ' ')
        echo "WARNING: Teammate has $FILE_COUNT uncommitted file(s) in worktree:"
        echo "$DIRTY" | head -10
        [ "$FILE_COUNT" -gt 10 ] && echo "... and $((FILE_COUNT - 10)) more"
        echo "Consider committing: git add -A && git commit -m 'wip: checkpoint'"
    fi
fi
