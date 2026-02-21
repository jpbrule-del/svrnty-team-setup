---
name: update
description: Update the svrnty-team-setup plugin to the latest version and re-run setup
allowed-tools:
  - Bash
---

# svrnty-team-setup:update — Self-Update Plugin

Download the latest plugin version from the repository and re-run setup to update all dependencies.

## Usage

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update.sh"
```

Run this single command and present the output to the user. Do NOT run any other commands — the script handles everything.
