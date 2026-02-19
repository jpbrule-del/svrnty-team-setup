# overstory dashboard — Live TUI Dashboard

Live terminal dashboard for monitoring agents, mail, merge queue, and metrics.

## Usage

```bash
overstory dashboard [options]
```

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--interval <ms>` | `2000` | Poll interval in milliseconds (min: 500) |
| `--all` | — | Show data from all runs (default: current run only) |

## Dashboard Panels

| Panel | Contents |
|-------|----------|
| **Agents** | Active agents with status, capability, bead ID, duration |
| **Mail** | Recent messages with priority and time |
| **Merge Queue** | Pending/merging/conflict entries |
| **Metrics** | Session counts, avg duration, by-capability breakdown |

## Examples

```bash
# Start dashboard with default settings
overstory dashboard

# Faster refresh rate
overstory dashboard --interval 1000

# Show all runs
overstory dashboard --all
```

Press `Ctrl+C` to exit.

## See Also

- `overstory status` — One-shot status check (non-interactive)
- `overstory feed` — Unified real-time event stream
