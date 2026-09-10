# One US, several repos

<!-- Template. `/sdd-init` copies this to `docs/cross-repo.md` for products that
span repositories; single-repo projects never see it. -->

Read this when a product story is transversal but its implementation lives in
repos you cannot build or verify from here — frontend, backend, infrastructure,
each with its own copy of this template.

## The rule

**One spec for the product. One plan and one task list per repo.**

- `spec.md` — WHAT the product must do. Independent of the technology used and of
  the repository. Every repo that implements the story carries the same spec.
- `plan.md` — HOW **this** repo implements that spec, be it backend, frontend,
  mobile or infrastructure, and which part of it this repo takes.
- `tasks.md` — only the tasks needed to implement that spec **here**.

The split between repos is drawn in `plan.md` → `## Scope in this repo`. The spec
itself is never narrowed: narrow it per repo and you get as many different WHATs
as you have repos, none of which describes the product.

## Why the spec is not narrowed

`Done means` requires the acceptance criteria to be met, so a spec that promised
what another repo delivers could never satisfy its own definition of done — a
frontend spec carrying "the reset email is delivered" makes every verification
pass report a false failure.

The fix is not to amputate the spec. The criteria stay product-level, and the
plan says which of them this repo answers for:

```markdown
## Scope in this repo

- **Here:** R2, R3 — AC2, AC3, AC5
- **Elsewhere:** R1 — `api-svc` 012, token issue and email dispatch
```

`/sdd-implement` verifies the criteria in the first list and reports the rest as
belonging to the repo named. That is what keeps `Done means` satisfiable while
the spec stays whole.

## Shared vs local

| | Same in every repo | Local to this repo |
| --- | --- | --- |
| `US:` id | identical | — |
| Directory slug | identical | — |
| `NNN` number | — | own sequence |
| `spec.md` — Problem, Scope, Requirements, ACs | identical | — |
| `wireframe.html` | identical, in the repos that have screens | — |
| Contract (endpoint, payload, event, config key) | copied verbatim | — |
| `plan.md`, `tasks.md` | — | yes |

The slug is the join key. Numbers diverge between repos — `007-password-reset`
here may be `012-password-reset` there — and that is fine. The slug stays
identical so the story is greppable across repos.

A spec you have to edit to make it fit this repo is a spec that was written with
a repo in mind. Fix the wording, not the copy: the correction belongs in all of
them.

## Contract ownership

One repo **owns** the contract, normally the provider. It designs it in
`plan.md` → `## Contract and schema changes`, as any other design decision.

Every consumer repo receives it as a **given**, not a decision: copy it verbatim
into its own `plan.md`, marked as given and naming the owner. A contract is
endpoints, payloads and status codes — technology — so it belongs to HOW and
never appears in the spec.

If a consumer finds the contract wrong, incomplete or contradicted by reality:
**STOP and ask.** Do not adjust it locally. That is Rule 1.4 applied to the
seam — a contract silently edited on one side is the failure mode this whole
document exists to prevent.

## Writing the slice

- **`Elsewhere` names the other repos explicitly**, with their spec id when known:

  ```markdown
  - **Elsewhere:**
    - R1 — token generation and email dispatch — `api-svc` 012-password-reset
    - R4 — SES domain and rate-limit rules — `infra` 004-password-reset
  ```

  An unnamed exclusion is how the same work gets built twice or not at all.

- **The spec's `Out` stays product-level.** What another repo builds is *in*
  scope for the story, so it never goes in `Out` — it goes in `Elsewhere`. `Out`
  is for what nobody builds.

- **The test strategy covers the criteria scoped here, and no others.** Nothing
  in this weakens principle 3 of the constitution — every criterion is still
  testable, just not all of them from this repo.

## Blocked work

A consumer does not wait for the provider. Once the contract is agreed, build
against it: stub, mock or fake the interface, and make its removal a real task.

```markdown
- [ ] **T4** (R2) — Mock `POST /auth/reset` per the contract
- [ ] **T9** (R2) — Drop the mock, point at the real endpoint (blocked by `api-svc` 012)
```

Any task that cannot finish inside this repo carries `(blocked by <repo> NNN)`.
An unmarked blocked task looks like a task someone forgot to do.

## Done

This repo is done when the acceptance criteria its plan scopes here pass. **That
is not the US being done.** The US is done when every participating repo has
passed the criteria it took, which is tracked wherever the US lives — not here.

## Worked example

Product US: *a user who forgot their password can set a new one.* One spec says
that, and the same one sits in all three repos:

```text
US-4417
├── web-app   007-password-reset   consumer   request form, token screen, error states
├── api-svc   012-password-reset   OWNER      token issue/verify, email dispatch, POST /auth/reset
└── infra     004-password-reset   consumer   SES domain, rate-limit rule, token secret
```

Three columns of work, and each repo claims its own in `## Scope in this repo`,
naming who covers the rest. `api-svc` defines `POST /auth/reset` in its plan;
`web-app` and `infra` copy that block into theirs as a given. `web-app` mocks the
endpoint on day one and drops the mock when `api-svc` 012 lands. One spec, three
plans, three task lists, one contract, one US id.
