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
| `/svrnty-team-setup:init [domains...]` | Initialize orchestration in the current project |
| `/svrnty-team-setup:doctor` | Repair project and sync to latest plugin version |
| `/svrnty-team-setup:update` | Update the plugin itself to the latest version |
| `/svrnty-team-setup:team spawn <name>` | Spawn a team pipeline |
| `/svrnty-team-setup:team list` | List available team definitions |
| `/svrnty-team-setup:team status <name>` | Check team progress |

### `/svrnty-team-setup:init`

Initializes Overstory, Beads, and Mulch in the project. Applies orchestration config, installs CLAUDE.md with the full dispatch template, signal protocol, bead lifecycle, and path discipline rules. Optionally adds Mulch expertise domains.

### `/svrnty-team-setup:doctor`

Runs health checks on all three subsystems, verifies CGO support for Beads, checks if CLAUDE.md has all required sections (dispatch template, signal protocol, bead lifecycle, path discipline), and auto-repairs what it can.

### `/svrnty-team-setup:update`

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

<!-- BEGIN PLUGIN STRUCTURE -->
## Plugin Structure

```
svrnty-team-setup/
├── .claude-plugin/
│   └── plugin.json                    # Plugin manifest (v2.1.0)
├── .github/
│   ├── workflows/
│   │   ├── validate-plugin.yml        # CI validation
│   │   └── sync-manifest.yml          # Auto-sync manifest + README
│   └── scripts/
│       └── sync-manifest.js           # Node.js sync automation
├── commands/
│   ├── doctor.md                      # /svrnty-team-setup:doctor
│   ├── init.md                        # /svrnty-team-setup:init
│   └── update.md                      # /svrnty-team-setup:update
├── hooks/
│   ├── hooks.json                     # Hook registration (9 hooks, 8 events)
│   ├── svrnty-auto-update.sh          # Auto-update check (throttled)
│   ├── svrnty-block-native-agents.sh  # Block Task + TeamCreate
│   ├── svrnty-pre-compact.sh          # Restore context after compaction
│   ├── svrnty-pre-tool-use.sh         # Block dangerous ops + worktree boundary
│   ├── svrnty-post-tool-use.sh        # Log file modifications (async)
│   ├── svrnty-prompt-submit.sh        # Check Overstory mail
│   ├── svrnty-session-start.sh        # Load Beads + Mulch + Overstory status
│   ├── svrnty-stop.sh                 # Sync Beads + Mulch on stop
│   ├── svrnty-task-completed.sh       # Auto-close Beads tasks
│   └── svrnty-teammate-idle.sh        # Warn about uncommitted work
├── scripts/
│   ├── _common.sh                     # Shared colors/logging utilities
│   ├── doctor.sh                      # Doctor script
│   ├── ensure-bd-cgo.sh              # Beads CGO rebuild helper
│   ├── init-project.sh               # Init script
│   ├── setup.sh                       # Full setup logic (delegated from root)
│   └── update.sh                      # Update script
├── skills/
│   └── team/
│       ├── SKILL.md                   # Team orchestration skill
│       └── references/
│           ├── team-schema.md         # Team YAML schema docs
│           └── pipeline-sequence.md   # Pipeline sequence docs
├── teams/
│   ├── README.md                      # Team YAML schema + pipeline docs
│   ├── development.yaml
│   ├── planning.yaml
│   ├── qa.yaml
│   └── testing.yaml
├── .gitignore
├── AGENTS.md                          # Agent guidelines
├── CLAUDE.md                          # Plugin development guide
├── CONTRIBUTING.md                    # Contribution standards
├── LICENSE
├── README.md
├── VERSIONS.md                        # Version history
├── setup.sh                           # Thin wrapper → scripts/setup.sh
└── validate-plugin.sh                 # Plugin validation
```
<!-- END PLUGIN STRUCTURE -->

<!-- BEGIN HOOKS REFERENCE -->
## Hooks Reference

| Hook | Event | Matcher | Purpose |
|------|-------|---------|---------|
| `svrnty-block-native-agents.sh` | PreToolUse | `Task\|TeamCreate` | Block native agent tools, redirect to Overstory |
| `svrnty-session-start.sh` | SessionStart | — | Load Beads + Mulch + Overstory status |
| `svrnty-prompt-submit.sh` | UserPromptSubmit | — | Check Overstory mail |
| `svrnty-pre-tool-use.sh` | PreToolUse | `Edit\|Write\|Bash` | Block dangerous git ops + enforce worktree boundary |
| `svrnty-post-tool-use.sh` | PostToolUse | `Edit\|Write` | Log file modifications (async) |
| `svrnty-stop.sh` | Stop | — | Sync Beads + Mulch learnings |
| `svrnty-task-completed.sh` | TaskCompleted | — | Auto-close Beads tasks |
| `svrnty-teammate-idle.sh` | TeammateIdle | — | Warn about uncommitted work |
| `svrnty-pre-compact.sh` | PreCompact | — | Restore critical context |
| `svrnty-auto-update.sh` | SessionStart | — | Silent update check (throttled, 1h cooldown) |
<!-- END HOOKS REFERENCE -->

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
| Beads CGO error on Linux | Run `/svrnty-team-setup:doctor` — auto-rebuilds with CGO |
| CLAUDE.md outdated | Run `/svrnty-team-setup:doctor` — auto-syncs to latest template |
| Plugin outdated | Run `/svrnty-team-setup:update` — pulls latest and re-runs setup |

## Dependencies

| Tool | Source | Install |
|------|--------|---------|
| [Overstory](https://github.com/jayminwest/overstory) | jayminwest | `setup.sh` handles it |
| [Beads](https://github.com/steveyegge/beads) | steveyegge | `setup.sh` handles it |
| [Mulch](https://github.com/jayminwest/mulch) | jayminwest | `npm install -g mulch-cli` |
| [Bun](https://bun.sh) | oven-sh | `curl -fsSL https://bun.sh/install \| bash` |

## Documentation

- [VERSIONS.md](VERSIONS.md) — Version history
- [CONTRIBUTING.md](CONTRIBUTING.md) — Contribution guidelines
- [AGENTS.md](AGENTS.md) — Agent guidelines and rules
- [CLAUDE.md](CLAUDE.md) — Plugin development guide

## License

MIT
