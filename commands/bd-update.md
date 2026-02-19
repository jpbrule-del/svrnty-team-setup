# bd update — Update and Close Tasks

Update one or more Beads issues. If no ID is provided, updates the last touched issue.

## Usage

```bash
bd update [id...] [flags]
```

## Key Flags

| Flag | Description |
|------|-------------|
| `-s, --status <status>` | New status: `open`, `in_progress`, `blocked`, `deferred`, `closed` |
| `--claim` | Atomically claim (sets assignee + status to `in_progress`) |
| `--title <text>` | New title |
| `-d, --description <text>` | New description |
| `-p, --priority <level>` | New priority (`0-4` or `P0-P4`) |
| `-a, --assignee <name>` | New assignee |
| `--add-label <labels>` | Add labels |
| `--remove-label <labels>` | Remove labels |
| `--notes <text>` | Replace notes |
| `--append-notes <text>` | Append to existing notes |
| `--acceptance <text>` | Acceptance criteria |
| `--due <date>` | Due date (empty to clear) |
| `--parent <id>` | Reparent issue (empty to remove parent) |
| `--json` | Output in JSON format |

## Closing Tasks

```bash
# Close a task
bd close <id>

# Close multiple tasks
bd close bd-1 bd-2 bd-3

# Reopen a closed task
bd reopen <id>
```

## Examples

```bash
# Claim a task (atomic assign + in_progress)
bd update bd-a3f8e9 --claim

# Update status
bd update bd-a3f8e9 --status in_progress

# Update priority and add labels
bd update bd-a3f8e9 --priority P0 --add-label "urgent,hotfix"

# Append progress notes
bd update bd-a3f8e9 --append-notes "API endpoints complete, starting tests"

# Close a completed task
bd close bd-a3f8e9

# Block a task
bd update bd-a3f8e9 --status blocked --append-notes "Waiting on bd-b2c4d6"
```

## Workflow

1. Claim when starting: `bd update <id> --claim`
2. Update progress: `bd update <id> --append-notes "..."`
3. Close when done: `bd close <id>`
