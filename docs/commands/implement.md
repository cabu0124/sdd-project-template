# /sdd-implement — build the next task, and verify when the list is done

**Goal.** Move `tasks.md` forward by exactly one task. When no unchecked task is
left, verify the spec against its acceptance criteria instead.

Argument: a spec id.

## Read first

- `tasks.md` — the first unchecked task, and `## Notes` for what earlier runs hit.
- The spec — the requirements that task serves, and their acceptance criteria.
- The plan — how it was decided this would be built here, which of the spec's
  requirements and criteria this repo took, and its `## Rollout` when it names a
  flag.
- `AGENTS.md` — conventions, boundaries, and the test and lint commands.
- The code the task touches, and the tests around it.

## Ask only

When the task cannot be done as written: it contradicts the spec, it needs
something `AGENTS.md` lists under "Ask before", or the plan assumed something
that is not true. Then stop and ask — do not improvise a way around it.

Otherwise implement without asking. The decisions were made in `/sdd-plan`, and
re-opening them here is how a plan quietly stops being the plan.

## Steps

1. Read. Identify the first unchecked task and what would prove it done.
2. Implement it, following the conventions already in the code.
3. Run the test and lint commands from `AGENTS.md`. Failing means not done.
4. Check the task off in `tasks.md`. Add a line to `## Notes` only for something
   a later reader needs: a blocker, a decision taken mid-task, a deviation from
   the plan and why.
5. Stop. One task per run — the review between tasks is the point of the list.
6. If implementing reveals the spec was wrong, stop and say so. Never edit the
   spec to match the code; that inverts the whole method. A mirrored spec — one
   with a `spec.link.yml` beside it — is corrected in the Spec Repository and
   re-synced, so every consumer gets the same correction.

## When every task is checked

Verify instead of implementing:

1. Take the acceptance criteria the plan scopes to this repo, one at a time. For
   each, report the criterion, how you checked it, and the actual result. Run the
   check — do not reason about what it would return. A feature behind a flag is
   verified with the flag on; the flag decides who sees it, not whether the spec
   is met.
2. Criteria the plan lists under `Elsewhere` belong to another repo. Name that
   repo and leave them unchecked here; this repo is not blocked on them.
3. Report failures as failures, with the output. Do not fix anything in the same
   run.
4. Leave `status:` alone. Marking a spec `done` is the user's call.

## Writes

Source code, tests, and `tasks.md`. The plan only when the user has approved a
change to it. Never a mirrored `spec.md`, `wireframe.html` or `spec.link.yml`.

## Stops when

One task is checked off and its tests pass — or, on the verification run, every
acceptance criterion has been reported with its actual result.
