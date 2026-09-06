# Constitution

Durable principles for this project. They outrank convenience, habit and any
individual spec. Read this when a spec is silent and you must choose.

This is not a style guide — style lives in `AGENTS.md`.

## Principles

1. **Spec First.**
   No code without an approved spec — for anything that changes WHAT the product
   does. Trivial changes (typo, dependency bump, formatter output, the SDD
   scaffolding itself) skip it; for the middle ground — a bug fix, a copy change,
   a refactor — ask the user whether to spec it rather than assuming either way.
   *Why:* intent written down before code is reviewable, testable and cheap to
   change. Intent discovered from code is none of those. Forcing a spec onto a
   one-line fix teaches the team to route around the method.

2. **Simplicity over cleverness.**
   Build what the spec asks for, not what it might ask for later.
   *Why:* every unused abstraction is permanent cost paid for a guess.

3. **Every requirement is testable.**
   If you cannot state how to verify it, it is not a requirement yet — rewrite it.
   *Why:* "done" must be observable, not a matter of opinion.

4. **Small, reversible changes.**
   One task, one commit-sized unit. Prefer two safe steps to one clever leap.
   *Why:* small changes are reviewable and cheap to undo when wrong.

5. **Explicit over implicit.**
   State assumptions in the spec. When blocked, ask — never guess and proceed.
   *Why:* a wrong silent assumption is discovered late, after code depends on it.

## Project constraints

<Non-negotiables specific to this project: supported platforms, performance or
security budgets, compliance, data residency, deprecated approaches. Delete this
section if there are none — an empty placeholder is worse than nothing.>

## Amendments

Changing this file requires explicit human approval. Append the date and the
reason below; never edit a principle silently.

- `YYYY-MM-DD` — Initial version.
