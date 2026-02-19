# bd list --ready — Find Actionable Tasks

Find tasks that are ready to be worked on: open status, not blocked, not deferred.

## Usage

```bash
bd list --ready [flags]
```

## Key Flags

| Flag | Description |
|------|-------------|
| `-p, --priority <level>` | Filter by priority (`0-4` or `P0-P4`) |
| `-a, --assignee <name>` | Filter by assignee |
| `--no-assignee` | Show only unassigned ready tasks |
| `-t, --type <type>` | Filter by type |
| `--pretty` | Tree format display |
| `--sort <field>` | Sort by: `priority`, `created`, `updated` |
| `-n, --limit <n>` | Limit results |
| `--json` | Output in JSON format |

## Examples

```bash
# Find all ready tasks
bd list --ready

# Find unassigned ready tasks (available for agents)
bd list --ready --no-assignee

# Find high-priority ready tasks
bd list --ready --priority P1

# Find ready tasks in tree format
bd list --ready --pretty

# JSON output for scripting
bd list --ready --json
```

## What "Ready" Means

A task is "ready" when ALL of these are true:
- Status is `open` (not `in_progress`, `blocked`, `deferred`, or `closed`)
- Not deferred (no `defer_until` date, or date has passed)
- Not blocked by unresolved dependencies

## Workflow

1. Find ready tasks: `bd list --ready --no-assignee`
2. Pick one and create an agent: `overstory sling <bead-id> --capability lead --name <name>`
3. Agent claims it: `bd update <id> --claim`
