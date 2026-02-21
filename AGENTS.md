# Agent Guidelines

Rules and conventions for agents spawned within the svrnty-team-setup orchestration layer.

## Critical Rules

1. **Do NOT use Claude Code's native `Task` or `TeamCreate` tools.** These are blocked by hooks. All agent work goes through Overstory.
2. **Stay within your worktree boundary.** Teammates cannot write files outside their assigned worktree.
3. **Always include `--agent $OVERSTORY_AGENT_NAME`** on every `overstory mail` command.
4. **Close all assigned beads** before signaling completion.

## Agent Spawning

```bash
# Create a task
bd create --title="<title>" --priority P1 --desc="<description>"

# Spawn an agent
overstory sling <bead-id> --capability <type> --name <agent-name>

# Dispatch work
overstory mail send --to <agent-name> --subject "<subject>" \
  --body "<instructions>" --type dispatch --agent $OVERSTORY_AGENT_NAME
```

## Agent Capabilities

| Capability | Role | Depth |
|-----------|------|-------|
| coordinator | Top-level orchestration | 0 |
| lead | Work stream coordination, spawns depth-2 agents | 1 |
| supervisor | Persistent lead with lifecycle management | 1 |
| builder | Code implementation in isolated worktree | 1-2 |
| scout | Read-only exploration and reporting | 2 |
| reviewer | Quality validation before merge | 2 |
| merger | Complex merge conflict resolution | — |
| monitor | Fleet watchdog, anomaly detection | 1 |
| analyst | Requirements analysis (planning team) | 2 |
| pm | Product requirements (planning team) | 2 |
| architect | Architecture design (planning team) | 2 |
| scrummaster | Story decomposition (planning team) | 2 |
| tester | Test execution (testing team) | 2 |
| security | Security audit (testing team) | 2 |
| qa | Quality assurance (qa team) | 2 |

## Communication

All inter-agent communication uses Overstory mail:

```bash
# Send a message
overstory mail send --to <agent> --subject "<subject>" --body "<body>" \
  --type <type> --agent $OVERSTORY_AGENT_NAME

# Check inbox
overstory mail check --agent $OVERSTORY_AGENT_NAME
```

Message types: `dispatch`, `status`, `result`, `question`, `error`, `merge_ready`, `worker_done`, `assign`, `escalation`

## Completion Signals

| Scenario | Signal |
|----------|--------|
| Builder -> Lead | `worker_done` |
| Builder -> Orchestrator (direct) | `merge_ready` |
| Lead -> Orchestrator | `merge_ready` |
| Supervisor -> Orchestrator | `result` |

## Available Commands

- `/svrnty-team-setup:init [domains...]` — Initialize orchestration in project
- `/svrnty-team-setup:doctor` — Repair project and sync to latest plugin
- `/svrnty-team-setup:update` — Update the plugin itself
- `/svrnty-team-setup:team spawn <name>` — Spawn a team pipeline
- `/svrnty-team-setup:team list` — List available teams
- `/svrnty-team-setup:team status <name>` — Check team progress

## Forbidden Operations

- Native `Task` or `TeamCreate` tools
- `git push --force` / `git reset --hard` / `git clean -f`
- `rm -rf` on project directories
- Writing outside worktree boundary
- Sending mail without `--agent $OVERSTORY_AGENT_NAME`
