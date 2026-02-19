# mulch prime — Load Expertise Context

Generate a priming prompt from expertise records to load relevant knowledge into the current session.

## Usage

```bash
mulch prime [domains...] [options]
```

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--domain <domains...>` | all | Domain(s) to include |
| `--exclude-domain <domains...>` | — | Domain(s) to exclude |
| `--full` | — | Include full record details (classification, evidence) |
| `-v, --verbose` | — | Full output with section headers and recording instructions |
| `--context` | — | Filter to records relevant to changed files only |
| `--files <paths...>` | — | Filter to records relevant to specified files |
| `--budget <tokens>` | `4000` | Token budget for output |
| `--no-limit` | — | Disable token budget limit |
| `--format <format>` | `markdown` | Output format: `markdown`, `xml`, `plain` |
| `--export <path>` | — | Export output to a file |
| `--mcp` | — | Output in MCP-compatible JSON format |

## Examples

```bash
# Load all expertise
mulch prime

# Load specific domains
mulch prime backend testing

# Load with full details
mulch prime --full

# Context-aware — only records relevant to changed files
mulch prime --context

# Load expertise for specific files
mulch prime --files "src/api/,src/models/"

# Export for use in prompts
mulch prime --export /tmp/context.md

# Higher token budget for comprehensive context
mulch prime --budget 8000
```

## When to Use

- At the start of a session to load project knowledge
- Before starting a new work stream to understand conventions
- When an agent needs domain-specific context
