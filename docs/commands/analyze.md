# /sdd-analyze — quality gate before implementing

**Goal.** Read the spec, plan and tasks against each other and against the
project, and report what does not line up.

Optional. Worth running when the spec is large, the stakes are high, or the three
artifacts were written across several sessions. A gate that always finds
something stops being read.

Argument: a spec id.

## Read first

Everything this gate compares:

- `spec.md`, `plan.md` and `tasks.md` of that spec, and `wireframe.html` if it
  has one.
- `AGENTS.md` and `docs/constitution.md`.
- The current state of the code the plan touches.
- `spec.link.yml`, if the spec is mirrored, and `docs/spec-repo.md`.
- `docs/cross-repo.md` (if present) and the current contract from the owning
  repo, if the plan carries a contract this repo does not own.

## Ask only

Nothing, until you have reported. This command reads and reports; what follows is
the user's decision. Ask afterwards only to confirm which corrections to apply.

## Steps

Check in this order, and report findings grouped by severity:

1. **Coverage** — every requirement has an acceptance criterion; every
   requirement the plan scoped to this repo has a place in the plan and at least
   one task; every task traces back to one of them. A requirement the plan puts
   elsewhere needs no task here, but it does need to name the repo that has it —
   a requirement in neither list is one nobody is building, and a flag the plan
   names with no task that removes it is debt already agreed to.
2. **Consistency** — the plan does not contradict the spec, the tasks do not
   contradict the plan, and nothing was silently widened along the way.
3. **Separation** — the spec states WHAT the product does, with no technology and
   no repository in it; the plan is how *this* repo builds it; the tasks are the
   work to do *here*. An endpoint or a framework in a requirement belongs in the
   plan; a task for what another repo builds does not belong at all.
4. **Testability** — every acceptance criterion scoped here has something in the
   test strategy that would actually prove it.
5. **Wireframe** — if the spec has one: every screen it draws is a screen the
   spec puts in scope, every element on it traces back to a requirement, and
   nothing it shows contradicts the spec. A drifted wireframe is corrected
   through `/sdd-clarify`, or upstream when it is mirrored — never the spec, to
   match the picture.
6. **Project fit** — nothing conflicts with the boundaries in `AGENTS.md` or the
   principles in the constitution. Name the principle when it does.
7. **Technical** — risks the plan does not mention, work it assumes exists and
   does not, ordering in `tasks.md` that cannot hold.
8. **Spec drift** — if the spec is mirrored, run
   `scripts/spec-hash.sh --check docs/specs/<NNN-slug>` — the same script that
   recorded the hashes, so a failure is the file and never the method. A
   mismatch means it was edited here: report the diff, and
   that the correction belongs in the Spec Repository. Then compare the mirror
   with the source at the configured `ref`: an upstream change that touches a
   requirement or an acceptance criterion invalidates the plan and the tasks
   built on it. Neither is fixed here — `/sdd-sync <id>` is.
9. **Contract drift** — if the plan carries a contract another repo owns, read it
   at the revision the plan pinned and compare that with the owner's current
   one. List every difference and what it breaks here, and say whether a
   contract test in this repo would have caught it. A diverged contract is a
   deliberate upgrade and a decision for the user, not a local edit.
10. **State** — what is already implemented, so the run resumes rather than
   restarts.

Then propose a correction for each finding, naming the file it belongs in. If
nothing is wrong, say that plainly and stop.

## Writes

Nothing, unless the user asks for the corrections to be applied — and then
through the command that owns the file: `/sdd-clarify` for the spec and its
wireframe, `/sdd-plan` for the plan, `/sdd-tasks` for the task list.

## Stops when

The findings are reported. Next: fix what is worth fixing, then
`/sdd-implement <NNN>`.
