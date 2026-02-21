# Team Orchestration Skill

Manage multi-agent teams for structured workflow pipelines.

## Usage

```
/svrnty-team-setup:team spawn <team-name>     — Spawn a team (creates beads, lead, group)
/svrnty-team-setup:team list                   — List available team definitions
/svrnty-team-setup:team status <team-name>     — Show team progress
```

## Instructions

When the user invokes `/svrnty-team-setup:team`, parse the subcommand and arguments, then execute the appropriate action below.

### `spawn <team-name>`

Spawn a team by reading its definition and creating the required overstory primitives.

**Steps:**

1. Read the team definition from `.overstory/teams/<team-name>.yaml` (or the plugin's `teams/` directory if not deployed yet).

2. Create a bead for the team lead:
   ```bash
   bd create --title="<team-name> team lead" --priority P0 --desc="Coordinate <team-name> pipeline: <phase list>"
   ```

3. Spawn the team lead:
   ```bash
   overstory sling <lead-bead-id> --capability lead --name <team-name>-lead
   ```

4. Create an overstory group for tracking:
   ```bash
   overstory group create '<team-name>-team' <lead-bead-id>
   ```

5. Send the lead a dispatch message with the full team definition:
   ```bash
   overstory mail send --to <team-name>-lead \
     --subject "Team: <team-name>" \
     --body "Execute <team-name> pipeline. Phases: <phase descriptions with capabilities, inputs, and outputs>. <project brief or context from user>" \
     --type dispatch --agent $OVERSTORY_AGENT_NAME
   ```

6. Report the team spawn status to the user.

### `list`

List all available team definitions.

**Steps:**

1. Check for team YAML files in `.overstory/teams/` (project-local) and the plugin's `teams/` directory.
2. For each YAML file, read the `name` and `description` fields.
3. Display a formatted table:

```
Available Teams:
  planning     — BMAD planning pipeline: analysis to sprint-ready stories
  development  — Sprint execution: builders implement stories
  testing      — Test execution and security audit
  qa           — Final quality assurance
```

### `status <team-name>`

Show the current progress of a spawned team.

**Steps:**

1. Check for an active overstory group matching `<team-name>-team`:
   ```bash
   overstory group status <group-id>
   ```

2. Check for the team lead agent:
   ```bash
   overstory status
   ```

3. Check mail from the team lead:
   ```bash
   overstory mail list --from <team-name>-lead --agent $OVERSTORY_AGENT_NAME
   ```

4. Report team status including:
   - Lead agent state (active/completed/stalled)
   - Phase progress (which phases complete, which in progress)
   - Any pending messages or blockers

## Team Definitions

Teams are defined in YAML files with this structure:

```yaml
name: <team-name>
description: <what this team does>
phases:
  - name: <phase-name>
    capability: <agent-capability>
    input: <what this phase reads>
    output: <what this phase produces>
    parallel: true  # optional: run multiple agents in parallel
    parallel_with: <other-phase>  # optional: run alongside another phase
handoff:
  produces:
    - <output artifacts>
  next_team: <team-name or null>
```

## Team Pipeline Sequence

The standard pipeline runs teams in order:

1. **planning** → produces stories + sprint plan
2. **development** → builders consume stories, produce code
3. **testing** → tester + security audit the code
4. **qa** → validates acceptance criteria

The orchestrator sequences teams by:
1. Spawning a team with `/svrnty-team-setup:team spawn <name>`
2. Monitoring with `/svrnty-team-setup:team status <name>`
3. After the team completes, spawning the next team in the pipeline

## Notes

- Teams use existing overstory primitives (sling, mail, groups, beads) — no new abstractions.
- The team lead coordinates phase execution within its pipeline.
- Artifacts flow between teams via committed files in `docs/planning/`, `docs/stories/`, `docs/testing/`, `docs/qa/`.
- Each phase agent works in its own worktree, commits its output, and signals completion to the lead.
- The lead merges each agent's worktree branch before spawning the next phase.
