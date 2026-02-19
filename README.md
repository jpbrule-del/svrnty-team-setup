# Svrnty Team Setup

A Claude Code plugin that uses **Overstory** for all agent orchestration (worktree isolation, agent spawning via `overstory sling`, SQLite mail), with **Beads** for task tracking and **Mulch** for knowledge persistence.

Native Claude Code `Task` and `TeamCreate` tools are **blocked by hooks** — all agent work goes through Overstory for proper worktree isolation and dashboard visibility.

## Architecture

```
┌──────────────────────────────────────────────────┐
│                  You (Human)                      │
│  bd create tasks → prompt orchestrator            │
└─────────────────┬────────────────────────────────┘
                  │
┌─────────────────▼────────────────────────────────┐
│         Orchestrator (Claude Code, depth 0)       │
│  Decomposes → bd create → overstory sling leads   │
│  Monitors via dashboard → merges → syncs          │
└───────┬──────────┬──────────┬────────────────────┘
        │          │          │
   ┌────▼───┐ ┌───▼────┐ ┌──▼──────┐
   │Lead A  │ │Lead B  │ │Lead C   │
   │depth 1 │ │depth 1 │ │depth 1  │
   │worktree│ │worktree│ │worktree │
   └──┬──┬──┘ └───┬────┘ └──┬──────┘
      │  │        │         │
   Scout Builder  Builder   Scout
   (d2) (d2)      (d2)      (d2)
        │          │
   overstory merge --all
                │
           main branch
```

## What Each Tool Does

| Tool | Role |
|------|------|
| **Overstory** | Agent spawning (`sling`), worktree isolation, mail, 4-tier merge, dashboard |
| **Beads** (`bd`) | Git-backed issue/task tracking for agents |
| **Mulch** | Structured knowledge persistence across sessions |
| **Hooks** | Block native agents, enforce worktree boundary, auto-sync on stop |

## Prerequisites

- macOS or Linux
- Git, Node.js (v18+), tmux
- Claude Code CLI (v2.1+)

## Installation

```bash
# 1. Clone this repo
git clone <repo-url> ~/Developer/svrnty-team-setup

# 2. Run setup (installs deps, configures Claude Code, registers plugin)
~/Developer/svrnty-team-setup/setup.sh

# 3. Reload your shell
exec $SHELL
```

The setup script handles everything:
- Installs **Bun**, **Overstory**, **Mulch**, **Beads**, **jq** (skips if already present)
- Verifies **tmux**, **Node.js**, **Claude Code**
- Enables agent teams in `~/.claude/settings.json`
- Registers the plugin via shell alias in your shell config (`~/.zshrc` or `~/.bashrc`)
- Makes all scripts executable
- Cleans up old `hybrid-orchestration-plugin` aliases if present

## Usage

### Initialize a project

```bash
cd /path/to/your/project
claude --dangerously-skip-permissions
```

Then type:
```
/svrnty:init backend frontend testing
```

This initializes Overstory, Beads, and Mulch in the project, applies the orchestration config, installs the CLAUDE.md with full Overstory workflow, and adds the specified Mulch expertise domains.

### Check status

```
/svrnty:status
```

Shows: active agents, worktrees, Beads tasks, Mulch expertise, agent mail.

### Teardown after a team session

```
/svrnty:teardown
```

Merges all branches (4-tier), syncs Beads, records Mulch learnings, cleans worktrees.

## Day-to-Day Workflow

```
1. Create tasks:        bd create --title="Feature X" --priority P1
                        bd create --title="Subtask A" --priority P1

2. Start session:       tmux new-session -s work
                        claude --dangerously-skip-permissions

3. Orchestrate:         "Work on <bead-ids>. Spawn leads via overstory sling
                         for each work stream. Monitor via dashboard."

4. Agents work:         Leads spawn scouts/builders/reviewers
                        Each in isolated worktree with Beads + Mulch

5. Merge:               overstory merge --all

6. Teardown:            /svrnty:teardown

7. Review & push:       git log --oneline && git push
```

## Agent Hierarchy

| Depth | Role | Spawned by | Capabilities |
|-------|------|------------|-------------|
| 0 | Orchestrator (you) | — | Decomposes, dispatches leads, monitors, merges |
| 1 | Lead | Orchestrator | Owns a work stream, spawns depth-2 agents |
| 2 | Scout | Lead | Read-only exploration, reports findings |
| 2 | Builder | Lead | Implements code in isolated worktree |
| 2 | Reviewer | Lead | Validates quality before merge |
| — | Merger | Orchestrator | Handles complex merge conflicts |

## Plugin Structure

