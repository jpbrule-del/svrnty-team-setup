#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Svrnty Update — Pull latest plugin and re-run setup
# ============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[1;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

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
echo -e "${BOLD}--- [1/4] Pulling Latest ---${NC}"

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
echo -e "${BOLD}--- [2/4] Syncing Remotes ---${NC}"

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
# 3. Re-run setup
# -------------------------------------------------------
echo -e "${BOLD}--- [3/4] Re-running Setup ---${NC}"

if [ -f "$PLUGIN_ROOT/setup.sh" ]; then
    bash "$PLUGIN_ROOT/setup.sh" 2>&1 || warn "Setup reported issues"
else
    fail "setup.sh not found at $PLUGIN_ROOT"
fi
echo ""

# -------------------------------------------------------
# 4. Version check
# -------------------------------------------------------
echo -e "${BOLD}--- [4/4] Version Check ---${NC}"

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
echo "  In any project, run /svrnty:doctor to sync it."
echo ""
