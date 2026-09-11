# AGENTS.md — [project]

<!-- Fill <...>. Delete what doesn't apply. Keep under 60 lines: this loads every session. -->

**Source of truth for every agent.** Tool adapters (`CLAUDE.md`, `GEMINI.md`, …) are generated
per developer by `docs/commands/onboard.md`, only point here, and hold no project content.

<!-- sdd:rule1:start -->
## Rule 1 — Spec First

No code without an approved spec. But first, classify the request:

- **No spec — just do it:** typo/wording fix, dependency bump, formatter output, comments, or a change to the SDD scaffolding itself (`AGENTS.md`, `docs/`, templates, agent command/skill files).
- **Ask first — never assume:** bug fix, copy change beyond a typo, refactor, config tweak, or anything you are unsure about. Ask the user *"spec this, or handle it as a no-spec change?"* and follow the answer — in doubt, ask; do not default to writing the spec.
- **Spec required:** a new feature, or any change to WHAT the product does — user-visible behaviour, a contract, a data model. Then:

1. Find the spec in `specs/` — WHAT the product does, independent of stack and repo. Not here yet: `/sdd-sync <id>` mirrors it from the Spec Repository named in `.sdd/config.yml`, or `/sdd-specify` writes it when none is configured. A local spec stops for approval; a mirror carries its owner's approval in `status:` and is not approved again here.
2. Follow that spec's `plan.md` — HOW **this** repo implements it — and its `tasks.md`, the work to do **here** and nothing else. Missing? Create from templates, STOP for approval.
3. Implement one task at a time, checking it off in `tasks.md`. Spec and code disagree → STOP and ask; never edit the spec to match the code — a mirrored spec is owned by the Spec Repository and is corrected there, for every repo.
<!-- sdd:rule1:end -->

## Project

<What it is + stack, 2-3 lines.>
<Interface: web · mobile · desktop · none, and its breakpoints. Drives wireframes.>

## Commands

- Run: `<cmd>`
- Test: `<cmd>`
- Lint: `<cmd>`
- Build: `<cmd>`

## Conventions

- Language/version: <...>
- Naming: <...>
- <One line per project-type rule: API contract, component pattern, migrations...>

## Boundaries

- Never touch: <generated files, migrations, secrets, vendored dirs>
- Ask before: <new dependency, public API change, schema change>

## Done means

- [ ] Acceptance criteria in `spec.md` met — the ones `plan.md` scopes here
- [ ] `<test cmd>` passes and `<lint cmd>` is clean
- [ ] `tasks.md` updated

## Read on demand (not upfront)

| Need | File |
| --- | --- |
| Running a stage of the loop | `docs/commands/` |
| Principles, trade-off rules | `docs/constitution.md` |
| Active spec, and where specs come from | `specs/<NNN-slug>/` · `docs/spec-repo.md` |
| Artifact structure | `docs/templates/` (incl. `wireframe.html`) |
| Branching, flags, releases | `docs/delivery.md` |
| US spanning several repos | `docs/cross-repo.md` (multi-repo projects only) |
| Roles for a subagent or chat mode | `docs/agents/` |
| Model-invoked how-to guides | `docs/skills/` |
| Always-on rules scoped to a file glob | `docs/standards/` |
