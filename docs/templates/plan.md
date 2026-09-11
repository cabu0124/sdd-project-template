# Plan — Spec NNN

- **Repo:** <this-repo> · <role: backend | frontend | mobile | infra | ...>

HOW **this repository** implements the approved spec. The spec is the same
everywhere; this is where it becomes technology, and where this repo's share of
it is decided. A sibling repo implementing the same spec writes its own plan.

## Scope in this repo

<Which of the spec's requirements this repo implements, and which of its
acceptance criteria are verified here. The rest name the repo that owns them — an
unnamed exclusion is how the same work gets built twice, or not at all.

Delete this section when the spec is single-repo: everything in it is this repo's.
See `docs/cross-repo.md`, if present.>

- **Here:** R1, R2 — AC1, AC2, AC4
- **Elsewhere:** R3 — `<repo>` NNN <what it covers>

## Approach

<3-5 lines. The shape of the solution, not a task list.>

## Areas touched

- `<path or module>` — <what changes>

## Contract and schema changes

<API endpoints, payloads, DB migrations, config keys, public interfaces.
Anything another component or person depends on. Delete if none.

A contract is technology, so it lives here and never in the spec. Two kinds, and
a plan can carry both:

- **Owned** — defined here, and published as an artifact at a path in this repo
  so consumers reference one definition rather than each keeping a copy.
- **Given** — owned by another repo. Record the reference and the revision this
  repo builds against, not a second copy of the text: a copy cannot tell you the
  owner changed it. It is an input, so if it is wrong, incomplete or
  contradicted by reality, STOP and ask. Never adjust it locally.

A given contract needs a contract test here, proving this repo still matches the
revision it pinned. See `docs/cross-repo.md`, if present.>

- **Owned:** `<path in this repo>` — <what it defines>
- **Given:** `<repo>` · `<path>` @ `<revision>` — <what this repo consumes>
  - Contract test: `<path>`

## Rollout

<Delete when the change lands finished in one merge — most do.

- **Flag:** `<NNN-slug>` — <provider or mechanism>, default off
- **Reaches `main` off after:** <which task>
- **Turned on when:** <the observable condition, not a date>
- **Removed by:** <the task in `tasks.md` that deletes it>

A flag with no removal condition is permanent. See `docs/delivery.md`.>

## Alternatives rejected

- <Option> — <why not, one line>

## Risks

- <Risk> → <mitigation>

## Test strategy

<What proves each acceptance criterion scoped to this repo: unit, integration,
manual steps. Name the level, not every case.>
