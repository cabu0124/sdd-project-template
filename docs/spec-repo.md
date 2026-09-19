# The Spec Repository

<!-- How this repository gets its specs. Read it when configuring `/sdd-sync`,
     when a sync reports drift, or when you are tempted to edit a spec here. -->

This repository builds a product whose specs live somewhere else: a **Spec
Repository**, the single source of truth for WHAT the product does and why.
Several development repositories — frontend, backend, workers, infrastructure —
consume the same spec.

## Who owns what

| Artifact | Lives in | Answers |
| --- | --- | --- |
| `spec.md` | the **Spec Repository** — read from there, never copied here | WHAT the product must do, and why |
| `wireframe.html` | the **Spec Repository** — read from there, never copied here | where things sit on screen |
| `spec.link.yml` | **here** | which spec this directory implements |
| `plan.md` | **here** | HOW *this* repo implements it |
| `tasks.md` | **here** | the ordered units of work, *here* |
| the code | **here** | — |

The line is the same one `docs/cross-repo.md` (if present) draws between
sibling repos, moved
one step out: the spec is not narrowed per repo, and the split between repos is
drawn in `plan.md` → `## Scope in this repo`. A plan or a task list in the Spec
Repository is the failure mode this separation exists to prevent — it would make
the Spec Repository decide how every consumer builds.

```text
Spec Repository            this repository
  specs/001-password-reset
        │                    specs/007-password-reset/
        │  /sdd-sync          spec.link.yml    which spec, and where
        └──── read at ref ───▶   plan.md          /sdd-plan   ← ours
           never copied      tasks.md         /sdd-tasks  ← ours
```

## Configuration

`.sdd/config.yml`, committed, is the whole mechanism. It names a repository, a
ref and a directory — no organisation, no tracker, no URL is assumed anywhere in
the template.

```yaml
spec_repo:
  name: acme-specs
  path: ../acme-specs                        # optional cache of this remote
  remote: git@github.com:acme/acme-specs.git # authority when configured
  ref: main                                  # branch to track, or tag to pin
  specs_dir: specs
```

**Authority:** when `remote` is configured, it defines the published ref. `path`
is used only when its `origin` URL exactly matches `remote`; normal sync fetches
that remote ref, so an unpublished local commit cannot be registered. A
different origin is ignored. `scripts/spec-sync.sh --offline <id>` is the
explicit exception: it reads the last remote ref cached at the matching path and
reports that freshness was not verified. When `remote` is empty, a valid `path`
is an intentional local-only authority. Every source is read through Git at a
resolved commit, never from its working tree.

**`ref` is a policy choice.** A branch (`main`) tracks specs as they are
approved — right for a team that moves together. A tag (`v1.4.0`) pins this
repository to a reviewed set and makes upgrading a deliberate act — right when
the consumers are on different cadences. Either way `spec.link.yml` records the
resolved commit, so what was built against is always recoverable.

**No Spec Repository yet?** Set `spec_repo: none`. `/sdd-specify` then writes
specs here and the repository behaves exactly as a single-repo project. Moving to
a Spec Repository later is `/sdd-init` again, plus one `/sdd-sync` per spec.

## Ids

Two numbers, one join key — the rule `docs/cross-repo.md` (if present) already sets:

| | Spec Repository | here |
| --- | --- | --- |
| Number | its own sequence | its own sequence |
| Slug | identical | identical |

`001-password-reset` upstream may be `007-password-reset` here. The slug is what
makes the story greppable across repositories; `spec.link.yml` holds the exact
mapping, so nothing depends on the numbers matching.

## There is no copy, and that is the design

An earlier arrangement mirrored `spec.md` under `specs/` so it was reviewable in
a pull request and readable offline. It also made the spec a file in this
repository — and a file in this repository can be edited. Once it is, this repo
has its own version of what was agreed, the hash recorded beside it agrees with
it, and everything looks right locally while every other consumer builds
something else.

So the copy is gone. `specs/<id>-<slug>/spec.link.yml` records which spec this
directory implements and where to read it; the spec itself stays in the Spec
Repository and is read from there at `ref`.

```bash
scripts/spec-sync.sh --list                     # the spec ids upstream
scripts/spec-sync.sh <id>                       # preview; write nothing
scripts/spec-sync.sh --write <sha> <id>         # register the reviewed revision
scripts/spec-pointer-check.sh                   # every pointer, no credentials
scripts/sdd-check.sh                            # what CI runs
```

