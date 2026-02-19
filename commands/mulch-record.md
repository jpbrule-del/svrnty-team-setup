# mulch record — Record New Learnings

Record an expertise record to persist knowledge across sessions.

## Usage

```bash
mulch record <domain> [content] [options]
```

## Record Types

| Type | Required Fields | Description |
|------|----------------|-------------|
| `convention` | `content` or `--description` | Coding conventions and standards |
| `pattern` | `--name`, `--description` | Recurring patterns and approaches |
| `failure` | `--description`, `--resolution` | Failures and how they were resolved |
| `decision` | `--title`, `--rationale` | Architecture/design decisions |
| `reference` | `--name`, `--description` | Reference material and documentation |
| `guide` | `--name`, `--description` | How-to guides and procedures |

## Key Flags

| Flag | Description |
|------|-------------|
| `--type <type>` | Record type (see above) |
| `--classification <level>` | `foundational`, `tactical`, `observational` |
| `--name <name>` | Name of the convention or pattern |
| `--description <desc>` | Description of the record |
| `--resolution <text>` | Resolution (for failure records) |
| `--title <text>` | Title (for decision records) |
| `--rationale <text>` | Rationale (for decision records) |
| `--files <files>` | Related files (comma-separated) |
| `--tags <tags>` | Comma-separated tags |
| `--evidence-commit <hash>` | Evidence: commit hash |
| `--evidence-bead <id>` | Evidence: bead ID |
| `--dry-run` | Preview without writing |
| `--batch <file>` | Read JSON records from file |

## Examples

```bash
# Record a convention
mulch record backend "Always use snake_case for API endpoint paths" \
  --type convention --classification foundational

# Record a pattern
mulch record backend --type pattern \
  --name "Repository pattern" \
  --description "All database access goes through repository classes in src/repos/"

# Record a failure and resolution
mulch record deployment --type failure \
  --description "Docker build failed due to missing .env" \
  --resolution "Added .env.example template and documented in README"

# Record a decision
mulch record architecture --type decision \
  --title "Use PostgreSQL over SQLite for production" \
  --rationale "Need concurrent writes and JSON indexing"

# Batch recording from file
mulch record backend --batch records.json
```
