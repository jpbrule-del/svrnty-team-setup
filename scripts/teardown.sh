#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[1;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

echo "==========================================="
echo " Svrnty Team — Teardown"
echo "==========================================="
echo ""

# 1. List worktrees
echo "--- Active Worktrees ---"
git worktree list 2>&1
echo ""

# 2. Merge
echo "--- Merging Branches ---"
if command -v overstory &>/dev/null && [ -d ".overstory" ]; then
    overstory merge --all 2>&1 && ok "All branches merged" || warn "Some merges may need manual resolution"
else
    warn "Overstory not available"
fi
echo ""

# 3. Sync Beads
echo "--- Syncing Beads ---"
if command -v bd &>/dev/null && [ -d ".beads" ]; then
    bd sync 2>&1 && ok "Beads synced" || warn "Beads sync had issues"
else
    warn "Beads not available"
fi
echo ""

# 4. Mulch learn + sync
echo "--- Recording Learnings ---"
if command -v mulch &>/dev/null && [ -d ".mulch" ]; then
    mulch learn 2>&1 || true
    mulch sync 2>&1 && ok "Mulch synced" || warn "Mulch sync had issues"
else
    warn "Mulch not available"
fi
echo ""

# 5. Clean worktrees
echo "--- Cleaning Worktrees ---"
if command -v overstory &>/dev/null && [ -d ".overstory" ]; then
    overstory worktree clean 2>&1 && ok "Worktrees cleaned" || warn "Some worktrees may need manual cleanup"
else
    warn "Overstory not available"
fi
echo ""

echo "==========================================="
echo -e "${GREEN} Teardown Complete${NC}"
echo "==========================================="
