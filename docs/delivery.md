# Delivery — branches, flags, releases

How work gets from a checked-off task to a user. Read it before opening a
branch, before putting anything behind a flag, and before cutting a release.

The whole model is one line:

```text
feature/* ──▶ develop ──▶ main ──▶ deploy ──▶ turn the flag on
```

## Branches

| Branch | Lives | Holds |
| --- | --- | --- |
| `main` | forever | what is in production |
| `develop` | forever | everything integrated, waiting to be promoted |
| `feature/<NNN>-<slug>` | days | one spec's work |
| `fix/<NNN>-<slug>` | hours | a defect, from `develop` |
| `hotfix/<slug>` | hours | a production defect, from `main` |

- **A branch opens from the branch it merges back into.** `feature/*` and
  `fix/*` from `develop`, `hotfix/*` from `main`.
- **`main` only ever receives `develop` or a `hotfix/*`.** Anything else is a
  commit that reached production without being tested next to the rest.
- **The spec number is the branch name.** `feature/007-password-reset` ties the
  branch, the pull request, the commits and `docs/specs/007-password-reset/`
  together without a tracker in between.
- **Temporary means temporary.** `feature/*`, `fix/*` and `hotfix/*` are deleted
  on merge — by hand, from the pull request. A branch alive for a month is a
  merge conflict with interest.

> [!WARNING]
> Do not turn on "Automatically delete head branches". The promotion pull
> request's head branch is `develop`, so the setting deletes a permanent branch
> the first time you promote — and someone then recreates it from a stale clone,
> silently rewinding it.

There are no `release/*` branches — see `## Deliberately absent`.

## Merges

Two merges, two strategies, and the difference is load-bearing:

| Merge | Strategy | What lands |
| --- | --- | --- |
| `feature/*` `fix/*` → `develop` | **Squash** | one commit, subject = the validated pull request title |
| `hotfix/*` → `main` | **Squash** | one commit, same |
| `develop` → `main` | **Merge commit** | every squashed commit, subjects intact |

**Squashing the promotion would erase the release.** The release job reads the
individual subjects on `main` to work out the bump; collapse a promotion of nine
commits into one `chore: promote develop` and it computes *nothing to release*.
The merge commit itself is skipped (`--no-merges`), so what the job sees is
exactly the list of `feat:` and `fix:` titles reviewers approved.

That is also why rebase merging is off: it rewrites the hashes `develop` and
`main` share, and the next promotion sees the same work twice.

## Hotfix

The only propagation rule in the whole model, and it is not optional: branch
from `main`, pull request into `main`, then merge `main` back into `develop` the
same day. A hotfix that never returns to `develop` is a bug that ships again on
the next promotion.

## Feature flags

Work too big for one merge does not get a long-lived branch. It reaches `main`
**off**: merged, deployed, dark. A branch that lives until the feature is
finished is a merge conflict growing in the dark — a flag is the same delay with
the code already integrated.

| Change | Flag? |
| --- | --- |
| A feature that needs several merges before it is usable | Yes |
| A change to behaviour users already rely on | Yes |
| Anything you would not switch on for everyone at once | Yes |
| A bug fix | No |
| A refactor with no behaviour change | No |
| Anything that lands finished in one merge | No |

A flag on a two-line fix costs more than it protects.

### The pattern

This template does not pick a provider. A vendor SDK, a config table, a database
row or an environment variable are all valid, and the choice is a `plan.md`
decision like any other. What does not change:

1. **One reader.** The flag is read in exactly one place, behind the project's
   own accessor. A flag read from nine call sites cannot be removed in one task.
2. **Off is the default.** Unknown flag, unreachable provider, missing config —
   all evaluate to off. *Why:* an outage must not ship a half-built feature.
3. **The name is the spec id.** `007-password-reset` — the same slug as the
   branch and the spec directory. A flag nobody can trace to a spec is a flag
   nobody dares delete.
4. **The old path keeps working until the flag dies.** Both sides of the branch
   ship on every deploy; that is what makes turning it off a switch rather than
   a rollback.
5. **Acceptance criteria are verified with the flag on.** The flag decides who
   sees the feature, not what the spec promised.

### Flags that do not become debt

- **`plan.md` names the flag and the condition that removes it** — `## Rollout`.
  A flag with no removal condition is permanent.
- **`tasks.md` carries the removal as a real task**, exactly like a mock written
  against a contract, and it is the last task of the spec: the flag, its reads
  and the old path, gone in one commit.
- **One flag per spec.** Two flags are four behaviours to test, and nobody tests
  four.
- **A flag that is on for everyone is finished, not done.** Remove it in the
  release after it goes fully on.

