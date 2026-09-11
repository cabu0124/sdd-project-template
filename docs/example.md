# Worked example — one spec, from the Spec Repository to shipped code

<!-- A complete run of the two templates together, end to end. It ships with
     `sdd-project-template` as documentation; `/sdd-init` deletes it. -->

Two repositories, created from the two templates:

```text
acme-specs   ← sdd-spec-template     the Spec Repository
acme-web     ← sdd-project-template  a development repository (frontend)
```

The feature: **a user who forgot their password can set a new one.**

---

## 1. Create the spec in `acme-specs`

Once per repository, after copying the template in:

```text
> Follow docs/commands/onboard.md.        # generates the sdd-* commands, per developer
/sdd-init new
```

`/sdd-init` asks what the product is, who consumes its specs, and the product
constraints; it fills `AGENTS.md`, `docs/constitution.md` and `README.md`, and
records `acme-web` under `docs/consumers.md`.

Then the spec itself:

```text
/sdd-specify a user who forgot their password can set a new one
```

It restates the request, asks what it cannot work out — who can request a reset,
how long the link lasts, what happens on a second request — and writes
`specs/014-password-reset/spec.md`:

```markdown
# Spec 014 — Password reset

- **Status:** draft
- **Created:** 2026-03-02
- **Updated:** 2026-03-02
- **Owner:** product@acme
- **Consumers:** `acme-web` · `acme-api`

## Requirements

- **R1** — A user who cannot sign in can ask for a reset using the email address on their account.
- **R2** — A reset request is answered identically whether or not the address has an account.
- **R3** — A reset link works once and expires 15 minutes after it is issued.
- **R4** — Setting a new password signs the user out of every other session.

## Acceptance criteria

- [ ] **AC1** (R1) — Given a registered address, when a reset is requested, then a reset link reaches that address within 2 minutes.
- [ ] **AC2** (R2) — Given an unregistered address, when a reset is requested, then the response and the time it takes are indistinguishable from AC1.
- [ ] **AC3** (R3) — Given a link used once, when it is opened again, then the user is told it is no longer valid and can request a new one.
- [ ] **AC4** (R4) — Given a session open on another device, when the password is changed, then that session is signed out.
```

Note what is **not** there: no endpoint, no token format, no mail provider, no
table. Those are decisions for the repositories that can see a codebase.

The wireframe is written beside it, because the product has screens.

```text
/sdd-clarify 014          # closes what is still open
/sdd-status 014 approved  # the gate: open questions empty, and the user says so
```

`/sdd-status` checks the gate, writes the status, updates `specs/INDEX.md`, and
reports: **`acme-web` and `acme-api` can now sync 014.**

---

## 2. Configure `acme-web`

Once per repository:

```text
> Follow docs/commands/onboard.md.
/sdd-init existing
```

Among its questions is where the specs live. The answer lands in
`.sdd/config.yml` — the only coupling between the two repositories:

```yaml
spec_repo:
  name: acme-specs
  path: ../acme-specs
  remote: git@github.com:acme/acme-specs.git
  ref: main
  specs_dir: specs
  mirror: [spec.md, wireframe.html]
```

`/sdd-init` verifies it before reporting it —
`git -C ../acme-specs ls-tree main:specs` has to list the specs.

---

## 3. Consume the spec

```text
/sdd-sync 014-password-reset
```

It resolves `path` first (no network, and it says so), reads
`specs/014-password-reset/` at `main`, reports the spec's title, status and
requirements, takes the next free local number — `007` — and writes:

```text
docs/specs/007-password-reset/
  spec.md          byte-identical to acme-specs
  wireframe.html   byte-identical
  spec.link.yml
```

```yaml
# spec.link.yml
spec_repo: acme-specs
source:
  id: 014-password-reset
  path: specs/014-password-reset
  ref: main
  commit: 4f9a1c0e7b3d2a5f8c1e6b0d9a4f7c2e5b8d1a30
  status: approved
synced:
  at: 2026-03-05
  local_id: 007-password-reset
files:
  spec.md: 9c1b7e...
  wireframe.html: 2a4f80...
```

