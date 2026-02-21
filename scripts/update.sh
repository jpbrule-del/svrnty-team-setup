#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Svrnty Update — Pull latest plugin and re-run setup
# ============================================================================

source "$(cd "$(dirname "$0")" && pwd)/_common.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo -e "${BOLD}==========================================="
echo " Svrnty Update"
echo -e "===========================================${NC}"
echo ""

# Read current version
OLD_VERSION=$(jq -r '.version // "unknown"' "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")
info "Current version: $OLD_VERSION"
info "Plugin path: $PLUGIN_ROOT"
echo ""

# -------------------------------------------------------
# 1. Pull latest from remote
# -------------------------------------------------------
echo -e "${BOLD}--- [1/5] Pulling Latest ---${NC}"

cd "$PLUGIN_ROOT"

# Determine the best remote (prefer origin, fallback to github, then any)
REMOTE=""
for candidate in origin github; do
    if git remote get-url "$candidate" &>/dev/null; then
        REMOTE="$candidate"
        break
    fi
done
if [ -z "$REMOTE" ]; then
    REMOTE=$(git remote | head -1)
fi

if [ -z "$REMOTE" ]; then
    fail "No git remote configured"
    exit 1
fi

REMOTE_URL=$(git remote get-url "$REMOTE" 2>/dev/null)
info "Remote: $REMOTE ($REMOTE_URL)"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
OLD_HASH=$(git rev-parse --short HEAD)

# Stash any local changes
STASHED=false
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    git stash push -m "svrnty-update: auto-stash before pull" &>/dev/null
    STASHED=true
    info "Stashed local changes"
fi

# Pull
if git pull "$REMOTE" "$BRANCH" --rebase 2>&1; then
    NEW_HASH=$(git rev-parse --short HEAD)
    if [ "$OLD_HASH" = "$NEW_HASH" ]; then
        ok "Already up to date ($NEW_HASH)"
    else
        COMMIT_COUNT=$(git rev-list --count "$OLD_HASH".."$NEW_HASH" 2>/dev/null || echo "?")
        ok "Updated: $OLD_HASH → $NEW_HASH ($COMMIT_COUNT new commit(s))"
    fi
else
    fail "Pull failed"
    if $STASHED; then
        git stash pop &>/dev/null || true
    fi
    exit 1
fi

# Restore stash
if $STASHED; then
    git stash pop &>/dev/null || warn "Could not restore stash — check 'git stash list'"
fi
echo ""

# -------------------------------------------------------
# 2. Sync all remotes
# -------------------------------------------------------
echo -e "${BOLD}--- [2/5] Syncing Remotes ---${NC}"

for r in $(git remote); do
    if [ "$r" != "$REMOTE" ]; then
        if git push "$r" "$BRANCH" 2>&1; then
            ok "Pushed to $r"
        else
            warn "Could not push to $r"
        fi
    fi
done
echo ""

# -------------------------------------------------------
# 3. Update dependencies
# -------------------------------------------------------
echo -e "${BOLD}--- [3/5] Updating Dependencies ---${NC}"

# Ensure PATH includes tool locations
[ -d "$HOME/.bun/bin" ] && export PATH="$HOME/.bun/bin:$PATH"
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# Overstory
OVERSTORY_DIR="$HOME/Developer/overstory"
OVERSTORY_REPO="${SVRNTY_OVERSTORY_REPO:-https://github.com/jpbrule-del/overstory.git}"

if [ -d "$OVERSTORY_DIR/.git" ]; then
    cd "$OVERSTORY_DIR"

    # Ensure origin points to our fork
    CURRENT_ORIGIN=$(git remote get-url origin 2>/dev/null || echo "")
    if [ "$CURRENT_ORIGIN" != "$OVERSTORY_REPO" ]; then
        git remote set-url origin "$OVERSTORY_REPO" 2>/dev/null || true
        info "Updated overstory origin to fork"
    fi

    OLD_HASH=$(git rev-parse --short HEAD)
    if git pull origin main --rebase 2>&1; then
        NEW_HASH=$(git rev-parse --short HEAD)
        if [ "$OLD_HASH" = "$NEW_HASH" ]; then
            ok "Overstory: already up to date ($NEW_HASH)"
        else
            COUNT=$(git rev-list --count "$OLD_HASH".."$NEW_HASH" 2>/dev/null || echo "?")
            ok "Overstory: $OLD_HASH → $NEW_HASH ($COUNT commit(s))"
            if command -v bun &>/dev/null; then
                bun install --silent 2>/dev/null && bun link 2>/dev/null && ok "Overstory: rebuilt" || warn "Overstory: rebuild failed"
            fi
        fi
    else
        warn "Overstory: pull failed"
    fi
    cd "$PLUGIN_ROOT"
else
    if command -v overstory &>/dev/null; then
        ok "Overstory: installed (not a git checkout, skipping update)"
    else
        warn "Overstory: not installed"
    fi
fi

# Mulch
if command -v mulch &>/dev/null && command -v npm &>/dev/null; then
    CURRENT_MULCH=$(mulch --version 2>/dev/null | tr -d '[:space:]' || echo "unknown")
    LATEST_MULCH=$(npm view mulch-cli version 2>/dev/null | tr -d '[:space:]' || echo "")
    if [ -n "$LATEST_MULCH" ] && [ "$CURRENT_MULCH" != "$LATEST_MULCH" ]; then
        info "Mulch: $CURRENT_MULCH → $LATEST_MULCH"
        npm install -g mulch-cli@latest 2>&1 && ok "Mulch: updated to $LATEST_MULCH" || warn "Mulch: update failed"
    else
        ok "Mulch: $CURRENT_MULCH (latest)"
    fi
else
    warn "Mulch: not installed or npm not available"
fi

# Beads
if command -v bd &>/dev/null && command -v npm &>/dev/null; then
    CURRENT_BD=$(bd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    LATEST_BD=$(npm view @beads/bd version 2>/dev/null | tr -d '[:space:]' || echo "")
    if [ -n "$LATEST_BD" ] && [ "$CURRENT_BD" != "$LATEST_BD" ]; then
        info "Beads: $CURRENT_BD → $LATEST_BD"
        npm install -g @beads/bd@latest 2>&1 && ok "Beads: updated to $LATEST_BD" || warn "Beads: update failed"
    else
        ok "Beads: $CURRENT_BD (latest)"
    fi
else
    warn "Beads: not installed or npm not available"
fi
echo ""

# -------------------------------------------------------
# 4. Re-run setup
# -------------------------------------------------------
echo -e "${BOLD}--- [4/5] Re-running Setup ---${NC}"

if [ -f "$PLUGIN_ROOT/setup.sh" ]; then
    bash "$PLUGIN_ROOT/setup.sh" 2>&1 || warn "Setup reported issues"
else
    fail "setup.sh not found at $PLUGIN_ROOT"
fi
echo ""

# -------------------------------------------------------
# 5. Version check
# -------------------------------------------------------
echo -e "${BOLD}--- [5/5] Version Check ---${NC}"

NEW_VERSION=$(jq -r '.version // "unknown"' "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")
if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
    ok "Version: $NEW_VERSION (unchanged)"
else
    ok "Updated: $OLD_VERSION → $NEW_VERSION"
fi
echo ""

echo "==========================================="
echo -e "${GREEN}${BOLD} Update Complete${NC}"
echo "==========================================="
echo ""
echo "Plugin: v${NEW_VERSION}"
echo "Path:   $PLUGIN_ROOT"
echo ""
echo "Next: restart Claude Code to load the new plugin version."
echo "  In any project, run /svrnty-team-setup:doctor to sync it."
echo ""
