#!/usr/bin/env bash
# Hook: Auto-update check on session start
# Purpose: Silently check for plugin + dependency updates and apply them
#
# Design:
#   - Fast: only does git fetch + compare, skips if already current
#   - Throttled: checks at most once per hour (via timestamp file)
#   - Silent: outputs a one-line summary, no interactive prompts
#   - Cascading: updates plugin → overstory → mulch → beads in order

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
STAMP_FILE="$PLUGIN_ROOT/.last-update-check"
COOLDOWN=3600  # seconds (1 hour)

# --- Throttle: skip if checked recently ---
if [ -f "$STAMP_FILE" ]; then
    LAST_CHECK=$(cat "$STAMP_FILE" 2>/dev/null || echo "0")
    NOW=$(date +%s)
    ELAPSED=$((NOW - LAST_CHECK))
    if [ "$ELAPSED" -lt "$COOLDOWN" ]; then
        exit 0
    fi
fi

# Record this check
date +%s > "$STAMP_FILE"

UPDATED=""

# Ensure PATH includes common tool locations
[ -d "$HOME/.bun/bin" ] && export PATH="$HOME/.bun/bin:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# --- 1. Plugin self-update ---
cd "$PLUGIN_ROOT"
REMOTE=""
for candidate in origin github; do
    if git remote get-url "$candidate" &>/dev/null; then
        REMOTE="$candidate"
        break
    fi
done

if [ -n "$REMOTE" ]; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    OLD_HASH=$(git rev-parse HEAD 2>/dev/null || echo "")

    # Quick fetch (no merge yet)
    git fetch "$REMOTE" "$BRANCH" --quiet 2>/dev/null || true

    REMOTE_HASH=$(git rev-parse "refs/remotes/$REMOTE/$BRANCH" 2>/dev/null || echo "")

    if [ -n "$REMOTE_HASH" ] && [ "$OLD_HASH" != "$REMOTE_HASH" ]; then
        # Stash, pull, restore
        STASHED=false
        if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
            git stash push -m "auto-update" --quiet 2>/dev/null && STASHED=true
        fi

        if git pull "$REMOTE" "$BRANCH" --rebase --quiet 2>/dev/null; then
            NEW_HASH=$(git rev-parse --short HEAD)
            COUNT=$(git rev-list --count "$OLD_HASH".."$NEW_HASH" 2>/dev/null || echo "?")
            UPDATED+="plugin(${COUNT} commits) "
        fi

        if $STASHED; then
            git stash pop --quiet 2>/dev/null || true
        fi

        # Sync to other remotes silently
        for r in $(git remote); do
            if [ "$r" != "$REMOTE" ]; then
                git push "$r" "$BRANCH" --quiet 2>/dev/null || true
            fi
        done
    fi
fi

# --- 2. Overstory update ---
OVERSTORY_DIR="$HOME/Developer/overstory"
OVERSTORY_REPO="${SVRNTY_OVERSTORY_REPO:-https://github.com/jpbrule-del/overstory.git}"

if [ -d "$OVERSTORY_DIR/.git" ]; then
    cd "$OVERSTORY_DIR"

    # Ensure origin points to our fork
    CURRENT_ORIGIN=$(git remote get-url origin 2>/dev/null || echo "")
    if [ "$CURRENT_ORIGIN" != "$OVERSTORY_REPO" ]; then
        git remote set-url origin "$OVERSTORY_REPO" 2>/dev/null || true
    fi

    OLD_HASH=$(git rev-parse HEAD 2>/dev/null || echo "")
    git fetch origin main --quiet 2>/dev/null || true
    REMOTE_HASH=$(git rev-parse refs/remotes/origin/main 2>/dev/null || echo "")

    if [ -n "$REMOTE_HASH" ] && [ "$OLD_HASH" != "$REMOTE_HASH" ]; then
        if git pull origin main --rebase --quiet 2>/dev/null; then
            NEW_HASH=$(git rev-parse --short HEAD)
            COUNT=$(git rev-list --count "$OLD_HASH".."$NEW_HASH" 2>/dev/null || echo "?")
            UPDATED+="overstory(${COUNT}) "

            # Rebuild if source changed
            if command -v bun &>/dev/null; then
                bun install --silent 2>/dev/null || true
                bun link 2>/dev/null || true
            fi
        fi
    fi
fi

# --- 3. Mulch update ---
if command -v mulch &>/dev/null && command -v npm &>/dev/null; then
    CURRENT_MULCH=$(mulch --version 2>/dev/null | tr -d '[:space:]' || echo "0")
    LATEST_MULCH=$(npm view mulch-cli version 2>/dev/null | tr -d '[:space:]' || echo "")

    if [ -n "$LATEST_MULCH" ] && [ "$CURRENT_MULCH" != "$LATEST_MULCH" ]; then
        npm install -g mulch-cli@latest --silent 2>/dev/null && UPDATED+="mulch(${CURRENT_MULCH}→${LATEST_MULCH}) " || true
    fi
fi

# --- 4. Beads update ---
if command -v bd &>/dev/null && command -v npm &>/dev/null; then
    CURRENT_BD=$(bd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "0")
    LATEST_BD=$(npm view @beads/bd version 2>/dev/null | tr -d '[:space:]' || echo "")

    if [ -n "$LATEST_BD" ] && [ "$CURRENT_BD" != "$LATEST_BD" ]; then
        npm install -g @beads/bd@latest --silent 2>/dev/null && UPDATED+="beads(${CURRENT_BD}→${LATEST_BD}) " || true
    fi
fi

# --- Output summary ---
if [ -n "$UPDATED" ]; then
    echo "🔄 Auto-updated: ${UPDATED}"
fi
