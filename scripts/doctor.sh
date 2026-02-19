#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Svrnty Doctor — Repair project and sync to latest plugin version
# ============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[1;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

FIXED=0
WARNINGS=0
ERRORS=0

echo ""
echo -e "${BOLD}==========================================="
echo " Svrnty Doctor"
echo -e "===========================================${NC}"
echo ""

# Resolve plugin root (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_VERSION=$(jq -r '.version // "unknown"' "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")
info "Plugin version: $PLUGIN_VERSION"
info "Plugin path: $PLUGIN_ROOT"

# Must be in a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    fail "Not a git repository"
    exit 1
fi
PROJECT_ROOT=$(git rev-parse --show-toplevel)
info "Project root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"
echo ""

# -------------------------------------------------------
# 1. Stack presence
# -------------------------------------------------------
echo -e "${BOLD}--- [1/6] Stack Components ---${NC}"

if [ -d ".overstory" ]; then
    ok "Overstory initialized"
else
    fail "Overstory not initialized — run /svrnty:init"
    ERRORS=$((ERRORS + 1))
fi

if [ -d ".beads" ]; then
    ok "Beads initialized"
else
    fail "Beads not initialized — run /svrnty:init"
    ERRORS=$((ERRORS + 1))
fi

if [ -d ".mulch" ]; then
    ok "Mulch initialized"
else
    fail "Mulch not initialized — run /svrnty:init"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# -------------------------------------------------------
# 2. Binary health + CGO check
# -------------------------------------------------------
echo -e "${BOLD}--- [2/6] Binary Health ---${NC}"

for cmd in overstory bd mulch git tmux jq; do
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd found"
    else
        fail "$cmd not found"
        ERRORS=$((ERRORS + 1))
    fi
done

# CGO check for bd
if command -v bd &>/dev/null; then
    CGO_SCRIPT="$SCRIPT_DIR/ensure-bd-cgo.sh"
    if [ -f "$CGO_SCRIPT" ]; then
        source "$CGO_SCRIPT"
        if ensure_bd_cgo; then
            : # ok already printed by ensure_bd_cgo
        else
            warn "bd CGO rebuild failed"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
fi
echo ""

# -------------------------------------------------------
# 3. Overstory config sync
# -------------------------------------------------------
echo -e "${BOLD}--- [3/6] Config Sync ---${NC}"

if [ -d ".overstory" ]; then
    EXPECTED_CONFIG='beads:
  enabled: true
mulch:
  enabled: true
merge:
  aiResolveEnabled: true
  reimagineEnabled: false
worktrees:
  baseDir: .overstory/worktrees
watchdog:
  tier1:
    enabled: false
  tier2:
    enabled: false
  tier3:
    enabled: false
mail:
  enabled: true
  pollInterval: 5
logging:
  format: ndjson
  level: info'

    if [ -f ".overstory/config.yaml" ]; then
        CURRENT_CONFIG=$(cat .overstory/config.yaml)
        if [ "$CURRENT_CONFIG" = "$EXPECTED_CONFIG" ]; then
            ok "Overstory config is current"
        else
            echo "$EXPECTED_CONFIG" > .overstory/config.yaml
            ok "Overstory config updated to latest"
            FIXED=$((FIXED + 1))
        fi
    else
        echo "$EXPECTED_CONFIG" > .overstory/config.yaml
        ok "Overstory config created"
        FIXED=$((FIXED + 1))
    fi

    mkdir -p .overstory/worktrees
fi
echo ""

# -------------------------------------------------------
# 4. CLAUDE.md sync — regenerate from latest plugin template
# -------------------------------------------------------
echo -e "${BOLD}--- [4/6] CLAUDE.md Sync ---${NC}"

