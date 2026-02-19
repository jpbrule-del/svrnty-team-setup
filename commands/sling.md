# overstory sling — Spawn a Worker Agent

Spawn a new agent into an isolated worktree, assigned to a Beads task.

## Usage

```bash
overstory sling <task-id> --capability <type> --name <agent-name> [options]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `<task-id>` | Beads task ID to assign (e.g., `bd-a3f8e9`) |
| `--name <name>` | Unique agent name |

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--capability <type>` | `builder` | Agent type: `builder`, `scout`, `reviewer`, `lead`, `merger` |
| `--spec <path>` | — | Path to task spec file |
| `--files <f1,f2,...>` | — | Exclusive file scope (comma-separated) |
| `--parent <agent-name>` | — | Parent agent for hierarchy tracking |
| `--depth <n>` | `0` | Current hierarchy depth |
| `--json` | — | Output result as JSON |

## Agent Types

| Type | Purpose |
|------|---------|
| `lead` | Owns a work stream end-to-end, can spawn depth-2 agents |
| `builder` | Implements code in isolated worktree |
| `scout` | Read-only exploration, reports findings |
| `reviewer` | Validates quality before merge |
| `merger` | Handles complex merge conflicts |

## Examples

```bash
# Spawn a lead for a work stream
overstory sling bd-a3f8e9 --capability lead --name api-lead --depth 1

# Spawn a builder under a lead
overstory sling bd-b2c4d6 --capability builder --name api-builder --parent api-lead --depth 2

# Spawn a scout for exploration
overstory sling bd-c3d5e7 --capability scout --name research-scout --parent api-lead --depth 2

# Spawn with file scope restriction
overstory sling bd-d4e6f8 --capability builder --name ui-builder --files "src/components/,src/styles/"
```

## Workflow

1. Create a Beads task first: `bd create --title="Task" --priority P1`
2. Spawn the agent: `overstory sling <bead-id> --capability <type> --name <name>`
3. Dispatch work via mail: `overstory mail send --to <name> --subject "Work" --body "Instructions" --type dispatch`
