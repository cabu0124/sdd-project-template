# /sdd-specify — write a new spec

**Goal.** Turn a feature request into `specs/<id>-<slug>/spec.md`: WHAT and
WHY, testable and approvable. No technical decisions and no repository
boundaries — both belong to `/sdd-plan`.

Argument: `[<id>] <description>` — the id this spec will carry, and what the
feature is. The id is optional only where `.sdd/config.yml` says
`spec_id.source: sequential`; see step 3. If the description is missing, ask for it.

Reasoning: high — it writes WHAT the product must do, and a requirement that can be read two ways is read two ways by everyone who builds it.

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
- `docs/skills/drawing-wireframes/` — only if `AGENTS.md` says this project has a
  user interface and this feature puts something on a screen. The template it
  points to is read by the subagent that draws, not here.
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
3. Settle the id before writing anything. `.sdd/config.yml` says where it comes
  from: **given as an argument**, use it exactly as written; **absent with
  `source: sequential`**, suggest the next free one in `specs/` and ask before
  continuing; **absent with `source: given`**, ask for it and stop. Then add a
  short slug. The id is permanent — commits, branches and issues.
4. Write `spec.md` from the template. Requirements are numbered `R1`, `R2`, …;
   every acceptance criterion names the requirement it verifies and is phrased so
   its result is observable. If you cannot say how a requirement would be
   verified, it is not a requirement yet — rewrite it. Write them as product
   behaviour: an endpoint, a framework, a table or a repository name in a
    requirement is a plan decision that leaked into the spec. Fill the metadata
    header — owner, dates, and the repositories expected to implement it, or
    `unknown` when nobody has decided yet.
5. Wireframe — only when `AGENTS.md` says this project has a user interface *and*
   this feature puts something on a screen. Follow
   `docs/skills/drawing-wireframes/`, which carries this project's notation and
   the rules a wireframe here must follow. Hand the first drawing to the
   `wireframe-artist` subagent: it writes `specs/<id>-<slug>/wireframe.html`
   itself and reports rather than returning the markup — the template is large,
   and handing it back would undo the point of delegating. Iterate here
   afterwards, reading the drawn file rather than the template again.
6. Cross-repo: one spec for the product, the same in every repo that implements
   it. Do not split the work between repos here and do not write a contract —
   both are `/sdd-plan`'s job. If a sibling repo already has this spec, copy it
   across instead of writing a second one. When `## Consumers` names more than
   one repository, fill `## Verification` with one row per acceptance criterion
   and name the `Verifier:` responsible for integrated criteria. A single-repo
   spec deletes the section and the header line. Follow `docs/cross-repo.md` if
   present.
7. Run `bash scripts/spec-check.sh --root specs specs/<id>-<slug>` and
   fix every reported structural or traceability error.
8. Report the requirements and anything left open.

## Writes

`specs/<id>-<slug>/spec.md`, plus `wireframe.html` beside it when step 5
applies. Nothing else — no `plan.md`, no `tasks.md`, no code.

## Stops when

`spec.md` is written, and its wireframe if the feature has screens. Approval
belongs to the user: they set `status: approved`, and `## Open questions` must be
empty first. Next: `/sdd-clarify` if anything is open, otherwise
`/sdd-plan <id>` once approved.
