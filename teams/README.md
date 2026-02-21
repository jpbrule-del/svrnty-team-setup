# Team Definitions

Team definitions are YAML files that describe multi-agent workflow pipelines. Each team has a lead agent that coordinates sequential (and optionally parallel) phases.

## YAML Schema

```yaml
name: <team-name>
description: <what this team does>
phases:
  - name: <phase-name>
    capability: <agent-capability>
    input: <what this phase reads>
    output: <what this phase produces>
    parallel: true              # optional: run multiple agents in parallel
    parallel_with: <other-phase>  # optional: run alongside another phase
handoff:
  produces:
    - <output artifacts>
  next_team: <team-name or null>
```

## Predefined Teams

| Team | Description | Phases | Output |
|------|-------------|--------|--------|
| **planning** | BMAD planning pipeline | analyst -> pm -> architect -> scrummaster | `docs/stories/*.md`, `docs/planning/sprint-plan.yaml` |
| **development** | Sprint execution | builders (parallel, one per story) | Implemented code on feature branches |
| **testing** | Test + security audit | tester + security (parallel) | `docs/testing/test-report.md`, `docs/testing/security-report.md` |
| **qa** | Final quality assurance | qa | `docs/qa/qa-report.md` |

## Standard Pipeline Sequence

```
planning -> development -> testing -> qa
```

1. **Planning** produces stories and a sprint plan
2. **Development** builders consume stories and produce code on feature branches
3. **Testing** runs tests and security audits on merged code
4. **QA** validates acceptance criteria from the original stories

The orchestrator sequences teams by spawning each one, monitoring progress, and spawning the next team after the current one completes.

## Artifact Flow

| Team | Reads From | Writes To |
|------|-----------|-----------|
| Planning | Project brief (dispatch) | `docs/planning/`, `docs/stories/` |
| Development | `docs/stories/*.md` | Feature branches |
| Testing | Merged development branches | `docs/testing/` |
| QA | `docs/testing/`, `docs/stories/` | `docs/qa/` |

## Adding Custom Teams

Create a new YAML file in this directory following the schema above. Run `/svrnty-team-setup:doctor` to deploy it to any initialized project.
