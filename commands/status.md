# overstory status — Check Agent Status

Show all active agents and project state.

## Usage

```bash
overstory status [options]
```

## Options

| Flag | Description |
|------|-------------|
| `--json` | Output as JSON |
| `--verbose` | Show extra detail per agent (worktree, logs, mail timestamps) |
| `--agent <name>` | Show unread mail for this agent (default: `orchestrator`) |
| `--all` | Show sessions from all runs (default: current run only) |

## Examples

```bash
# Quick status overview
overstory status

# Detailed status with worktree info
overstory status --verbose

# Check status for a specific agent
overstory status --agent api-lead

# JSON output for scripting
overstory status --json

# Show all runs, not just current
overstory status --all
```

## Output

Shows per-agent:
- Agent name, capability, and depth
- Assigned bead ID
- Current status (active, idle, completed)
- Worktree path
- Unread mail count

## See Also

- `overstory dashboard` — Live TUI for continuous monitoring
- `overstory inspect <agent>` — Deep inspection of a single agent
