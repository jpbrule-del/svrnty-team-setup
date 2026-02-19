#!/usr/bin/env bash
# Hook: TaskCompleted — Auto-close Beads issues
set -euo pipefail

INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // empty' 2>/dev/null || true)
[ -z "$TASK_SUBJECT" ] && exit 0

# Match real bead IDs: project-name-hexhash (e.g., spacebot-jp-a3f2dd)
BEADS_ID=$(echo "$TASK_SUBJECT" | grep -oE '[a-zA-Z0-9_-]+-[a-f0-9]{4,}' | head -1 || true)
if [ -n "$BEADS_ID" ] && command -v bd &>/dev/null; then
    bd close "$BEADS_ID" 2>/dev/null || true
    echo "Auto-closed Beads task: $BEADS_ID"
fi
