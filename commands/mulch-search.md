# mulch search — Search Expertise

Search expertise records across domains.

## Usage

```bash
mulch search [query] [options]
```

## Options

| Flag | Description |
|------|-------------|
| `--domain <domain>` | Limit search to a specific domain |
| `--type <type>` | Filter by record type: `convention`, `pattern`, `failure`, `decision`, `reference`, `guide` |
| `--tag <tag>` | Filter by tag |

## Examples

```bash
# Search across all domains
mulch search "authentication"

# Search within a specific domain
mulch search "API design" --domain backend

# Search for failure records only
mulch search "deployment" --type failure

# Search by tag
mulch search --tag "database"

# Search for decisions
mulch search "PostgreSQL" --type decision
```

## See Also

- `mulch prime` — Generate priming prompt from expertise
- `mulch query` — Query expertise records with domain filter
- `mulch status` — Show status of expertise records