```
svrnty-team-setup/
├── .claude-plugin/
│   └── plugin.json                # Plugin manifest
├── .gitignore
├── LICENSE
├── README.md                      # This file
├── setup.sh                       # One-time setup for new machines
├── commands/                      # CLI command wrappers
│   ├── sling.md                   # overstory sling — agent spawning
│   ├── status.md                  # overstory status — agent status
│   ├── mail.md                    # overstory mail — inter-agent messaging
│   ├── merge.md                   # overstory merge — branch merging
│   ├── dashboard.md               # overstory dashboard — live TUI
│   ├── doctor.md                  # overstory doctor — health checks
│   ├── bd-create.md               # bd create — create tasks
│   ├── bd-list.md                 # bd list — list/query tasks
│   ├── bd-update.md               # bd update — update/close tasks
│   ├── bd-ready.md                # bd list --ready — find actionable tasks
│   ├── mulch-prime.md             # mulch prime — load expertise context
│   ├── mulch-record.md            # mulch record — record learnings
│   └── mulch-search.md            # mulch search — search expertise
├── hooks/
│   ├── hooks.json                 # Hook registration (9 hooks, 8 events)
│   ├── block-native-agents.sh     # Block Task + TeamCreate → redirect to overstory
│   ├── hybrid-session-start.sh    # Load Beads + Mulch + Overstory status
│   ├── hybrid-prompt-submit.sh    # Check Overstory mail
│   ├── hybrid-pre-tool-use.sh     # Block dangerous ops + enforce worktree boundary
│   ├── hybrid-post-tool-use.sh    # Log file modifications (async)
│   ├── hybrid-stop.sh             # Sync Beads + Mulch on stop
│   ├── hybrid-task-completed.sh   # Auto-close Beads tasks
│   ├── hybrid-teammate-idle.sh    # Warn about uncommitted work
│   └── hybrid-pre-compact.sh      # Restore context after compaction
├── skills/
│   ├── init/
│   │   └── SKILL.md               # /svrnty:init — project initialization
│   ├── status/
│   │   └── SKILL.md               # /svrnty:status — stack status check
│   └── teardown/
│       └── SKILL.md               # /svrnty:teardown — merge + cleanup
└── scripts/
    ├── init-project.sh            # Init script (called by /svrnty:init)
    ├── status.sh                  # Status script (called by /svrnty:status)
    └── teardown.sh                # Teardown script (called by /svrnty:teardown)
```

## Hooks Reference

| Hook | Event | Matcher | Purpose |
|------|-------|---------|---------|
| `block-native-agents.sh` | PreToolUse | `Task\|TeamCreate` | Block native agent tools, redirect to Overstory |
| `hybrid-session-start.sh` | SessionStart | — | Load Beads + Mulch + Overstory status |
| `hybrid-prompt-submit.sh` | UserPromptSubmit | — | Check Overstory mail |
| `hybrid-pre-tool-use.sh` | PreToolUse | `Edit\|Write\|Bash` | Block dangerous git ops + enforce worktree boundary |
| `hybrid-post-tool-use.sh` | PostToolUse | `Edit\|Write` | Log file modifications (async) |
| `hybrid-stop.sh` | Stop | — | Sync Beads + Mulch learnings |
| `hybrid-task-completed.sh` | TaskCompleted | — | Auto-close Beads tasks |
| `hybrid-teammate-idle.sh` | TeammateIdle | — | Warn about uncommitted work |
| `hybrid-pre-compact.sh` | PreCompact | — | Restore critical context |

## Merge Protocol (4 Tiers)

1. **Fast-forward** — no conflicts
2. **Git auto-merge** — standard 3-way merge
3. **AI-assisted** — Overstory resolves with AI
4. **Reimagine** — full AI reimagining (disabled by default)

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `overstory` not found after install | `exec $SHELL` or check `~/.bun/bin` in PATH |
| Hooks not firing | Ensure plugin is loaded (`claude --plugin-dir ...`) |
| `compdef` warning on shell reload | Harmless — add `autoload -Uz compinit && compinit` before bun completions in `.zshrc` |
| Native Task/TeamCreate blocked | By design — use `overstory sling` instead |
| Agents not on dashboard | Use `overstory sling` (not native teams) to spawn |

## Dependencies

| Tool | Source | Install |
|------|--------|---------|
| [Overstory](https://github.com/jayminwest/overstory) | jayminwest | `setup.sh` handles it |
| [Beads](https://github.com/steveyegge/beads) | steveyegge | `setup.sh` handles it |
| [Mulch](https://github.com/jayminwest/mulch) | jayminwest | `npm install -g mulch-cli` |
| [Bun](https://bun.sh) | oven-sh | `curl -fsSL https://bun.sh/install \| bash` |

## License

MIT
