# Team Pipeline Sequence

The standard pipeline runs teams in order:

1. **planning** — produces stories + sprint plan
2. **development** — builders consume stories, produce code
3. **testing** — tester + security audit the code
4. **qa** — validates acceptance criteria

## Orchestrator Sequence

The orchestrator sequences teams by:

1. Spawning a team with `/svrnty-team-setup:team spawn <name>`
2. Monitoring with `/svrnty-team-setup:team status <name>`
3. After the team completes, spawning the next team in the pipeline

## Artifact Flow

| Team | Reads From | Writes To |
|------|-----------|-----------|
| Planning | Project brief (dispatch) | `docs/planning/`, `docs/stories/` |
| Development | `docs/stories/*.md` | Feature branches |
| Testing | Merged development branches | `docs/testing/` |
| QA | `docs/testing/`, `docs/stories/` | `docs/qa/` |

## Notes

- Teams use existing overstory primitives (sling, mail, groups, beads) — no new abstractions.
- The team lead coordinates phase execution within its pipeline.
- Artifacts flow between teams via committed files.
- Each phase agent works in its own worktree, commits its output, and signals completion to the lead.
- The lead merges each agent's worktree branch before spawning the next phase.
