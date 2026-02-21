# Team Definition YAML Schema

Teams are defined in YAML files with this structure:

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

## Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Unique team identifier |
| `description` | yes | Human-readable purpose |
| `phases` | yes | Ordered list of pipeline phases |
| `phases[].name` | yes | Phase identifier |
| `phases[].capability` | yes | Agent capability type (analyst, pm, architect, scrummaster, builder, tester, security, qa) |
| `phases[].input` | yes | What this phase reads (string or list) |
| `phases[].output` | no | What this phase produces (string or list) |
| `phases[].parallel` | no | If true, spawn multiple agents for this phase |
| `phases[].parallel_with` | no | Name of another phase to run concurrently |
| `handoff.produces` | yes | List of output artifacts |
| `handoff.next_team` | yes | Next team in pipeline, or `null` if final |
