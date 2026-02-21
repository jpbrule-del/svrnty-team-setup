#!/usr/bin/env bash
# Hook: PreToolUse
# Matcher: Task|TeamCreate
# Purpose: Block native Claude Code agent spawning — force overstory sling

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)

if [ "$TOOL_NAME" = "Task" ]; then
    cat <<'EOF'
{"decision": "block", "reason": "BLOCKED: Do NOT use the native Task tool to spawn agents. Use Overstory instead:\n\n1. Create a beads task: bd create --title=\"<title>\" --priority P1\n2. Spawn via overstory: overstory sling <bead-id> --capability <scout|builder|lead|reviewer|merger> --name <agent-name>\n3. Dispatch via mail: overstory mail send --to <agent-name> --subject \"<subject>\" --body \"<instructions>\" --type dispatch\n\nSee .overstory/agent-defs/ for agent capabilities. Monitor with: overstory dashboard"}
EOF
    exit 0
fi

if [ "$TOOL_NAME" = "TeamCreate" ]; then
    cat <<'EOF'
{"decision": "block", "reason": "BLOCKED: Do NOT use native Claude Code teams. Use Overstory agent orchestration instead:\n\n- Spawn agents: overstory sling <bead-id> --capability <type> --name <name>\n- Track tasks: bd create / bd list / bd close\n- Group tasks: overstory group create '<name>' <bead-id-1> <bead-id-2>\n- Monitor: overstory dashboard\n\nSee CLAUDE.md for the full orchestration workflow."}
EOF
    exit 0
fi

echo '{"decision": "allow"}'
