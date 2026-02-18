---
name: status
description: Check the status of the orchestration stack (Overstory, Beads, Mulch, worktrees)
disable-model-invocation: true
allowed-tools:
  - Bash
---

# Orchestration Status

Run this single command and present the output:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/status.sh"
```

Do NOT run any other commands — the script handles everything.
