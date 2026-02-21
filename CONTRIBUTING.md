# Contributing to svrnty-team-setup

## Structure

```
commands/     — Slash command definitions (.md with YAML frontmatter)
skills/       — Skill definitions (SKILL.md with YAML frontmatter + references/)
hooks/        — Lifecycle hooks (svrnty-*.sh + hooks.json)
scripts/      — Shell scripts (sourced or called by commands/hooks)
teams/        — Team pipeline definitions (.yaml)
```

## Naming Conventions

- **Hook scripts**: `hooks/svrnty-<event-or-purpose>.sh`
- **Scripts**: `scripts/<name>.sh` (source `_common.sh` for logging)
- **Commands**: `commands/<name>.md` with YAML frontmatter
- **Skills**: `skills/<name>/SKILL.md` with YAML frontmatter
- **Team definitions**: `teams/<name>.yaml`

## Adding a New Hook

1. Create `hooks/svrnty-<name>.sh` with `#!/usr/bin/env bash` and `set -euo pipefail`
2. Add the hook entry to `hooks/hooks.json` under the appropriate event
3. Run `chmod +x hooks/svrnty-<name>.sh`
4. Update the Hooks Reference table in `README.md`

## Adding a New Command

1. Create `commands/<name>.md` with YAML frontmatter:
   ```yaml
   ---
   name: <name>
   description: <what it does>
   allowed-tools:
     - Bash
   ---
   ```
2. Add the command to `.claude-plugin/plugin.json` commands array
3. Update `README.md` Commands table

## Adding a New Skill

1. Create `skills/<name>/SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: <name>
   description: "<description with trigger phrases>"
   allowed-tools:
     - Bash
     - Read
   ---
   ```
2. Add the skill to `.claude-plugin/plugin.json` skills array
3. Optionally add `skills/<name>/references/` for extracted docs

## Adding a New Team

1. Create `teams/<name>.yaml` following the schema in `teams/README.md`
2. Run `/svrnty-team-setup:doctor` in a project to deploy it

## Scripts

All scripts should:
- Start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Source `_common.sh` for logging: `source "$(cd "$(dirname "$0")" && pwd)/_common.sh"`
- Use `ok`, `warn`, `fail`, `info` functions for consistent output

## Validation

Before submitting a PR:
```bash
bash validate-plugin.sh
```

This checks manifest validity, file references, frontmatter, permissions, and naming conventions.

## PR Process

1. Create a feature branch
2. Make changes following conventions above
3. Run `bash validate-plugin.sh` — must pass with 0 errors
4. Submit PR with description of changes
5. CI will run validation automatically
