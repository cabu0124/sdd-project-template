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
| `spec.md` | the **Spec Repository** — mirrored here, read-only | WHAT the product must do, and why |
| `wireframe.html` | the **Spec Repository** — mirrored here, read-only | where things sit on screen |
| `plan.md` | **here** | HOW *this* repo implements it |
| `tasks.md` | **here** | the ordered units of work, *here* |
| the code | **here** | — |

The line is the same one `docs/cross-repo.md` draws between sibling repos, moved
one step out: the spec is not narrowed per repo, and the split between repos is
drawn in `plan.md` → `## Scope in this repo`. A plan or a task list in the Spec
Repository is the failure mode this separation exists to prevent — it would make
the Spec Repository decide how every consumer builds.

```text
Spec Repository            this repository
  specs/001-password-reset
        │  /sdd-sync
        └──────────────▶ docs/specs/007-password-reset/
                           spec.md          mirror, byte-identical
                           spec.link.yml    where it came from
                           wireframe.html   mirror, when the spec has one
                           plan.md          /sdd-plan   ← ours
                           tasks.md         /sdd-tasks  ← ours
```

## Configuration

`.sdd/config.yml`, committed, is the whole mechanism. It names a repository, a
ref and a directory — no organisation, no tracker, no URL is assumed anywhere in
the template.

```yaml
spec_repo:
  name: acme-specs
  path: ../acme-specs                        # tried first; needs no network
  remote: git@github.com:acme/acme-specs.git # fallback
  ref: main                                  # branch to track, or tag to pin
  specs_dir: specs
  mirror: [spec.md, wireframe.html]
```

**Resolution order:** `path` if it exists on disk, then `remote`, then stop and
report. Both are read with `git` at `ref`, never from a working tree, so two
repositories syncing the same id get the same bytes.

**`ref` is a policy choice.** A branch (`main`) tracks specs as they are
approved — right for a team that moves together. A tag (`specs-v4`) pins this
repository to a reviewed set and makes upgrading a deliberate act — right when
the consumers are on different cadences. Either way `spec.link.yml` records the
resolved commit, so what was built against is always recoverable.

**No Spec Repository yet?** Set `spec_repo: none`. `/sdd-specify` then writes
specs here and the repository behaves exactly as a single-repo project. Moving to
a Spec Repository later is `/sdd-init` again, plus one `/sdd-sync` per spec.

## Ids

Two numbers, one join key — the rule `docs/cross-repo.md` already sets:

| | Spec Repository | here |
| --- | --- | --- |
| Number | its own sequence | its own sequence |
| Slug | identical | identical |

`001-password-reset` upstream may be `007-password-reset` here. The slug is what
makes the story greppable across repositories; `spec.link.yml` holds the exact
mapping, so nothing depends on the numbers matching.

## The mirror is read-only

The copy under `docs/specs/` exists so the spec is reviewable in a pull request,
readable offline, and versioned with the plan that was written against it. It is
still not yours: `spec.link.yml` carries a `sha256` per mirrored file, and
`/sdd-sync` and `/sdd-analyze` compare against it.

One script takes that digest, `scripts/spec-hash.sh`, and everything that writes
or reads a hash calls it — `/sdd-sync`, `/sdd-analyze`, and the `spec-mirror`
job:

```bash
scripts/spec-hash.sh docs/specs/007-password-reset   # the files: block to record
scripts/spec-hash.sh --check                         # what CI runs
```

That is not ceremony. A hash is only evidence if everyone takes it the same way,
and the ways to take it differently are all mundane: `Get-FileHash` returns
uppercase hex, a mirror saved through an editor on Windows is CRLF where the
sync recorded LF, a hand-copied digest is a typo. Each of those fails a spec
nobody edited, in somebody else's pull request — which is why `.gitattributes`
pins the mirrored files to LF and why no command computes a digest of its own.

| Situation | What to do |
| --- | --- |
| The spec is ambiguous or wrong | Raise it in the Spec Repository — `/sdd-clarify` there. Never patch the mirror |
| The spec asks for something impossible here | Stop and say so, as Rule 1 requires. The answer is a spec change upstream, not a local edit |
| The spec is right but this repo only builds part of it | Nothing to change. That split is `plan.md` → `## Scope in this repo` |
| Upstream changed | `/sdd-sync <id>` again; it reports what the change invalidates |

A mirror edited here fails its own hash and every consumer keeps the old wording,
so the product quietly has as many WHATs as it has repositories. That is the one
rule this file exists to state.

## Drift

`/sdd-sync` re-run on a spec already present reports two diffs before it writes
anything:

- **Local drift** — the mirror no longer matches its recorded hash. Someone
  edited it here. Report and stop.
- **Upstream drift** — the source at `ref` no longer matches the mirror. Report
  what changed and what it invalidates: a changed requirement or acceptance
  criterion sends `plan.md` back through `/sdd-plan` and `tasks.md` through
  `/sdd-tasks`, and a spec that moved to `superseded` upstream stops work here
  until the user decides.

`/sdd-analyze` checks the same hashes, so a stale mirror surfaces at the quality
gate even if nobody re-synced. And the `spec-mirror` job in
`.github/workflows/spec-mirror.yml` recomputes them on every pull request, which
is the backstop for the case neither command covers: nobody thought to run
either one. Local drift cannot reach `develop`.

### When `spec-mirror` fails

Run `scripts/spec-hash.sh --check` locally — it is the same code, so it says the
same thing — and read which of the three it reported:

| The job says | What happened | Fix |
| --- | --- | --- |
| `does not match the hash recorded` | The mirror was edited here | Correct the spec upstream, then `/sdd-sync <id>` again |
| `matches … only once CR is stripped` | The mirror was committed CRLF, the hash recorded LF | `git config core.autocrlf input`, renormalise the file, commit. `.gitattributes` holds it after that |
| `is recorded in spec.link.yml but is not in …` | A mirrored file was deleted or renamed | `/sdd-sync <id>` again; the mirror's contents are the source's, not this repo's |

A mismatch on a spec you did not touch, in a repository where several people
sync, is almost always the second row — the bytes agree and the way they were
hashed did not. Re-running `/sdd-sync` fixes the symptom; committing
`.gitattributes` and taking every digest from `scripts/spec-hash.sh` is what
stops it recurring.

## Sibling development repositories

Contracts between consumers — endpoints, payloads, config keys — are technology,
so they never enter the Spec Repository. They are owned by one development repo,
defined in its `plan.md`, and copied verbatim into the consumers' plans. Full
rules in `docs/cross-repo.md`.
