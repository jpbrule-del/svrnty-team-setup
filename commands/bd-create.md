# bd create — Create Tasks

Create a new Beads issue/task for agent work tracking.

## Usage

```bash
bd create [title] [flags]
```

## Key Flags

| Flag | Description |
|------|-------------|
| `--title <text>` | Issue title (alternative to positional argument) |
| `-d, --description <text>` | Issue description |
| `-p, --priority <level>` | Priority: `0-4` or `P0-P4` (0=highest, default: 2) |
| `-t, --type <type>` | Type: `bug`, `feature`, `task`, `epic`, `chore`, `decision` |
| `-a, --assignee <name>` | Assignee |
| `-l, --labels <list>` | Labels (comma-separated) |
| `--parent <id>` | Parent issue ID for hierarchy |
| `--deps <list>` | Dependencies (e.g., `blocks:bd-15,bd-20`) |
| `--acceptance <text>` | Acceptance criteria |
| `--due <date>` | Due date: `+6h`, `+1d`, `tomorrow`, `2025-01-15` |
| `-e, --estimate <min>` | Time estimate in minutes |
| `--notes <text>` | Additional notes |
| `--silent` | Output only the issue ID (for scripting) |
| `--json` | Output in JSON format |

## Examples

```bash
# Simple task
bd create "Implement user authentication" --priority P1

# Full task with description and acceptance criteria
bd create --title "Build REST API" --priority P1 \
  --description "CRUD endpoints for /users resource" \
  --acceptance "All endpoints return proper status codes, validation on input" \
  --type feature --labels "api,backend"

# Create child task under an epic
bd create "Add login endpoint" --parent bd-a3f8e9 --priority P1

# Quick capture (output ID only)
bd q "Fix CSS alignment on dashboard"

# Create with dependencies
bd create "Deploy to staging" --deps "blocks:bd-1,blocks:bd-2" --priority P2
```

## Workflow

1. Create task: `bd create --title "..." --priority P1`
2. Spawn agent for task: `overstory sling <bead-id> --capability lead --name <name>`
3. Agent claims task: `bd update <id> --claim`
4. Agent completes: `bd close <id>`
