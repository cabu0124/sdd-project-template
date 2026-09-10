# /sdd-sync — bring a spec in from the Spec Repository

**Goal.** Copy one spec from the product's Spec Repository into
`docs/specs/<NNN-slug>/`, verbatim, and record where it came from in
`spec.link.yml`. After this, `/sdd-plan` has something to plan against.

The spec is an **input** to this repository, not an artifact of it. Syncing it
changes nothing about who owns it: WHAT and WHY stay in the Spec Repository, and
this repo owns HOW — `plan.md`, `tasks.md`, the code.

Argument: a spec id as the Spec Repository names it (`001-password-reset`,
`SPEC-014`, …), or empty to list what is available and stop.

Re-run it any time to pick up an approved change upstream. Running it on a spec
already here is a re-sync, and it reports the diff before touching anything.

## Read first

- `.sdd/config.yml` — the Spec Repository, its ref, and where its specs sit. If
  `spec_repo: none`, stop: this repo writes its own specs with `/sdd-specify`.
  If it still holds `<...>` placeholders, stop and say so — `/sdd-init` fills it.
- `docs/spec-repo.md` — resolution order, ids, drift, and what to do about it.
- `docs/specs/` — the next free `NNN`, and whether this spec is already here
  under a different number.
- The source spec, once resolved: read it in full before copying it.

## Resolving the Spec Repository

In this order, first hit wins — and say which one you used:

1. **`path`**, when it exists on disk. No network, and it shows work that is
   committed there but not pushed. Read at `ref` rather than at the working
   tree, so two repositories syncing the same id get the same bytes:

   ```bash
   git -C <path> fetch --quiet          # skip if offline
   git -C <path> show <ref>:<specs_dir>/<id>/spec.md
   git -C <path> rev-parse <ref>
   ```

2. **`remote`**, otherwise — a shallow clone into a scratch directory, read, and
   remove:

   ```bash
   git clone --quiet --depth 1 --branch <ref> <remote> "$TMP/spec-repo"
   ```

3. Neither resolves → stop and report which was tried and what failed. Never
   invent the spec's content, and never fall back to writing one here.

## Ask only

- Which spec, when the argument is missing or matches more than one id.
- The local `NNN`, only when the obvious next number is already taken by
  something unrelated.
- Whether to proceed, when the source spec is not `approved`. A `draft` spec can
  be synced to read it, but `/sdd-plan` will refuse it, so say that plainly.

Nothing else. Everything here is mechanical once the id is known.

## Steps

1. Read `.sdd/config.yml` and resolve the Spec Repository. Report which source
   and which commit you are reading.
2. Locate `<specs_dir>/<id>/` at `ref`. Not there → list the ids that are, and
   stop.
3. Read the spec. Report its title, status, requirements and acceptance
   criteria, and — when it names them — the repositories that implement it. If
   this repository is not one of them, say so and ask before continuing.
4. Take the local `NNN`: the next free number in `docs/specs/`, zero-padded,
   never reused. Keep the source slug unchanged, so the story stays greppable
   across repositories — `007-password-reset` here may be `001-password-reset`
   there, and that is fine. See `docs/cross-repo.md` for the id rules.
5. Copy the files listed under `mirror` in the config, **byte for byte**, out of
   git rather than through you — `git -C <path> show <ref>:<specs_dir>/<id>/spec.md > docs/specs/<NNN-slug>/spec.md`.
   Content that passes through a reply is content that can be reflowed, and a
   mirror that differs by one whitespace fails its hash for every consumer. Do
   not reword, renumber, reformat or trim it to this repo either. A spec you
   have to edit to make it fit here is a spec written with a repo in mind — that
   correction belongs upstream, in the Spec Repository, for every consumer.
6. Write `spec.link.yml` beside it from `docs/templates/spec.link.yml`: the
   source id and path, the ref, the resolved commit, the status at sync time, and
   a `sha256` per mirrored file. Those hashes are what makes drift detectable.

   Take them from `scripts/spec-hash.sh`, never by hand and never with your own
   command, and paste the block it prints unchanged:

   ```bash
   scripts/spec-hash.sh docs/specs/<NNN-slug>    # prints the whole files: block
   ```

   `/sdd-analyze` and the `spec-mirror` job read those hashes back with the same
   script. A digest taken any other way — a different tool, uppercase hex, a
   file saved with CRLF — fails a mirror that nobody edited, and it fails it for
   the next person rather than for you.
7. **Re-sync** — when the directory already exists, diff before writing:
   - the mirror against its recorded hashes: `scripts/spec-hash.sh --check docs/specs/<NNN-slug>`.
     Different → it was edited **here**, which is not allowed. Report the diff
     and stop; the fix is upstream. The script says when the difference is only
     line endings, which is a checkout to correct, not a spec.
   - the mirror against the source at `ref`. Different → report the diff, and
     what it invalidates: a changed requirement or acceptance criterion means
     `plan.md` and `tasks.md` need a pass through `/sdd-plan` and `/sdd-tasks`.
     Overwrite only once the user has seen that.
8. Run `scripts/spec-hash.sh --check docs/specs/<NNN-slug>` before you report.
   It is what CI runs, so a sync that does not pass it is not finished.
9. Never write `plan.md`, `tasks.md` or code. `/sdd-plan <NNN>` is next.

## Writes

`docs/specs/<NNN-slug>/spec.md`, its `wireframe.html` when the source has one,
and `spec.link.yml`. Nothing in the Spec Repository — this command only reads it.

## Stops when

The spec is mirrored and `spec.link.yml` is written. Report the source commit,
the local number, the status upstream, and whether anything already planned here
is invalidated. Next: `/sdd-plan <NNN>` once the spec is `approved` upstream.
