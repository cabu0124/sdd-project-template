# Spec NNN — [feature name]

- **Status:** draft <!-- draft | review | approved | done | superseded -->
- **Created:** YYYY-MM-DD
- **Updated:** YYYY-MM-DD
- **Owner:** [who answers questions about this spec]
- **Consumers:** [repo] · [repo] <!-- repositories expected to implement it; "unknown" is an honest answer -->
- **Verifier:** [repo] <!-- multi-repo specs only; delete when one repository builds all of it -->
- **US:** [id or link] <!-- delete if none -->
- **Supersedes:** [NNN-slug] <!-- delete if none -->
- **Superseded by:** [NNN-slug] <!-- delete unless the status is superseded -->

WHAT the product must do, and why. No technology and no repository: the same spec
holds for every repo that implements it. HOW, and which part each repo builds,
belong in `plan.md`.

## Problem

[What is wrong or missing today, and who feels it. 2-4 sentences.]

## Scope

**In:**

- [...]

**Out:**

- [Named exclusions. "Out" is as informative as "In" — it prevents scope drift.
  Product-level only: work another repo does is still *in* scope here. The split
  between repos is drawn in `plan.md`, never in this file.]

## Requirements

Numbered and testable. If you cannot say how to verify it, rewrite it. Phrased as
product behaviour — a requirement naming an endpoint, a framework, a table or a
repository is a plan decision that leaked in.

- **R1** — [...]
- **R2** — [...]

## Acceptance criteria

Each criterion names the requirement it verifies, and is observable from outside
the product.

- [ ] **AC1** (R1) — Given [context], when [action], then [observable result].
- [ ] **AC2** (R2) — [...]

## Verification

[Multi-repo specs only. Delete this section when one repository builds the whole
spec. Give every acceptance criterion an owner. Evidence is a link to the run
that proved it; `Verified at` is the revision of this spec used by that run.]

| AC | Answered by | Verified at | Evidence |
| --- | --- | --- | --- |
| AC1 | `[repo]` | [tag or commit of this spec] | [link to the run that proved it] |
| AC2 | `[repo]` · `[repo]` — integrated | — | — |

## Non-functional

[Performance, security, accessibility, compatibility budgets. Delete if none.]

## Open questions

What is still undecided. The spec is not approvable while any remain.

- [ ] [...]

## Amendments

Append-only, and only once the status has been `approved` at least once. Name
what changed and who has to re-sync. See `docs/lifecycle.md`.

- `YYYY-MM-DD` — [what changed, and which consumers it affects]
