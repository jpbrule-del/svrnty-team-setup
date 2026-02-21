#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Svrnty Team Setup — Project Init Script
# Called by /svrnty-team-setup:init skill
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

# Ensure bd has CGO support (required for Dolt backend on Linux)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/ensure-bd-cgo.sh" ]; then
    source "$SCRIPT_DIR/ensure-bd-cgo.sh"
    ensure_bd_cgo || warn "CGO check failed — bd init may not work"
fi

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

# 6b. Team definitions
echo "--- Team Definitions ---"
TEAMS_SOURCE="$SCRIPT_DIR/../teams"
TEAMS_TARGET=".overstory/teams"
if [ -d "$TEAMS_SOURCE" ]; then
    mkdir -p "$TEAMS_TARGET"
    for team_file in "$TEAMS_SOURCE"/*.yaml; do
        [ -f "$team_file" ] || continue
        team_name=$(basename "$team_file")
        cp "$team_file" "$TEAMS_TARGET/$team_name"
        ok "Deployed team: $team_name"
    done
else
    warn "No team definitions found at $TEAMS_SOURCE"
fi
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
  --body "<instructions>" --type dispatch --agent $OVERSTORY_AGENT_NAME
```

**Agent types:** `coordinator`, `lead`, `supervisor`, `scout`, `builder`, `reviewer`, `merger`, `monitor`, `analyst`, `pm`, `architect`, `scrummaster`, `tester`, `security`, `qa`

---

## Choosing the Right Dispatch Strategy

### Use direct builders (preferred when stories are pre-written)

When user stories already have clear acceptance criteria and file paths, **skip the lead layer entirely**. Leads burn their entire context window on exploration before spawning a single builder -- pure waste when the work is already decomposed.

```bash
# Spawn builder directly, bypassing hierarchy enforcement
overstory sling <bead-id> --capability builder --name <name> --force-hierarchy
```

**Use direct builders when:**
- Story files already exist with acceptance criteria
- File scope is well-understood
- No ambiguity requiring codebase exploration

### Use the lead layer for genuine discovery work only

```bash
overstory sling <bead-id> --capability lead --name <lead-name>
```

**Use leads when:**
- Work requires discovery before decomposition
- Codebase is unfamiliar and scouts are needed
- Multiple parallel work streams need coordination within a sprint

---

## Orchestrator Workflow (You)

You are the **orchestrator/coordinator**. You decompose work, dispatch agents, monitor progress, and merge results. You do NOT write code directly.

### 1. Analyze and decompose
```bash
# Check existing tasks
bd list --status ready
bd list --status in_progress

# Load expertise
mulch prime
mulch search "<relevant query>"
```

### 2. Dispatch agents
```bash
# Create a task for each work stream
bd create --title="<work stream>" --priority P1 --desc="<objective and acceptance criteria>"

# Spawn direct builder (for pre-written stories)
overstory sling <bead-id> --capability builder --name <name> --force-hierarchy

# OR spawn a lead (for discovery/decomposition work)
overstory sling <bead-id> --capability lead --name <lead-name>

# Group related tasks for batch tracking
overstory group create '\''<batch-name>'\'' <bead-id-1> <bead-id-2>
```

### 3. Monitor
```bash
overstory status              # Active agents and worktrees
overstory dashboard           # Live TUI (run in separate terminal)
overstory mail check          # Incoming messages from agents
overstory group status <id>   # Batch progress
```

**IMPORTANT:** Always use `overstory mail check` to poll for completion signals. Never use `overstory mail list --unread` in a loop -- messages already read will not reappear, causing signals to be silently missed.

### 4. Merge and close

**MANDATORY sequence -- do not skip any step:**

```bash
# Step 1: Merge
overstory merge --branch <branch> --dry-run   # Check first
overstory merge --branch <branch>              # Then merge
# (or: overstory merge --all)

# Step 2: ALWAYS verify beads immediately after merge
# Builders sometimes close only their task bead and miss story beads.
bd list --status open   # any sprint beads still open? close them now

# Close any story beads the builder missed:
bd close <missed-bead> --reason "Implemented in <builder-name>, merged at <branch>"

# Step 3: Sync dashboard
bd sync

# Step 4: Clean up (only after beads are verified + synced)
overstory worktree clean --completed
mulch sync
```

> **Why this matters:** The builder overlay only closes the builder'\''s own task bead. Story beads are only closed if the dispatch message instructions were followed perfectly. Always assume at least one story bead may be open and verify with `bd list --status open` before declaring a sprint done.

---

## Agent Hierarchy

```
Orchestrator (you, depth 0)
  +-- Lead (depth 1) -- owns a work stream end-to-end (use for discovery only)
        +-- Scout (depth 2) -- read-only exploration, reports findings
        +-- Builder (depth 2) -- implements code in isolated worktree
        +-- Reviewer (depth 2) -- validates quality before merge
  +-- Builder (depth 1, --force-hierarchy) -- direct dispatch for pre-written stories
  +-- Supervisor (depth 1) -- persistent per-project team lead
        +-- Scout/Builder/Reviewer/Merger (depth 2) -- leaf workers
  +-- Monitor (depth 1) -- fleet watchdog, anomaly detection
```

- **Leads** spawn their own scouts, builders, and reviewers
- **Supervisors** are persistent leads with full worker lifecycle management
- **Builders/Scouts/Reviewers** are leaf nodes -- they do NOT spawn sub-agents
- **Monitor** observes and nudges but never spawns agents
- Use `--force-hierarchy` to dispatch builders directly when stories are ready

---

## Team Orchestration

Teams are groups of specialized agents that execute a workflow pipeline together. Teams are a convention layer built on existing overstory primitives (sling, mail, groups, beads).

### Available Teams

| Team | Lead dispatches | Agents | Output |
|---|---|---|---|
| planning | BMAD pipeline | analyst -> pm -> architect -> scrummaster | stories + sprint plan |
| development | Story execution | builders (parallel) | implemented features |
| testing | Validation | tester + security (parallel) | test + security reports |
| qa | Final check | qa | QA report |

### Spawning a Team

```bash
# 1. Create a bead for the team lead
bd create --title="Planning: <project brief>" --priority P0 --desc="Run BMAD planning pipeline"

# 2. Spawn the team lead
overstory sling <bead-id> --capability lead --name planning-lead

# 3. Send team dispatch with pipeline definition
overstory mail send --to planning-lead --subject "Team: planning" \
  --body "Execute BMAD pipeline: analyst -> pm -> architect -> scrummaster. <project brief>" \
  --type dispatch --agent $OVERSTORY_AGENT_NAME
```

### Team Sequencing

Output of one team feeds the next:
1. **Planning** -> produces `docs/stories/*.md` + `docs/planning/sprint-plan.yaml`
2. **Development** -> builders consume stories, produce implemented code
3. **Testing** -> tester + security audit the merged code
4. **QA** -> validates acceptance criteria from stories

### Artifact Locations

| Team | Output Directory |
|---|---|
| Planning | `docs/planning/`, `docs/stories/` |
| Development | Feature branches (merged by orchestrator) |
| Testing | `docs/testing/` |
| QA | `docs/qa/` |

---

## Direct Builder Dispatch Template

The builder'\''s `.claude/CLAUDE.md` overlay already contains the full protocol: quality gates, bead lifecycle, PATH DISCIPLINE, and completion signals. Dispatch messages only need to supply what is unique per sprint.

**Required fields -- missing any causes broken bead tracking:**

```
## Sprint N -- <Title>
Stack: Flutter | .NET | TypeScript
<Framework> app with Sprint 1-(N-1) complete at <dir>/. Add to existing project. DO NOT re-create.

Stories to implement (read each story file first):
1. X-N.M -> docs/stories/<path>.md (bead: <project-xxx>)
2. X-N.M -> docs/stories/<path>.md (bead: <project-yyy>)
...

Key technical context:
- <any library quirks, patterns, import paths, constraints not already in mulch>

Quality gates (OVERRIDE defaults if needed):
- Flutter: flutter analyze from mobile/ -- 0 issues
- .NET:    dotnet build from backend/ -- 0 warnings
- TypeScript: bun test && bun run lint && bun run typecheck

Close ALL beads before signalling done (story beads FIRST, then your task bead):
  bd close <project-xxx> --reason "Implemented: X-N.M"
  bd close <project-yyy> --reason "Implemented: X-N.M"
  bd close <builder-task-bead> --reason "Sprint N builder complete"

Signal: send merge_ready (NOT worker_done) to orchestrator -- parent is orchestrator, not a lead.

Your worktree: <worktree-path>
Your branch:   <branch-name>
Your parent:   orchestrator
Your task bead: <builder-task-bead>
```

> **Note:** The builder overlay hardcodes `worker_done` and `bun` quality gates as defaults. Override both in the dispatch message when your project uses a different stack or when the parent is the orchestrator (not a lead).

---

## Bead Lifecycle

Beads must be kept in sync with actual work state. The builder overlay only closes the builder'\''s own task bead -- story bead closure must be explicitly listed in every dispatch message (see template above) and verified by the orchestrator after every merge.

| Bead type | Created by | Closed by |
|---|---|---|
| Orchestrator task bead | Orchestrator | Orchestrator (after merge) |
| Story-level beads | Orchestrator (before sprint) | Builder (in dispatch) OR Orchestrator (bulk after merge) |
| Builder task bead | Orchestrator | Builder (in completion protocol) |

**After every merge**, verify and sync:
```bash
bd list --status in_progress   # should be empty after a sprint completes
bd list --status open          # should be empty for all sprint beads
bd sync                        # flush to dashboard immediately
```

---

## Communication Protocol

All inter-agent communication uses Overstory mail. **CRITICAL: always pass `--agent $OVERSTORY_AGENT_NAME` on every mail command.** Omitting it causes silent routing failures.

```bash
# Send
overstory mail send --to <agent> --subject "<subject>" --body "<body>" --type <type> --agent $OVERSTORY_AGENT_NAME

# Types: dispatch, status, result, question, error, merge_ready, worker_done, assign, escalation

# Check inbox -- use this for polling loops
overstory mail check --agent $OVERSTORY_AGENT_NAME

# List/read specific messages
overstory mail list [--from <agent>] --agent $OVERSTORY_AGENT_NAME
overstory mail read <id>

# Nudge a stalled agent
overstory nudge <agent-name> "Status check"
```

### Completion signal rules

| Scenario | Signal to send |
|---|---|
| Builder -> Lead (normal hierarchy) | `worker_done` |
| Builder -> Orchestrator (direct, `--force-hierarchy`) | `merge_ready` |
| Lead -> Orchestrator | `merge_ready` |
| Supervisor -> Orchestrator | `result` |

Builders dispatched directly to the orchestrator must send `merge_ready` (not `worker_done`) so the orchestrator knows the branch is ready to land without a lead review step.

---

## Merge Protocol (4-Tier Escalation)

1. **Tier 1 -- Fast-forward**: No conflicts, auto-merged
2. **Tier 2 -- Git auto-merge**: Standard 3-way merge, no conflicts
3. **Tier 3 -- AI-assisted resolve**: Overstory uses AI to resolve conflicts
4. **Tier 4 -- Manual / Reimagine**: Human intervention required

After every merge, always verify beads and sync:
```bash
overstory merge --branch <branch> --dry-run   # check first
overstory merge --branch <branch>              # merge
bd list --status open                          # verify all beads closed
bd sync                                        # flush to dashboard
overstory worktree clean --completed           # clean up
```

---

## Forbidden Operations

**NEVER** do any of these:
- Use Claude Code'\''s `Task` tool to spawn agents (use `overstory sling`)
- Use Claude Code'\''s `TeamCreate` tool (use `overstory group create`)
- `git push --force` or `git push -f`
- `git reset --hard`
- `git clean -f` or `git clean -fd`
- `rm -rf` on any project directory
- Write files outside your worktree boundary (teammates only)
- Use `overstory mail list --unread` in orchestrator polling loops (use `mail check`)
- Send mail without `--agent $OVERSTORY_AGENT_NAME` (causes silent routing failures)

---

## Project-Specific Quality Gates

Override the builder overlay'\''s default `bun` commands when your project uses a different stack. Always specify in the dispatch message.

| Stack | Build | Test |
|---|---|---|
| TypeScript/Node | `bun run typecheck` | `bun test && bun run lint` |
| Flutter | `flutter analyze` -- 0 issues | `flutter test` |
| .NET | `dotnet build` -- 0 warnings | `dotnet test` |

---

## Quick Reference

| Tool | Purpose | Key Commands |
|------|---------|-------------|
| `overstory sling` | Spawn agents | `sling <bead-id> --capability <type> --name <name> [--force-hierarchy]` |
| `overstory status` | Agent monitoring | `status`, `dashboard` |
| `overstory mail` | Communication | `mail check` (polling), `mail send --agent`, `mail list`, `mail read` |
| `overstory merge` | Branch integration | `merge --branch <name>`, `merge --all`, `merge --dry-run` |
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
echo "  4. Health check:   /svrnty-team-setup:doctor"
echo ""
