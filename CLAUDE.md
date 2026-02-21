# svrnty-team-setup Plugin Development

This file guides development of the svrnty-team-setup plugin itself.

## Project Structure

```
svrnty-team-setup/
├── .claude-plugin/plugin.json    — Plugin manifest (version, skills, commands)
├── hooks/hooks.json              — Hook registration (events -> scripts)
├── hooks/svrnty-*.sh             — Hook scripts (svrnty- prefix required)
├── scripts/_common.sh            — Shared logging (ok/warn/fail/info)
├── scripts/*.sh                  — Setup, doctor, init, update scripts
├── commands/*.md                 — Slash command definitions (YAML frontmatter)
├── skills/*/SKILL.md             — Skill definitions (YAML frontmatter)
├── teams/*.yaml                  — Team pipeline definitions
└── validate-plugin.sh            — Plugin validation script
```

## Rules

1. All hook scripts must use the `svrnty-` prefix
2. All `.md` skill/command files must have YAML frontmatter
3. All scripts must source `scripts/_common.sh` for logging
4. The Overstory repo URL must use `${SVRNTY_OVERSTORY_REPO:-...}` pattern
5. Env vars must support both `SVRNTY_*` and legacy `HYBRID_*` prefixes

## Testing

```bash
# Validate plugin structure
bash validate-plugin.sh

# Test setup (thin wrapper delegates to scripts/setup.sh)
bash setup.sh

# Test in a project
claude --plugin-dir .
/svrnty-team-setup:doctor
/svrnty-team-setup:team list
```

## Version Bumping

Update version in `.claude-plugin/plugin.json` and add entry to `VERSIONS.md`.