# Source the init script to get CLAUDE_CONTENT, but we only need the variable.
# Extract it by running the init script in a subshell with a flag.
# Instead, we'll inline a version check.
if [ -f "CLAUDE.md" ]; then
    # Check for key markers from the sprint-fixed template
    NEEDS_UPDATE=false

    if ! grep -q "Dispatch Template (MANDATORY" CLAUDE.md 2>/dev/null; then
        NEEDS_UPDATE=true
        info "Missing: Dispatch Template section"
    fi
    if ! grep -q "Signal Protocol" CLAUDE.md 2>/dev/null; then
        NEEDS_UPDATE=true
        info "Missing: Signal Protocol table"
    fi
    if ! grep -q "Bead Lifecycle" CLAUDE.md 2>/dev/null; then
        NEEDS_UPDATE=true
        info "Missing: Bead Lifecycle table"
    fi
    if ! grep -q "Path Discipline" CLAUDE.md 2>/dev/null; then
        NEEDS_UPDATE=true
        info "Missing: Path Discipline section"
    fi
    if ! grep -q "mail list --unread" CLAUDE.md 2>/dev/null || grep -q "NEVER.*mail list --unread\|Forbidden.*mail list --unread\|forbidden.*polling" CLAUDE.md 2>/dev/null; then
        : # either not mentioned or properly forbidden
    else
        if grep -q "mail list.*--unread" CLAUDE.md 2>/dev/null && ! grep -q "Forbidden in polling" CLAUDE.md 2>/dev/null; then
            NEEDS_UPDATE=true
            info "Stale: mail list --unread not forbidden"
        fi
    fi

    if $NEEDS_UPDATE; then
        info "CLAUDE.md is outdated — regenerating orchestration layer..."
        # Run the init script's CLAUDE.md generation by re-running init
        # But only the CLAUDE.md part. We'll regenerate from scratch.
        bash "$SCRIPT_DIR/init-project.sh" 2>/dev/null | grep -E "(CLAUDE|orchestration)" || true
        if grep -q "Dispatch Template (MANDATORY" CLAUDE.md 2>/dev/null; then
            ok "CLAUDE.md updated to latest template (v${PLUGIN_VERSION})"
            FIXED=$((FIXED + 1))
        else
            # init won't overwrite if marker exists; force it
            rm -f CLAUDE.md
            bash "$SCRIPT_DIR/init-project.sh" 2>/dev/null | grep -E "(CLAUDE|orchestration)" || true
            if [ -f "CLAUDE.md" ]; then
                ok "CLAUDE.md regenerated from latest template (v${PLUGIN_VERSION})"
                FIXED=$((FIXED + 1))
            else
                fail "Could not regenerate CLAUDE.md"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    else
        ok "CLAUDE.md is current (has all sprint fixes)"
    fi
else
    info "No CLAUDE.md found — generating..."
    bash "$SCRIPT_DIR/init-project.sh" 2>/dev/null | grep -E "(CLAUDE|orchestration)" || true
    if [ -f "CLAUDE.md" ]; then
        ok "CLAUDE.md created from latest template"
        FIXED=$((FIXED + 1))
    else
        fail "Could not create CLAUDE.md"
        ERRORS=$((ERRORS + 1))
    fi
fi
echo ""

# -------------------------------------------------------
# 5. Subsystem doctors
# -------------------------------------------------------
echo -e "${BOLD}--- [5/6] Subsystem Health ---${NC}"

if command -v overstory &>/dev/null && [ -d ".overstory" ]; then
    echo -e "${CYAN}Overstory:${NC}"
    OVERSTORY_RESULT=$(overstory doctor 2>&1 || true)
    echo "$OVERSTORY_RESULT" | tail -1
    if echo "$OVERSTORY_RESULT" | grep -q "0 failure"; then
        ok "Overstory healthy"
    else
        FAIL_COUNT=$(echo "$OVERSTORY_RESULT" | grep -oE '[0-9]+ failure' | grep -oE '[0-9]+' || echo "0")
        warn "Overstory has $FAIL_COUNT failure(s)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

if command -v bd &>/dev/null && [ -d ".beads" ]; then
    echo -e "${CYAN}Beads:${NC}"
    BD_RESULT=$(bd doctor 2>&1 || true)
    echo "$BD_RESULT" | head -1
    if echo "$BD_RESULT" | grep -q "0 errors"; then
        ok "Beads healthy"
    else
        ERR_COUNT=$(echo "$BD_RESULT" | grep -oE '[0-9]+ errors' | grep -oE '[0-9]+' || echo "0")
        warn "Beads has $ERR_COUNT error(s)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

if command -v mulch &>/dev/null && [ -d ".mulch" ]; then
    echo -e "${CYAN}Mulch:${NC}"
    MULCH_RESULT=$(mulch doctor 2>&1 || true)
    echo "$MULCH_RESULT" | tail -1
    if echo "$MULCH_RESULT" | grep -q "0 failed"; then
        ok "Mulch healthy"
    else
        warn "Mulch has issues"
        WARNINGS=$((WARNINGS + 1))
    fi
fi
echo ""

# -------------------------------------------------------
# 6. Common fixes
# -------------------------------------------------------
echo -e "${BOLD}--- [6/6] Auto-Repairs ---${NC}"

# Git merge driver for beads
if command -v bd &>/dev/null && [ -d ".beads" ]; then
    if ! git config --get merge.beads.driver &>/dev/null; then
        git config merge.beads.driver 'bd merge %A %O %A %B'
        ok "Configured beads git merge driver"
        FIXED=$((FIXED + 1))
    else
        ok "Beads merge driver already configured"
    fi
fi

# Ensure worktree base dir exists
if [ -d ".overstory" ]; then
    mkdir -p .overstory/worktrees
    ok "Worktree base directory present"
fi

echo ""

# -------------------------------------------------------
# Summary
# -------------------------------------------------------
echo "==========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}${BOLD} Project Healthy${NC}"
else
    echo -e "${RED}${BOLD} $ERRORS Error(s) Found${NC}"
fi
echo "==========================================="
echo ""
echo -e "  Fixed:    ${GREEN}$FIXED${NC}"
echo -e "  Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "  Errors:   ${RED}$ERRORS${NC}"
echo -e "  Plugin:   v${PLUGIN_VERSION}"
echo ""
if [ $ERRORS -gt 0 ]; then
    echo "Run /svrnty:init to reinitialize missing components."
fi
