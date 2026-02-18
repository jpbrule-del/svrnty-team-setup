---
name: init
description: Initialize Overstory agent orchestration in the current project (Overstory + Beads + Mulch + worktrees)
argument-hint: "[mulch-domains...]"
disable-model-invocation: true
allowed-tools:
  - Bash
---

# Initialize Orchestration

Run the init script in a single command. Pass any user-provided domain arguments through:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/init-project.sh" $ARGUMENTS
```

Run this single command and present the output to the user. Do NOT run any other commands — the script handles everything.
