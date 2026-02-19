# overstory doctor — Health Checks

Run health checks on all Overstory subsystems.

## Usage

```bash
overstory doctor [options]
```

## Options

| Flag | Description |
|------|-------------|
| `--json` | Output as JSON |
| `--verbose` | Show passing checks (default: only problems) |
| `--category <name>` | Run only one category |

## Categories

| Category | What it checks |
|----------|---------------|
| `dependencies` | Required CLI tools are installed |
| `structure` | `.overstory/` directory layout is correct |
| `config` | Configuration file is valid |
| `databases` | SQLite databases (mail, etc.) are accessible |
| `consistency` | Cross-references between agents, tasks, worktrees |
| `agents` | Active agent health |
| `merge` | Merge queue state |
| `logs` | Log file integrity |
| `version` | Overstory version compatibility |

## Examples

```bash
# Full health check
overstory doctor

# Verbose — show passing checks too
overstory doctor --verbose

# Check only dependencies
overstory doctor --category dependencies

# JSON output for scripting
overstory doctor --json
```

## See Also

- `bd doctor` — Beads database health checks
- `mulch doctor` — Mulch expertise record validation
