# /sdd-preflight — the repositories are current before any command reads them

**Goal.** Before `/sdd-sync`, `/sdd-plan`, `/sdd-tasks` and `/sdd-implement`,
prove that this repository and every repository the work depends on contain a
freshly fetched integration branch, and that the spec being worked on is the one
upstream published. A plan written against a stale read is wrong in a way
nothing downstream detects.

Argument: optional. `--spec <id>` names the spec about to be worked on;
`--repo Name=/absolute/path` locates a clone that is not a sibling;
`--branch <name>` is the integration branch when it is not `develop`.

Reasoning: mechanical — it runs a script and reports its exit code.

## The script does the mechanics

```bash
scripts/sdd-preflight.sh                        # every required repository
scripts/sdd-preflight.sh --spec 007-password-reset
scripts/sdd-preflight.sh --repo acme-api=/abs/path
```

| Exit | Means | What you do |
| --- | --- | --- |
| 0 | Ready for this invocation | Continue the command that called it |
| 1 | Blocked | Report what it said and stop. Fix it yourself: preflight never does |

It **inspects and fetches only**. It never merges, rebases, switches branch,
stashes, commits or pushes. A repository that cannot be fast-forwarded is
reported, not repaired — updating somebody's working tree is not a thing a
preflight gets to decide.

## What it checks

1. **This repository** — on the integration branch, or on a branch ahead of it,
   and never behind the freshly fetched `origin/<branch>`.
2. **The Spec Repository** — that `spec_repo.ref` still resolves. It is read at
   that ref, which may be a tag, so it is resolved rather than branch-checked.
3. **Every consumer** — the repositories named in the Spec Repository's
   `docs/consumers.md`, in the same delimited JSON block `/sdd-init` documents.
   Each is resolved as a sibling of the Spec Repository clone unless `--repo`
   says otherwise, and each is checked like this repository.
4. **The spec pointers here** — well formed, with no spec copied in beside them,
   and each at the revision it records.

A spec that moved upstream **blocks only when it is the one being worked on**,
named with `--spec`. Every other moved spec is a warning: a repository with ten
specs would otherwise be unable to touch any of them because an unrelated one
was amended this morning.

## When it cannot check everything

Preflight degrades where the template does, and says which:

| Situation | What happens |
| --- | --- |
| `.sdd/config.yml` is unfilled | Warns, checks this repository only. `/sdd-init` fills it |
| `spec_repo: none` | Nothing upstream to check — this repository writes its own specs |
| No `docs/consumers.md` upstream | Warns, checks this repository only. Publish one to gate the siblings |
| A consumer has no local clone | Blocks, naming it. Clone it, or pass `--repo Name=/path` |

## Ask only

For a path it cannot resolve. Never choose a merge, a rebase, a branch switch or
a different ref on the user's behalf, and never continue the calling command on
a blocked result.

## Writes

Fetches update Git objects and remote-tracking refs in the repositories it
inspects. Nothing else: no working tree is modified, no branch is created or
moved, no file is written, and nothing is pushed.

## Stops when

Every required repository contains its freshly fetched integration branch and
the active spec is current, or a blocker has been reported. Success certifies
the commits observed during that run, not future ones — it is not reusable for
the next command, after a pause, or after a branch change.
