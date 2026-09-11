# Standard — <name>

<!-- Template. Copy to `docs/standards/<slug>.md` and fill <...>. One
convention per file — a naming rule, an API contract pattern, a test
requirement — scoped to the files it actually governs. `/sdd-onboard` turns
`applyTo` into the scoped-rule format each tool supports (Copilot `applyTo`,
Cursor `globs`); tools with no such mechanism skip it, so a standard that must
always apply belongs in `AGENTS.md` instead. -->

---
description: <what this enforces, one line>
applyTo: "<glob, e.g. src/api/**/*.ts>"
---

<The rule itself. Keep it short: on a matching tool this loads on every file
that matches `applyTo`.>
