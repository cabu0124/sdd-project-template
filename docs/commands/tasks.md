# /sdd-tasks — break a plan into commit-sized units

**Goal.** Write `docs/specs/<NNN-slug>/tasks.md`: an ordered list where every
item can be implemented and verified on its own.

Argument: a spec id.

## Read first

- The spec — requirements and acceptance criteria.
- The plan — which of them this repo took, the areas it touches, and the order
  its approach implies. `## Scope in this repo` is the boundary of this list.
- `AGENTS.md` — the test and lint commands each task must leave passing.
- The code, enough to know what already exists. A task to build something that is
  already there is worse than no task at all.
- `docs/cross-repo.md`, if present and the spec names other repositories.
- `docs/templates/tasks.md`.

## Ask only

Almost nothing — sequencing is derivable from the plan. Ask when the plan leaves
a real fork: two orders with materially different risk, or a task whose size
depends on how much the user wants landing in one commit.

## Steps

1. Read the spec and the plan together.
2. Derive tasks from the plan's areas and the requirements the plan scoped here.
   Each task is one commit-sized unit, names the requirement id it serves, and
   leaves the repository working with its tests passing. Write only what this
   repo builds — a requirement the plan assigned elsewhere gets no task here, not
   even a placeholder one.
3. Order by dependency: a task that consumes another's output comes after it.
4. Check coverage both ways — every requirement scoped to this repo has at least
   one task, every task serves at least one of them. Report anything that fails
   this; it usually means the plan missed something, and that is a `/sdd-plan`
   fix, not a task you invent here.
5. Cross-repo: a task that cannot finish inside this repo is marked
   `(blocked by <repo> NNN)`, and every mock written against a contract gets its
   own removal task.
6. A plan with a `## Rollout` flag ends its list with the task that removes it:
   the flag, its reads and the old path, in one commit. Same rule as the mock —
   what is added for a transition gets its own removal task, or it never gets
   removed.
7. Leave `## Notes` empty. `/sdd-implement` fills it as it goes.

## Writes

`docs/specs/<NNN-slug>/tasks.md`. No code.

## Stops when

`tasks.md` is written and coverage is reported. Next: `/sdd-analyze <NNN>` when
the spec is large or the stakes are high, otherwise `/sdd-implement <NNN>`.
