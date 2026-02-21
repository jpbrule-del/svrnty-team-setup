# Version History

## 2.1.0 (current)

- Professional restructure: manifest upgrade with skills/commands arrays
- Hook rename: all hooks now use `svrnty-*` prefix (was `hybrid-*`/`block-*`/`auto-*`)
- Backward-compatible env var migration (`SVRNTY_WORKTREE_PATH`/`SVRNTY_AGENT_NAME`)
- Shared logging utilities (`scripts/_common.sh`)
- Parameterized Overstory repo URL (`SVRNTY_OVERSTORY_REPO`)
- SKILL.md YAML frontmatter and reference docs
- Setup.sh moved to `scripts/setup.sh` (root is thin wrapper)
- Validation script (`validate-plugin.sh`)
- CI/CD workflows for validation and manifest sync
- Documentation: VERSIONS.md, CONTRIBUTING.md, AGENTS.md, CLAUDE.md
- Removed accidental `.mulch/` dev state

## 2.0.0

- Multi-team orchestration (planning, development, testing, qa pipelines)
- Team definitions in YAML with phase sequencing
- `/svrnty-team-setup:team` skill (spawn, list, status)
- Auto-update hook with 1-hour cooldown
- 9 hooks across 8 Claude Code lifecycle events
- Commands moved from skills/ to commands/

## 1.0.0

- Initial Overstory + Beads + Mulch integration
- Agent spawning via `overstory sling` with worktree isolation
- Hook-based enforcement: block native Task/TeamCreate, worktree boundary
- CLAUDE.md generation with orchestration layer
- Setup script with dependency auto-install