`scripts/spec-sync.sh` is the mechanical half of `/sdd-sync`: preview resolves
the Spec Repository to one commit and reports what changed since the revision
this repository last reviewed, without writing. Apply takes that full commit
SHA and records it. A moving branch therefore cannot replace the revision the
user reviewed. It never touches `plan.md` or `tasks.md`, and it never writes
spec content anywhere.

**`source.commit` is not what gets read.** Reads follow `ref`, so an approved
change upstream reaches this repository with no action — there is no copy to
refresh. The commit records the revision last reviewed *here*, which is what
makes "a requirement moved since the plan was written" a diff somebody reviews
rather than a change nobody notices.

| Situation | What to do |
| --- | --- |
| The spec is ambiguous or wrong | Raise it in the Spec Repository — `/sdd-clarify` there |
| The spec asks for something impossible here | Stop and say so, as Rule 1 requires. The answer is a spec change upstream, not a local edit |
| The spec is right but this repo only builds part of it | Nothing to change. That split is `plan.md` → `## Scope in this repo` |
| Upstream changed | `/sdd-sync <id>` again; it diffs the two revisions and reports what the change invalidates |
| A `spec.md` appeared beside a pointer | Delete it. It is a second WHAT, and the `spec-pointer` job fails on it |

## Drift

There is no local copy, so a spec cannot drift from its source here. What can
drift is the plan and the tasks written against an older wording, and that is
what `/sdd-sync` reports:

- **Upstream drift** — the spec at `ref` is no longer the revision recorded in
  `spec.link.yml`. The preview diffs the two revisions out of git and exits 3.
  A changed requirement or acceptance criterion sends `plan.md` back through
  `/sdd-plan` and `tasks.md` through `/sdd-tasks`; a spec that moved to
  `superseded` upstream stops work here until the user decides.
- **A copy put back** — someone added `spec.md` beside the pointer. That is not
  drift to reconcile, it is a file to delete.

### What the `spec-pointer` job proves

`.github/workflows/spec-pointer.yml` runs `scripts/sdd-check.sh` on every pull
request, and `scripts/spec-pointer-check.sh` within it answers two questions:

| Question | Catches |
| --- | --- |
| Is every `spec.link.yml` well formed — a real source id, a full commit, `synced.local_id` equal to its directory, and the ref the config reads? | a pointer to the wrong spec, a renamed directory, a repo reading a different ref |
| Is there any `spec.md` or `wireframe.html` beside a pointer? | a spec copied back in, by hand or by an old habit |

It reads nothing outside this repository, so it needs no access to the Spec
Repository and no credentials — a consequence of the design rather than a
shortcut: with no local copy there is nothing to compare against the source.

When `spec_repo` is `none` this repository writes its own specs with
`/sdd-specify`. Then there are no pointers, every spec under `specs/` is local
and legitimate, and `scripts/spec-check.sh` is what validates it.

Run `scripts/sdd-check.sh` locally — it is the same code CI runs, so it says the
same thing.

## Before any command reads: preflight

`scripts/sdd-preflight.sh` runs before `/sdd-sync`, `/sdd-plan`, `/sdd-tasks`
and `/sdd-implement`. It fetches and inspects — never merges, rebases or
switches a branch — and blocks when this repository, the Spec Repository or any
registered consumer is behind, or when the spec being worked on moved upstream
since it was last reviewed here. Full behaviour in
[commands/preflight.md](commands/preflight.md).

It learns which repositories to check from the Spec Repository, which publishes
them in `docs/consumers.md` as one delimited JSON block:

```markdown
<!-- sdd:consumers:start -->
{"version": 1, "consumers": [{"name": "acme-web", "builds": "the web app"}]}
<!-- sdd:consumers:end -->
```

fenced as `json` between those two comments. Each `name` is the repository's
directory name, resolved as a sibling of the Spec Repository clone unless
`--repo Name=/path` says otherwise. The registry is optional: without it
preflight checks this repository alone and says so, which is the right answer
for a single-repo product.

## Sibling development repositories

Contracts between consumers — endpoints, payloads, config keys — are technology,
so they never enter the Spec Repository. They are owned by one development repo,
published as an artifact there, and **referenced** by the consumers at a pinned
revision rather than copied into each of their plans. Full rules in
`docs/cross-repo.md`, when the product spans repos.
