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
│  Decomposes → bd create → overstory sling         │
│  Monitors via dashboard → merges → syncs          │
└───────┬──────────┬──────────┬────────────────────┘
        │          │          │
   ┌────▼───┐ ┌───▼────┐ ┌──▼──────┐
   │Builder │ │Builder │ │Lead     │  ← skip leads when stories are pre-written
   │depth 1 │ │depth 1 │ │depth 1  │
   │worktree│ │worktree│ │worktree │
   └────────┘ └────────┘ └──┬──────┘
                             │
                        Scout Builder
                        (d2)  (d2)

   overstory merge --all → main branch
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
- Installs **Bun**, **Overstory**, **Mulch**, **Beads** (with CGO rebuild if needed), **jq**
- Verifies **tmux**, **Node.js**, **Claude Code**
- Enables agent teams in `~/.claude/settings.json`
- Registers the plugin via shell alias
- Makes all scripts executable

## Commands

| Command | Description |
|---------|-------------|
| `/svrnty:init [domains...]` | Initialize orchestration in the current project |
| `/svrnty:doctor` | Repair project and sync to latest plugin version |
| `/svrnty:update` | Update the plugin itself to the latest version |

### `/svrnty:init`

Initializes Overstory, Beads, and Mulch in the project. Applies orchestration config, installs CLAUDE.md with the full dispatch template, signal protocol, bead lifecycle, and path discipline rules. Optionally adds Mulch expertise domains.

### `/svrnty:doctor`

Runs health checks on all three subsystems, verifies CGO support for Beads, checks if CLAUDE.md has all required sections (dispatch template, signal protocol, bead lifecycle, path discipline), and auto-repairs what it can.

### `/svrnty:update`

Pulls the latest plugin from the repository, syncs all remotes, re-runs `setup.sh` to update dependencies, and reports the version change. Restart Claude Code after updating.

## Day-to-Day Workflow

```
1. Create tasks:        bd create --title="Feature X" --priority P1

2. Start session:       tmux new-session -s work
                        claude --dangerously-skip-permissions

3. Orchestrate:         "Work on <bead-ids>. Spawn builders via overstory sling.
                         Monitor via dashboard."

4. Agents work:         Each in isolated worktree with Beads + Mulch

5. Merge:               overstory merge --all

6. Review & push:       git log --oneline && git push
```

## Agent Hierarchy

| Depth | Role | Spawned by | Capabilities |
|-------|------|------------|-------------|
| 0 | Orchestrator (you) | — | Decomposes, dispatches, monitors, merges |
| 1 | Builder | Orchestrator | Implements code in isolated worktree (when stories are pre-written) |
| 1 | Lead | Orchestrator | Owns a work stream, spawns depth-2 agents (when stories need decomposition) |
| 2 | Scout | Lead | Read-only exploration, reports findings |
| 2 | Builder | Lead | Implements code in isolated worktree |
| 2 | Reviewer | Lead | Validates quality before merge |
| — | Merger | Orchestrator | Handles complex merge conflicts |

## Plugin Structure

```
svrnty-team-setup/
├── .claude-plugin/
│   └── plugin.json                # Plugin manifest (v2.0.0)
├── .gitignore
├── LICENSE
├── README.md
├── setup.sh                       # One-time setup for new machines
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
│   ├── doctor/
│   │   └── SKILL.md               # /svrnty:doctor — repair & sync project
│   └── update/
│       └── SKILL.md               # /svrnty:update — self-update plugin
└── scripts/
    ├── init-project.sh            # Init script (called by /svrnty:init)
    ├── doctor.sh                  # Doctor script (called by /svrnty:doctor)
    ├── update.sh                  # Update script (called by /svrnty:update)
    └── ensure-bd-cgo.sh           # Beads CGO rebuild helper
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
| Native Task/TeamCreate blocked | By design — use `overstory sling` instead |
| Beads CGO error on Linux | Run `/svrnty:doctor` — auto-rebuilds with CGO |
| CLAUDE.md outdated | Run `/svrnty:doctor` — auto-syncs to latest template |
| Plugin outdated | Run `/svrnty:update` — pulls latest and re-runs setup |

## Dependencies

| Tool | Source | Install |
|------|--------|---------|
| [Overstory](https://github.com/jayminwest/overstory) | jayminwest | `setup.sh` handles it |
| [Beads](https://github.com/steveyegge/beads) | steveyegge | `setup.sh` handles it |
| [Mulch](https://github.com/jayminwest/mulch) | jayminwest | `npm install -g mulch-cli` |
| [Bun](https://bun.sh) | oven-sh | `curl -fsSL https://bun.sh/install \| bash` |

## License

MIT