> [!WARNING]
> A flag left behind after the feature shipped is dead code every future change
> has to keep working, and by then nobody remembers which branch of the `if` is
> the live one.

## Commits

Conventional Commits, enforced on the **pull request title** — the squash merge
turns that title into the commit, so the title *is* the history.
`.github/workflows/pr-title.yml` rejects anything else.

```text
<type>(<scope>)!: <subject>
```

| Type | Releases | For |
| --- | --- | --- |
| `feat` | MINOR | new user-visible behaviour |
| `fix` | PATCH | a defect |
| `perf` | PATCH | faster, same behaviour |
| `docs` `test` `refactor` `chore` `ci` `build` `style` `revert` | nothing | everything else |

A `!` before the colon, or a `BREAKING CHANGE:` footer, is **MAJOR** whatever the
type says. Scope is optional, and when the work belongs to a spec it is the spec
number: `feat(007): send the reset email`.

## Versioning

Semantic Versioning, tags `vX.Y.Z`, on `main` only.

| Bump | When, since the last tag |
| --- | --- |
| MAJOR | any breaking change |
| MINOR | at least one `feat` |
| PATCH | at least one `fix` or `perf`, and no `feat` |
| none | only `docs`, `test`, `refactor`, `chore`, `ci` |

The version is derived from the commits — never typed by a person, never stored
in a file that has to be kept in step. Nothing to forget and nothing to conflict
on. A manifest that must carry it (`package.json`, `pyproject.toml`) is written
from the tag by the release job, never edited in a pull request.

## Releases

Only from `main`, only by `.github/workflows/release.yml`, on every push:

1. Find the last `v*` tag.
2. Read the commit subjects since it, and work out the bump.
3. Nothing to release → stop. Most pushes stop here, and that is correct.
4. Create the tag `vX.Y.Z`.
5. Create the GitHub Release, notes generated from those subjects.
6. Try to prepend those notes to `CHANGELOG.md` on `main` — best effort, and a
   protected branch refusing it changes nothing about steps 4 and 5.

**`develop` never releases.** A tag on a branch nobody deployed is a version
number pointing at code nobody is running.

The CHANGELOG commit is the only write the pipeline attempts on `main`. It
carries `[skip ci]` and is made with the workflow token, which does not trigger
workflows — so it cannot loop. Whether it lands depends on the branch
protection; see `## Repository settings`.

## Repository settings

The workflows assume these. They are settings, not files, so no checkout
enforces them:

| Setting | Why |
| --- | --- |
| Squash and merge commits both enabled; rebase disabled | the two merges do different jobs — see `## Merges` |
| "Default to pull request title for squash merge commits" | otherwise the validated title is not the one that lands |
| `main` and `develop` protected, pull request required | a direct push bypasses every check above |
| `conventional-commit` and `spec-mirror` required as status checks | a check that can be skipped is documentation |
| "Automatically delete head branches" **off** | the promotion's head branch is `develop`, and the setting would delete it |
| `main` and `develop` restricted against deletion | the second guard on the same mistake |

The required checks are named after the **job**, not the workflow or the file:
`conventional-commit` in `.github/workflows/pr-title.yml`, `spec-mirror` in
`.github/workflows/spec-mirror.yml`. Requiring a
name nothing reports leaves every pull request stuck on *Expected — waiting for
status to be reported*, forever and silently.

Workflow permissions can stay on the read-only default: `release.yml` declares
the `contents: write` it needs, which is narrower than granting it repo-wide.

**A protected `main` rejects the CHANGELOG commit, and that is expected.**
`github-actions[bot]` cannot be added to a ruleset bypass list — the list takes
roles, teams, GitHub Apps and Dependabot, and the Actions bot is none of them.
The step logs a warning and the release stands: tag and notes are already
published. Two ways out, in the order worth trying:

| Want | Do |
| --- | --- |
| Nothing — the Release is the changelog | leave it; the warning is the record |
| `CHANGELOG.md` in the repo | push from a `fix(docs):` pull request like any other change |
| It automated anyway | mint a token from a GitHub App that *is* in the bypass list, and use it in `actions/checkout` — a secret to rotate, for a file the Release already contains |

## Deliberately absent

| Not here | Why |
| --- | --- |
| `release/x.y.z` branches | a release branch is a second `main` you have to keep in step with the first |
| Forward-porting, cherry-pick trains | they exist to serve release branches, and there are none |
| Supporting several versions at once | one version is in production: the one on `main` |
| A release pull request (`release-please`, `semantic-release`) | it opens a long-lived branch to hold the pending release — a release branch under another name |
| A named flag provider | it is a `plan.md` decision, and the pattern above holds for any of them |
| Environments beyond production | add one when a deploy target exists; the flow does not change |
