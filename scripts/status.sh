#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

echo "==========================================="
echo " Svrnty Team — Status"
echo "==========================================="
echo ""

# Overstory
echo "--- Overstory ---"
if [ -d ".overstory" ] && command -v overstory &>/dev/null; then
    overstory status 2>&1 || warn "Could not get status"
else
    warn "Not initialized — run /hybrid:init"
fi
echo ""

# Beads
echo "--- Beads Tasks ---"
if [ -d ".beads" ] && command -v bd &>/dev/null; then
    bd list 2>&1 || info "No tasks yet"
else
    warn "Not initialized"
fi
echo ""

# Mulch
echo "--- Mulch Expertise ---"
if [ -d ".mulch" ] && command -v mulch &>/dev/null; then
    mulch status 2>&1 || info "No expertise yet"
else
    warn "Not initialized"
fi
echo ""

# Worktrees
echo "--- Worktrees ---"
git worktree list 2>&1 || warn "Not in a git repo"
echo ""

# Mail
echo "--- Agent Mail ---"
if [ -d ".overstory" ] && command -v overstory &>/dev/null; then
    overstory mail list 2>&1 || info "No mail"
fi
echo ""
