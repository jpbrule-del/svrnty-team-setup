---
name: doctor
description: Repair the current project and sync it to the latest installed plugin version
disable-model-invocation: true
allowed-tools:
  - Bash
---

# svrnty doctor — Repair & Sync Project

Run health checks on the full stack, repair common issues, and sync the project's orchestration config to the latest installed plugin version.

## Usage

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh"
```

Run this single command and present the output to the user. Do NOT run any other commands — the script handles everything.
