# bd list — List and Query Tasks

List Beads issues with powerful filtering and display options.

## Usage

```bash
bd list [flags]
```

## Key Flags

| Flag | Description |
|------|-------------|
| `-s, --status <status>` | Filter: `open`, `in_progress`, `blocked`, `deferred`, `closed` |
| `-p, --priority <level>` | Filter by priority (`0-4` or `P0-P4`) |
| `-a, --assignee <name>` | Filter by assignee |
| `-t, --type <type>` | Filter by type: `bug`, `feature`, `task`, `epic`, `chore` |
| `-l, --label <labels>` | Filter by labels (AND: must have ALL) |
| `--ready` | Show only ready issues (open, not blocked/deferred) |
| `--parent <id>` | Show children of a specific issue |
| `--all` | Include closed issues |
| `--pretty` | Tree format with status/priority symbols |
| `--tree` | Alias for `--pretty` |
| `-n, --limit <n>` | Limit results (default: 50, 0 for unlimited) |
| `--sort <field>` | Sort by: `priority`, `created`, `updated`, `status`, `id`, `title` |
| `-r, --reverse` | Reverse sort order |
| `--overdue` | Show only overdue issues |
| `--no-assignee` | Show unassigned issues |
| `--json` | Output in JSON format |
| `-w, --watch` | Watch for changes and auto-update |

## Examples

```bash
# List all open tasks
bd list

# Show ready tasks (actionable)
bd list --ready

# Filter by status and priority
bd list --status in_progress --priority P1

# Show tasks for a specific assignee
bd list --assignee api-lead

# Tree view of an epic's children
bd list --parent bd-a3f8e9 --pretty

# Find unassigned high-priority tasks
bd list --no-assignee --priority P1

# Watch mode — live updates
bd list --watch

# JSON output for scripting
bd list --status open --json
```

## See Also

- `bd query` — Advanced query language
- `bd search` — Full-text search
- `bd count` — Count matching issues
