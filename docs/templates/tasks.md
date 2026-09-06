# Tasks — Spec NNN

Ordered. Each task is one commit-sized unit and names the requirement it serves.
The checkboxes are the progress record.

Only the work needed to implement this spec **in this repository**, as scoped by
`plan.md` → `## Scope in this repo`. What another repo builds never appears here,
not even as a reminder. A task that cannot finish here is marked
`(blocked by <repo> NNN)`, and every mock written against a contract gets its own
removal task — see `docs/cross-repo.md`. A feature behind a flag ends the list
with the task that deletes it — see `docs/delivery.md`.

- [ ] **T1** (R1) — <task>
- [ ] **T2** (R1) — <task>
- [ ] **T3** (R2) — <task>
- [ ] **T4** (R2) — Remove flag `NNN-slug` and the old path <!-- if one is scoped -->

## Notes

<Blockers, decisions taken mid-implementation, deviations from the plan and why.
A deviation that changes WHAT gets built belongs in `spec.md` instead.>
