#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Svrnty Team Setup — Project Init Script
# Called by /hybrid:init skill
# ============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

DOMAINS="$*"

echo "==========================================="
echo " Svrnty Team Setup — Project Init"
echo "==========================================="
echo ""

# 1. Verify git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    fail "Not a git repository. Run 'git init' first."
    exit 1
fi
PROJECT_ROOT=$(git rev-parse --show-toplevel)
info "Project root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"
echo ""

# 2. Overstory
echo "--- Overstory ---"
if [ -d ".overstory" ]; then
    warn "Already initialized"
else
    if command -v overstory &>/dev/null; then
        overstory init
        ok "Initialized"
    else
        fail "overstory not found — run setup.sh first"
    fi
fi
echo ""

# 3. Overstory config
if [ -d ".overstory" ]; then
    cat > .overstory/config.yaml << 'YAML'
beads:
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
  level: info
YAML
    ok "Orchestration config applied"
fi

# 4. Beads
echo "--- Beads ---"
if [ -d ".beads" ]; then
    warn "Already initialized"
else
    if command -v bd &>/dev/null; then
        bd init --quiet 2>/dev/null || bd init
        ok "Initialized"
    else
        fail "bd not found — run setup.sh first"
    fi
fi
echo ""

# 5. Mulch
echo "--- Mulch ---"
if [ -d ".mulch" ]; then
    warn "Already initialized"
else
    if command -v mulch &>/dev/null; then
        mulch init
        ok "Initialized"
    else
        fail "mulch not found — run setup.sh first"
    fi
fi

# Add domains
if [ -n "$DOMAINS" ]; then
    for domain in $DOMAINS; do
        mulch add "$domain" 2>/dev/null && ok "Domain added: $domain" || warn "Domain '$domain' may already exist"
    done
else
    info "No domains specified. Add with: mulch add <domain>"
fi
echo ""

# 6. Worktree base dir
mkdir -p .overstory/worktrees
ok "Worktree base directory ready"
echo ""

# 7. CLAUDE.md — Overstory orchestration layer
echo "--- Orchestration Layer ---"

CLAUDE_CONTENT='# Overstory Agent Orchestration

This project uses **Overstory** for all agent orchestration: worktree isolation, `overstory sling` for spawning, Beads for task tracking, Mulch for knowledge persistence.

---

## CRITICAL: Agent Spawning Rules

**NEVER use Claude Code'\''s native `Task` tool or `TeamCreate` to spawn agents.** These are blocked by hooks. All agent work goes through Overstory:

```bash
# 1. Create a beads task
bd create --title="<task title>" --priority P1 --desc="<description>"

# 2. Spawn an agent into its own worktree
overstory sling <bead-id> --capability <type> --name <agent-name>

# 3. Dispatch work via mail
overstory mail send --to <agent-name> --subject "<subject>" \
  --body "<instructions>" --type dispatch
```

**Agent types:** `coordinator`, `lead`, `scout`, `builder`, `reviewer`, `merger`

---

## Orchestrator Workflow (You)

You are the **orchestrator/coordinator**. You decompose work, dispatch leads, monitor progress, and merge results. You do NOT write code directly.

### 1. Analyze and decompose
```bash
bd list --status ready
bd list --status in_progress
mulch prime
mulch search "<relevant query>"
```

### 2. Create tasks and dispatch leads
```bash
bd create --title="<work stream>" --priority P1 --desc="<objective and acceptance criteria>"
overstory sling <bead-id> --capability lead --name <lead-name> --depth 1
overstory mail send --to <lead-name> --subject "Work stream: <title>" \
  --body "Objective: <what>. File area: <where>. Acceptance: <criteria>." \
  --type dispatch
overstory group create '\''<batch-name>'\'' <bead-id-1> <bead-id-2>
```

### 3. Monitor
```bash
overstory status
overstory dashboard
overstory mail check
overstory group status <id>
```

### 4. Merge and close
```bash
overstory merge --branch <branch> --dry-run
overstory merge --branch <branch>
overstory merge --all
overstory worktree clean --completed
bd sync
mulch sync
```

---

## Agent Hierarchy

```
Orchestrator (you, depth 0)
  +-- Lead (depth 1) -- owns a work stream end-to-end
        +-- Scout (depth 2) -- read-only exploration, reports findings
        +-- Builder (depth 2) -- implements code in isolated worktree
        +-- Reviewer (depth 2) -- validates quality before merge
```

---

## Communication Protocol

```bash
overstory mail send --to <agent> --subject "<subject>" --body "<body>" --type <type>
# Types: dispatch, status, result, question, error, merge_ready, worker_done
overstory mail check
overstory mail list [--from <agent>] [--unread]
overstory mail read <id>
overstory nudge <agent-name> "Status check"
```

---

## Forbidden Operations

- Use Claude Code'\''s `Task` tool to spawn agents (use `overstory sling`)
- Use Claude Code'\''s `TeamCreate` tool (use `overstory group create`)
- `git push --force` or `git push -f`
- `git reset --hard`
- `git clean -f` or `git clean -fd`
- `rm -rf` on any project directory
- Write files outside your worktree boundary (teammates only)

---

## Quick Reference

| Tool | Purpose | Key Commands |
|------|---------|-------------|
| `overstory sling` | Spawn agents | `overstory sling <bead-id> --capability <type> --name <name>` |
| `overstory status` | Monitoring | `overstory status`, `overstory dashboard` |
| `overstory mail` | Communication | `mail send`, `mail check`, `mail list`, `mail read` |
| `overstory merge` | Branch integration | `merge --branch <name>`, `merge --all` |
| `overstory group` | Batch tracking | `group create`, `group status`, `group list` |
| `bd` | Task tracking | `bd create`, `bd list`, `bd update`, `bd close`, `bd sync` |
| `mulch` | Knowledge | `mulch prime`, `mulch search`, `mulch record`, `mulch learn` |
'

if [ -f "CLAUDE.md" ]; then
    if grep -q "Overstory Agent Orchestration" CLAUDE.md 2>/dev/null; then
        warn "CLAUDE.md already has orchestration layer"
    else
        echo "" >> CLAUDE.md
        echo "---" >> CLAUDE.md
        echo "$CLAUDE_CONTENT" >> CLAUDE.md
        ok "Orchestration layer appended to CLAUDE.md"
    fi
else
    echo "$CLAUDE_CONTENT" > CLAUDE.md
    ok "CLAUDE.md created with orchestration layer"
fi
echo ""

# 8. Health checks
echo "==========================================="
echo " Health Checks"
echo "==========================================="

if command -v overstory &>/dev/null && [ -d ".overstory" ]; then
    overstory doctor 2>&1 && ok "Overstory doctor passed" || warn "Overstory doctor reported issues"
fi
echo ""

if command -v bd &>/dev/null && [ -d ".beads" ]; then
    bd doctor 2>&1 && ok "Beads doctor passed" || warn "Beads doctor reported issues"
fi
echo ""

if command -v mulch &>/dev/null && [ -d ".mulch" ]; then
    mulch doctor 2>&1 && ok "Mulch doctor passed" || warn "Mulch doctor reported issues"
fi
echo ""

# 9. Summary
echo "==========================================="
echo -e "${GREEN} Project Ready!${NC}"
echo "==========================================="
echo ""
echo "Next steps:"
echo "  1. Create tasks:   bd create --title=\"Task title\" --priority P1"
echo "  2. Spawn agents:   overstory sling <bead-id> --capability lead --name <name>"
echo "  3. Monitor:        overstory dashboard"
echo "  4. After work:     /hybrid:teardown"
echo ""
