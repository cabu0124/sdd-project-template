# /sdd-clarify — close the gaps in a spec

**Goal.** Turn what a spec leaves ambiguous into decisions written into the spec.

Optional. Run it when the spec has open questions or reads as vague; skip it when
it does not. A clarification round that invents doubts is worse than none.

Argument: a spec id. If it is missing, take the most recently modified spec whose
status is `draft`.

**A mirrored spec is not clarified here.** If the spec directory holds a
`spec.link.yml`, the spec is owned by the Spec Repository: report the ambiguities
you found, and stop. They are answered there — with that repository's
`/sdd-clarify` — and the answer reaches every consumer through `/sdd-sync`.
Rewriting a requirement in the mirror fixes it for this repo and for nobody else.
See `docs/spec-repo.md`.

## Read first

- The spec, and its `wireframe.html` if it has one.
- `docs/constitution.md` and `AGENTS.md` — some ambiguities are already settled
  here, and those you resolve by reading, not by asking.
- `docs/cross-repo.md`, if present and the spec names more than one repository.
- The codebase, where it tells you which readings are even plausible.

## Ask only

One question per real ambiguity, each with the readings you see and what each one
would change. Never ask what the constitution, `AGENTS.md` or the code already
answers. Never ask about implementation — a question that only affects HOW, or
which repository does the work, is for `/sdd-plan`.

What is worth asking about:

- A requirement with two readings that lead to different acceptance criteria.
- An acceptance criterion whose result is not observable.
- A requirement with no acceptance criterion, or a criterion with no requirement.
- Scope that neither `In` nor `Out` settles.
- A contradiction between two requirements, or with the constitution.
- Anything already listed under `## Open questions`.

## Steps

1. Read the spec against the constitution and `AGENTS.md`.
2. List what you found, grouped: ambiguous, contradictory, missing, not testable.
3. If the list is empty, say so and stop.
4. Ask, in one round where possible.
5. Write the answers where they belong: a vague requirement gets rewritten, a
   settled question is struck through with its resolution and date, decided scope
   moves into `In` or `Out`. Do not append a transcript of the conversation, and
   do not let an answer bring technology or a repository name into the spec — an
   answer that only lands in `plan.md` was a `/sdd-plan` question.
6. If the spec has a wireframe, update it only where an answer changed what is on
   a screen: a field added, a control dropped, an arrangement decided. An answer
   that changes no screen leaves the file byte-identical — resist the urge to
   tidy it while you are in there.
7. Report what changed, requirement by requirement.

## Writes

The spec, and its `wireframe.html` when an answer changed a screen. Never
`plan.md`, `tasks.md` or code.

## Stops when

Every ambiguity is either resolved in the spec or still listed as an open
question for the user to settle — say which. `/sdd-plan` needs
`## Open questions` empty and `status: approved`.
