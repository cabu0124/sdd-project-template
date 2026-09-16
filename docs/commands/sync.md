# /sdd-sync — register the spec this repository implements

**Goal.** Write `specs/<NNN-slug>/spec.link.yml`, which says which spec in the
product's Spec Repository this directory implements and where to read it. After
this, `/sdd-plan` has something to plan against.

**Nothing is copied.** The spec stays in the Spec Repository and is read from
there at the configured ref, every time a command needs it. This repository
holds a pointer, `plan.md`, `tasks.md` and the code — never a second version of
what was agreed. A copy here would be a file someone can edit, and then the
product has as many WHATs as it has repositories.

The spec is an **input** to this repository, not an artifact of it. Registering
it changes nothing about who owns it: WHAT and WHY stay in the Spec Repository,
and this repo owns HOW — `plan.md`, `tasks.md`, the code.

Argument: a spec id as the Spec Repository names it (`001-password-reset`,
`SPEC-014`, …), or empty to list what is available and stop.

Re-run it any time to pick up an approved change upstream. Running it on a spec
already registered is a re-sync, and it reports the diff before touching
anything.

## The script does the mechanics

```bash
scripts/spec-sync.sh --list           # the ids available upstream
scripts/spec-sync.sh <id>             # previews a new sync or re-sync; writes nothing
scripts/spec-sync.sh --write <sha> <id> # applies exactly the revision previewed
scripts/spec-sync.sh --offline <id>    # previews the last remote ref cached at path
```

It resolves the Spec Repository to one commit, reads the spec at that commit,
picks the local number, and writes the pointer. Do not reimplement any of it,
and never copy a spec through a reply: the spec belongs upstream, and content
that passes through you is content that can be reflowed.

With both `remote` and `path`, the remote is authoritative and the path is only
a cache when its `origin` matches exactly. Use `--offline` only after saying
that remote freshness cannot be checked; it never silently replaces normal
sync. A path without a remote is an explicit local-only source.

Its exit code is the whole interface:

| Exit | Means | What you do |
| --- | --- | --- |
| 0 | Already in sync, or an exact revision was applied | Report the commit, the local id and the status upstream |
| 1 | A spec was copied in beside the pointer, or that id is not upstream | Stop and report. The fix is upstream, never here |
| 2 | No Spec Repository configured, or the config is unfilled | Stop: `/sdd-specify` or `/sdd-init`, and say which |
| 3 | A new sync or re-sync is ready for review | The judgement below, then `--write <sha> <id>` |

## Read first

- `.sdd/config.yml` — whether there is a Spec Repository at all. `spec_repo: none`
  means this repository writes its own specs with `/sdd-specify`.
- `docs/spec-repo.md` — ownership, ids, pinning, and what drift means here.
- The source spec, in full, before you report anything about it.

## Ask only

- Which spec, when the argument is missing or matches more than one id.
- Whether to proceed, when the source spec is not published. A `draft` spec can
  be synced to read it, but `/sdd-plan` will refuse it, so say that plainly.
- Whether to apply a re-sync, once the diff has been seen and explained.

## Steps

1. `scripts/spec-sync.sh --list` when you have no id, or to confirm the one you
   were given exists upstream. If the remote is unavailable and the user accepts
   cached freshness, repeat with `--offline` and report that limitation.
2. `scripts/spec-sync.sh <id>`. It writes nothing. Report the source it read,
   the commit it resolved, and the proposed local directory.
3. Read the spec. Report its title, status, requirements and acceptance
   criteria, and — when it names them — the repositories that implement it. If
   this repository is not one of them, say so and ask before going further.
4. **Exit 3 — a re-sync is pending.** This is why the command is not just the
   script. Read the diff and say what it invalidates:
   - a changed requirement or acceptance criterion means `plan.md` and
     `tasks.md` need a pass through `/sdd-plan` and `/sdd-tasks`;
   - a changed wireframe may undo work already done;
   - wording that changes nothing built invalidates nothing, and saying that
     plainly is as useful as raising the alarm.

   Then run the exact command printed by preview,
   `scripts/spec-sync.sh --write <sha> <id>`, once the user has decided. The SHA
   is the approval boundary: if the source ref advances, the reviewed revision
   is still the one applied.
5. **Exit 1 — a spec was copied in here.** Do not re-sync over it and do not
   reconcile it. Delete the copy and report it: the spec is read from the Spec
   Repository, and a copy here is a second version of what was agreed.
6. Never edit the spec to fit this repository. A spec you have to reword to make
   it apply here was written with a repo in mind, and the fix is `/sdd-clarify`
   upstream, for every consumer.
7. Never write `plan.md`, `tasks.md` or code. `/sdd-plan <NNN>` is next.

## Writes

Through the script: `specs/<NNN-slug>/spec.link.yml`, and nothing else. No spec
content is written anywhere, here or upstream. A matching `path` cache may
receive fetched Git objects and refs.

## Stops when

The pointer is written, or a pending re-sync has
been reported and left with the user. Either way, name the source commit, the
local number, the status upstream, and whether anything already planned here is
invalidated. Next: `/sdd-plan <NNN>` once the spec is published upstream —
`approved`, or `done` if the work was already delivered elsewhere.
