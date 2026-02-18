---
name: teardown
description: Merge agent branches, sync tasks and knowledge, clean up worktrees
disable-model-invocation: true
allowed-tools:
  - Bash
---

# Orchestration Teardown

Run this single command and present the output:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/teardown.sh"
```

Do NOT run any other commands — the script handles everything.