Local `007`, upstream `014`, same slug. The mirror is read-only from here on:
those hashes are checked on every re-sync and by `/sdd-analyze`.

---

## 4. Plan — the part that is this repository's

```text
/sdd-plan 007
```

It refuses a spec that is not published upstream, checks the mirror against its
hashes, reads the code that will change, asks only what the code cannot answer,
and writes `docs/specs/007-password-reset/plan.md`:

```markdown
# Plan — Spec 007

- **Repo:** `acme-web` · frontend

## Scope in this repo

- **Here:** R1, R3 — AC3, and the request half of AC1
- **Elsewhere:**
  - R2, R4 — token issue, timing equivalence, session revocation — `acme-api` 012-password-reset
  - AC1's delivery half — `acme-api` 012

## Approach

Two routes on the existing auth stack: a request form and a token screen, both
unauthenticated, reusing the `AuthLayout` and the form primitives already in
`src/features/auth/`.

## Contract and schema changes

**Given** — owned by `acme-api` (its plan for 012), copied verbatim:

    POST /auth/reset-request  { email }        → 202, always
    POST /auth/reset          { token, pass }  → 204 | 410 expired | 400 invalid

## Rollout

- **Flag:** `007-password-reset` — off by default
- **Removed by:** T8
```

The spec was not narrowed to fit the frontend: the criteria stay product-level,
and `## Scope in this repo` says which of them this repository answers for. That
is what keeps `Done means` satisfiable while the spec stays whole. The contract
is technology, so it lives here and never in `acme-specs`.

---

## 5. Tasks

```text
/sdd-tasks 007
```

Ordered, commit-sized, and only this repository's work:

```markdown
- [ ] **T1** (R1) — Reset request form at `/reset`, with the AuthLayout
- [ ] **T2** (R1) — Mock `POST /auth/reset-request` per the contract
- [ ] **T3** (R3) — Token screen at `/reset/:token`, new-password form
- [ ] **T4** (R3) — Used or expired link: the state AC3 describes
- [ ] **T5** (R1) — Point at the real endpoint, drop the mock (blocked by `acme-api` 012)
- [ ] **T8** — Remove flag `007-password-reset` and the old path
```

R2 and R4 get no task here — the plan assigned them to `acme-api`, and a
placeholder task for another repository's work is worse than none. The mock has
its own removal task, and so does the flag.

---

## 6. Implement

```text
/sdd-implement 007      # once per task
```

One task per run: it implements, runs the test and lint commands from
`AGENTS.md`, checks the box, and stops. When every box is checked, the same
command verifies instead — each acceptance criterion the plan scoped here, run
rather than reasoned about, with its actual result. AC2 and AC4 are reported as
`acme-api`'s, and this repository is not blocked on them.

---

## When the spec changes

`acme-specs` reworders R3 from 15 minutes to 1 hour:

```text
# in acme-specs
/sdd-clarify 014        # rewrites R3, appends an amendment line
                        # "2026-03-14 — R3: 15 minutes → 1 hour. Consumers: re-sync."
```

```text
# in acme-web
/sdd-sync 014-password-reset
```

It diffs the mirror against the source before writing anything, reports that a
requirement changed and that the plan and tasks built on it need a pass through
`/sdd-plan` and `/sdd-tasks`, and overwrites only once that has been seen.

Had someone instead edited the mirror in `acme-web`, the hash in `spec.link.yml`
would not match, and `/sdd-sync` and `/sdd-analyze` would both stop and say so.
The fix for a wrong spec is always upstream, where it reaches every repository.

---

## What lived where

| | `acme-specs` | `acme-web` |
| --- | --- | --- |
| `spec.md`, `wireframe.html` | owner | read-only mirror |
| Status, amendments | owner | recorded in `spec.link.yml` |
| `plan.md`, `tasks.md`, code | never | owner |
| The contract | never | owned by `acme-api`, copied verbatim |
| Spec number | `014` | `007`, same slug |
