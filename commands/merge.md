# overstory merge — Branch Merging

Merge agent branches into the canonical branch using a 4-tier merge protocol.

## Usage

```bash
overstory merge --branch <name> | --all [options]
```

## Options

| Flag | Description |
|------|-------------|
| `--branch <name>` | Merge a specific branch |
| `--all` | Merge all pending branches in the queue |
| `--into <branch>` | Target branch (default: config `canonicalBranch`) |
| `--dry-run` | Check for conflicts without actually merging |
| `--json` | Output results as JSON |

## 4-Tier Merge Protocol

1. **Fast-forward** — No conflicts, branch is ahead of target
2. **Git auto-merge** — Standard 3-way merge resolves conflicts
3. **AI-assisted** — Overstory resolves with AI (when `aiResolveEnabled: true`)
4. **Reimagine** — Full AI reimagining (disabled by default, `reimagineEnabled: false`)

## Examples

```bash
# Dry-run check before merging
overstory merge --branch feature/api-endpoints --dry-run

# Merge a specific agent branch
overstory merge --branch feature/api-endpoints

# Merge all pending branches
overstory merge --all

# Merge into a specific target branch
overstory merge --branch feature/api-endpoints --into develop
```

## Workflow

1. Agent completes work and sends `merge_ready` mail
2. Orchestrator reviews: `overstory merge --branch <name> --dry-run`
3. If clean, merge: `overstory merge --branch <name>`
4. Clean up worktree: `overstory worktree clean --completed`
