# /sdd-plan — technical design for an approved spec

**Goal.** Decide HOW **this repository** implements the approved spec, and write
it to `specs/<NNN-slug>/plan.md`. The spec is the same in every repo that
implements it; this is the file where it becomes technology, and where this
repo's share of it is fixed.

Argument: a spec id.

## Read first

- The spec. If `status:` is neither `approved` nor `done`, or `## Open questions`
  is not empty, stop and say so. That gate is the point of the method, not a
  formality: `draft` and `review` are still being written, and `superseded` was
  replaced — plan against the successor it names. `done` is published work that
  was delivered, not a contract that expired, so a repository joining the
  product later plans against it like any other. A spec that is not here yet is
  not written here: `/sdd-sync <id>` brings it in.
- `spec.link.yml`, when the spec has one — it is mirrored from the Spec
  Repository. Check it with `scripts/spec-hash.sh --check specs/<NNN-slug>`:
  a mismatch means the mirror was edited here, and that is a stop, not a detail.
  The approval gate is upstream's `status:`; this repo does not grant it.
- `AGENTS.md` — stack, conventions, boundaries, what is off-limits.
- `docs/constitution.md` — it outranks convenience when you have to choose.
- The code that will change: the modules the spec touches, the tests around them,
  the patterns they already follow, the dependencies already available.
- `docs/spec-repo.md`, when the spec is mirrored — what this repo may decide
  about it, and what it may not.
- `docs/cross-repo.md`, if present and the spec names other repositories — and
  the plans of the sibling repos that already have one, for the contract and for
  who took what. `/sdd-init` creates it for multi-repo products.
- `docs/delivery.md` — the branch, flag and release model this repo ships under.
- `docs/templates/plan.md`.

## Ask only

Decisions that are the user's rather than yours: a new dependency, a public API
change, a schema change, anything `AGENTS.md` lists under "Ask before". And
trade-offs where two options are genuinely close and the choice is about
priorities rather than facts.

Do not ask what the code answers. A pattern used in three places is the
convention here, and reading it is faster than asking about it.

## Steps

1. Read. State which existing patterns you will follow and which dependencies are
   already present, so a wrong assumption is caught before it is designed in.
2. Ask what only the user can decide.
3. Scope this repo first, when the spec spans several: which requirements it
   implements and which acceptance criteria it verifies, and which repo takes the
   rest, named. Everything below depends on that line being drawn, and it is
   drawn here — never by editing the spec. Single-repo spec: this repo takes all
   of it, and the section goes away.
4. Write `plan.md`: the approach, the areas touched and what changes in each,
   contract and schema changes, alternatives rejected with the reason, risks with
   their mitigation, and a test strategy that names what proves each acceptance
   criterion scoped here.
5. Prefer the smallest thing that satisfies the spec. An abstraction the spec
   does not ask for is permanent cost paid for a guess.
6. If this repo owns a contract other repos consume, define it exactly here and
   publish it as an artifact at a path in this repo: endpoints, payloads, status
   codes, error shapes, config keys. Leave nothing implied. A contract this repo
   only consumes is recorded as a **reference** — the owning repo, the path and
   the revision built against — never as a second copy of the text, because a
   copy cannot tell anyone the owner has changed it. Pair it with a contract
   test that fails when this repo no longer matches the revision it pinned. It
   is an input, so if it is wrong, stop and ask rather than adjust it.
7. Decide the rollout. A spec that cannot land usable in one merge, or that
   changes behaviour users already rely on, ships behind a flag named after the
   spec and off by default; `## Rollout` records the flag and the condition that
   removes it. Most specs need none — say so by deleting the section, because a
   flag on work that lands in one merge costs more than it protects.
8. If the spec turns out to be wrong, contradictory or impossible, stop and say
   so. Never edit the spec to match a plan. A mirrored spec is corrected in the
   Spec Repository and re-synced — the fix belongs to every repo that consumes
   it, not to this plan.

## Writes

`specs/<NNN-slug>/plan.md`. No `tasks.md`, no code.

## Stops when

`plan.md` is written. Report the decisions taken and what you rejected. The user
approves the approach; then `/sdd-tasks <NNN>`.
