# overstory mail — Inter-Agent Messaging

SQLite-backed messaging system for agent communication.

## Subcommands

### send — Send a message

```bash
overstory mail send --to <agent> --subject <text> --body <text> [options]
```

| Flag | Description |
|------|-------------|
| `--to <agent>` | Recipient agent name |
| `--subject <text>` | Message subject |
| `--body <text>` | Message body |
| `--from <name>` | Sender name (default: current agent) |
| `--type <type>` | Message type (see below) |
| `--priority <level>` | `low`, `normal`, `high`, `urgent` |
| `--payload <json>` | Attached JSON payload |
| `--json` | Output as JSON |

**Message types:**
- Semantic: `status`, `question`, `result`, `error`
- Protocol: `worker_done`, `merge_ready`, `merged`, `merge_failed`, `escalation`, `health_check`, `dispatch`, `assign`

### check — Check inbox (unread)

```bash
overstory mail check [--agent <name>] [--inject] [--json]
```

### list — List messages with filters

```bash
overstory mail list [--from <name>] [--to <name>] [--unread] [--json]
```

### read — Mark a message as read

```bash
overstory mail read <message-id>
```

### reply — Reply to a message

```bash
overstory mail reply <message-id> --body <text> [--from <name>] [--json]
```

### purge — Delete old messages

```bash
overstory mail purge --all | --days <n> | --agent <name> [--json]
```

## Examples

```bash
# Dispatch work to an agent
overstory mail send --to api-lead --subject "Build REST API" \
  --body "Implement CRUD endpoints for /users. See spec in docs/api.md." \
  --type dispatch

# Check for new messages
overstory mail check

# List unread messages from a specific agent
overstory mail list --from api-lead --unread

# Read and acknowledge a message
overstory mail read msg-abc123

# Reply to a message
overstory mail reply msg-abc123 --body "Acknowledged, starting work now"
```
