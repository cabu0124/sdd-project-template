# Spec NNN — [feature name]

- **Status:** draft <!-- draft | review | approved | done | superseded -->
- **Date:** YYYY-MM-DD
- **US:** <id or link> <!-- shared across repos; delete if single-repo -->
- **Repos:** <repo> · <repo> <!-- every repo implementing it; delete if single-repo -->

WHAT the product must do, and why. No technology and no repository: the same spec
holds for every repo that implements it. HOW, and which part each repo builds,
belong in `plan.md`.

## Problem

<What is wrong or missing today, and who feels it. 2-4 sentences.>

## Scope

**In:**

- <...>

**Out:**

- <Named exclusions. "Out" is as informative as "In" — it prevents scope drift.
  Product-level only: work another repo does is still *in* scope here. The split
  between repos is drawn in `plan.md`, never in this file.>

## Requirements

Numbered and testable. If you cannot say how to verify it, rewrite it. Phrased as
product behaviour — a requirement naming an endpoint, a framework, a table or a
repository is a plan decision that leaked in.

- **R1** — <...>
- **R2** — <...>

## Acceptance criteria

Each criterion names the requirement it verifies.

- [ ] **AC1** (R1) — Given <context>, when <action>, then <observable result>.
- [ ] **AC2** (R2) — <...>

## Non-functional

<Performance, security, accessibility, compatibility budgets. Delete if none.>

## Open questions

What is still undecided. The spec is not approvable while any remain.

- [ ] <...>
