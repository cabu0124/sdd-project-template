# /sdd-specify — write a new spec

**Goal.** Turn a feature request into `specs/<NNN-slug>/spec.md`: WHAT and
WHY, testable and approvable. No technical decisions and no repository
boundaries — both belong to `/sdd-plan`.

Argument: a description of the feature. If it is missing, ask for it.

## First: does this repository own its specs?

Read `.sdd/config.yml`.

- **A Spec Repository is configured.** Specs are owned there, not here. Stop, and
  say which: the feature belongs in that repository — write it there with its own
  `/sdd-specify` — and comes back with `/sdd-sync <id>`. If it already exists
  upstream, run `/sdd-sync` instead of writing anything. Writing a second spec
  here would give the product two WHATs, one per repo, which is the failure this
  split exists to prevent.
- **`spec_repo: none`.** This repository owns its specs. Continue below — the
  workflow is unchanged.

## Read first

- `AGENTS.md` — scope, boundaries, and what "done" means here.
- `docs/constitution.md` — constraints an individual spec cannot override.
- `specs/` — the next free number, and whether an existing spec already
  covers part of this. Overlapping scope is a question, not a silent merge.
- `docs/templates/spec.md` — the structure to produce.
- `docs/templates/wireframe.html` — only if `AGENTS.md` says this project has a
  user interface and this feature puts something on a screen.
- `docs/cross-repo.md` — only if present and the feature spans several
  repositories. `/sdd-init` creates it for multi-repo products.
- `docs/spec-repo.md` — the ownership rule this command has just checked.
- Enough of the codebase to describe the problem accurately. Not to design it.

## Ask only

What changes the WHAT: who the users are and what they are trying to do, what is
explicitly out, how someone would know it works, which constraints are real
today. Ambiguity you can resolve by reading, resolve by reading.

Do not ask how it should be built. If the answer would only change `plan.md`,
it is not a question for this stage.

Anything still open when the spec is written goes to `## Open questions` instead
of being guessed. That is what the section is for, and `/sdd-clarify` closes it.

## Steps

1. Read, then restate the request in two or three sentences and name what you
   understood to be out of scope. A wrong reading surfaces here, cheaply.
2. Ask what is missing.
3. Take the next free `NNN` in `specs/` — zero-padded, never reused — and a
   short slug. The number is the permanent id for commits, branches and issues.
4. Write `spec.md` from the template. Requirements are numbered `R1`, `R2`, …;
   every acceptance criterion names the requirement it verifies and is phrased so
   its result is observable. If you cannot say how a requirement would be
   verified, it is not a requirement yet — rewrite it. Write them as product
   behaviour: an endpoint, a framework, a table or a repository name in a
    requirement is a plan decision that leaked into the spec. Fill the metadata
    header — owner, dates, and the repositories expected to implement it, or
    `unknown` when nobody has decided yet.
5. Wireframe — only when `AGENTS.md` says this project has a user interface *and*
   this feature puts something on a screen. Copy `docs/templates/wireframe.html`
   into the spec directory and draw it: one section per screen in scope and no
   screen the spec does not name, each at the project's breakpoints, with the
   states the spec calls for, and the banner filled with this spec's path. Draw
   arrangement, hierarchy and on-screen content — never color, type, iconography
   or components: a wireframe that looks finished gets reviewed as a design
   instead of a layout. Every element traces to a requirement, so if you find
   yourself drawing something no requirement asks for, the spec is incomplete.
   Fix the spec; do not invent it here.
6. Cross-repo: one spec for the product, the same in every repo that implements
   it. Do not split the work between repos here and do not write a contract —
   both are `/sdd-plan`'s job. If a sibling repo already has this spec, copy it
   across instead of writing a second one. When `## Consumers` names more than
   one repository, fill `## Verification` with one row per acceptance criterion
   and name the `Verifier:` responsible for integrated criteria. A single-repo
   spec deletes the section and the header line. Follow `docs/cross-repo.md` if
   present.
7. Run `bash scripts/spec-check.sh --root specs specs/<NNN-slug>` and
   fix every reported structural or traceability error.
8. Report the requirements and anything left open.

## Writes

`specs/<NNN-slug>/spec.md`, plus `wireframe.html` beside it when step 5
applies. Nothing else — no `plan.md`, no `tasks.md`, no code.

## Stops when

`spec.md` is written, and its wireframe if the feature has screens. Approval
belongs to the user: they set `status: approved`, and `## Open questions` must be
empty first. Next: `/sdd-clarify` if anything is open, otherwise
`/sdd-plan <NNN>` once approved.
