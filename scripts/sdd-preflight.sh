#!/usr/bin/env bash
#
# Run before /sdd-sync, /sdd-plan, /sdd-tasks and /sdd-implement: the Spec
# Repository and every registered consumer contain freshly fetched origin's
# integration branch, and this repository's spec pointers are current.
#
#   scripts/sdd-preflight.sh                       # every required repository
#   scripts/sdd-preflight.sh --spec 007-password-reset  # also gate that spec
#   scripts/sdd-preflight.sh --repo acme-api=/abs/path  # a clone that is not a sibling
#   scripts/sdd-preflight.sh --branch main         # a repo that integrates on main
#
# It inspects and fetches. It never merges, rebases, switches branch, stashes,
# commits or pushes: a repository that cannot be fast-forwarded is reported, not
# repaired. Updating is the user's, always.
#
# Exit 0 ready, 1 blocked. See docs/commands/preflight.md.

set -uo pipefail

if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$root"
fi

CONFIG=.sdd/config.yml
SPEC_SYNC=scripts/spec-sync.sh
POINTER=scripts/spec-pointer-check.sh

# The branch every repository integrates on — docs/delivery.md. It is not
# spec_repo.ref: that names which revision of the specs to read, and may be a
# tag, while this names where the code is integrated.
branch=develop
active_spec=""
declare -a overrides=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --spec) shift; [ "$#" -gt 0 ] || { echo "sdd-preflight: --spec needs an id" >&2; exit 2; }; active_spec=$1 ;;
    --branch) shift; [ "$#" -gt 0 ] || { echo "sdd-preflight: --branch needs a name" >&2; exit 2; }; branch=$1 ;;
    --repo)
      shift
      [ "$#" -gt 0 ] || { echo "sdd-preflight: --repo needs Name=/path" >&2; exit 2; }
      case "$1" in *=*) overrides+=("$1") ;; *) echo "sdd-preflight: --repo takes Name=/path" >&2; exit 2 ;; esac
      ;;
    --help|-h) awk 'NR > 1 && /^#/ { sub(/^#[[:space:]]?/, ""); print; next } NR > 1 { exit }' "$0"; exit 0 ;;
    *) echo "sdd-preflight: unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

blocked=0
warned=0

block() { echo "::error::$1"; blocked=1; }
warn()  { echo "::warning::$1"; warned=$((warned + 1)); }

config_field() {
  [ -f "$CONFIG" ] || return 0
  sed -n '/^spec_repo:/,/^[^[:space:]#]/p' "$CONFIG" \
    | sed -n "s/^[[:space:]][[:space:]]*$1:[[:space:]]*//p" | head -n1 \
    | sed -e 's/[[:space:]]*#.*$//' -e 's/\r$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'\$//" -e 's/[[:space:]]*$//'
}

override_for() {
  local name=$1 entry
  [ "${#overrides[@]}" -eq 0 ] && return 1
  for entry in "${overrides[@]}"; do
    [ "${entry%%=*}" = "$name" ] || continue
    printf '%s' "${entry#*=}"
    return 0
  done
  return 1
}

# One repository: fetch, then report whether its branch already contains the
# freshly fetched integration branch. An ahead feature branch is fine; behind is
# not, and neither is a branch that never joined.
check_repo() {
  local label=$1 dir=$2 current ahead behind dirty base

  if ! git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    block "$label: $dir is not a git repository. Clone it, or pass --repo $label=/path."
    return
  fi

  if ! git -C "$dir" fetch --quiet origin "$branch" 2>/dev/null; then
    block "$label: could not fetch $branch from origin. Check access and try again."
    return
  fi

  base=$(git -C "$dir" rev-parse --verify --quiet "refs/remotes/origin/$branch") || {
    block "$label: origin/$branch does not exist after fetching."
    return
  }

  current=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  dirty=""
  [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ] && dirty=" (uncommitted changes)"

  behind=$(git -C "$dir" rev-list --count "HEAD..$base" 2>/dev/null || echo 0)
  ahead=$(git -C "$dir" rev-list --count "$base..HEAD" 2>/dev/null || echo 0)

  if [ "$behind" -ne 0 ]; then
    block "$label: $current is $behind commit(s) behind origin/$branch$dirty. Update it yourself — preflight never merges."
    return
  fi

  if [ "$current" = "$branch" ]; then
    echo "ok: $label on $branch, up to date${dirty}"
  else
    echo "ok: $label on $current, $ahead commit(s) ahead of $branch${dirty}"
  fi
}

echo "==> Repositories"

# This repository first: a preflight that passes while the repo it runs in is
# behind is a preflight that certified nothing.
check_repo "$(basename "$PWD")" .

spec_repo_none=0
if [ ! -f "$CONFIG" ]; then
  warn "no $CONFIG, so no Spec Repository is configured. Only this repository was checked."
  spec_repo_none=1
elif grep -qE '^spec_repo:[[:space:]]*none[[:space:]]*(#.*)?$' "$CONFIG"; then
  echo "note: spec_repo is none — this repository writes its own specs, so there is nothing upstream to check."
  spec_repo_none=1
fi

if [ "$spec_repo_none" -eq 0 ]; then
  spec_name=$(config_field name)
  spec_path=$(config_field path)
  spec_ref=$(config_field ref)
  case "$spec_path" in ''|*'<'*) spec_path="" ;; esac

  # The Spec Repository is read at spec_repo.ref, which may be a tag and may not
  # be the integration branch, so it is resolved rather than branch-checked.
  spec_commit=$(bash "$SPEC_SYNC" --resolve 2>/dev/null)
  resolve_status=$?

  if [ "$resolve_status" -eq 2 ]; then
    # spec-sync reserves 2 for "nothing configured yet" — an unfilled template is
    # not a repository in trouble.
    warn "$CONFIG is not filled in yet, so nothing upstream was checked. /sdd-init fills it."
    spec_repo_none=1
  elif [ "$resolve_status" -ne 0 ]; then
    block "$spec_name: could not resolve $spec_ref. Run scripts/spec-sync.sh --list to see why."
  else
    echo "ok: $spec_name resolved $spec_ref at $spec_commit"

    # A local clone is a cache, not the authority, but a stale one is what the
    # user reads with --offline, so it is worth reporting.
    if [ -n "$spec_path" ] && git -C "$spec_path" rev-parse --git-dir >/dev/null 2>&1; then
      if [ -n "$(git -C "$spec_path" status --porcelain 2>/dev/null)" ]; then
        warn "$spec_name: the clone at $spec_path has uncommitted changes. They are never what a sync reads."
      fi
    fi

    echo
    echo "==> Consumers"

    registry=""
    if registry=$(bash "$SPEC_SYNC" --show docs/consumers.md 2>/dev/null); then
      names=$(printf '%s\n' "$registry" \
        | sed -n '/sdd:consumers:start/,/sdd:consumers:end/p' \
        | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([A-Za-z0-9][A-Za-z0-9_-]*\)".*/\1/p')

      if [ -z "$names" ]; then
        warn "docs/consumers.md carries no delimited consumers block, so no sibling repository was checked."
      else
        while read -r name; do
          [ -n "$name" ] || continue
          [ "$name" = "$(basename "$PWD")" ] && continue
          if dir=$(override_for "$name"); then
            :
          elif [ -n "$spec_path" ]; then
            dir="$(dirname "$spec_path")/$name"
          else
            dir="../$name"
          fi
          check_repo "$name" "$dir"
        done <<<"$names"
      fi
    else
      warn "$spec_name publishes no docs/consumers.md, so only this repository was checked. Publish one to gate the siblings too."
    fi
  fi
fi

echo
echo "==> Spec pointers"

bash "$POINTER" || blocked=1

if [ "$spec_repo_none" -eq 0 ] && [ "$blocked" -eq 0 ]; then
  shopt -s nullglob
  for link in specs/*/spec.link.yml; do
    dir=$(dirname "$link")
    local_id=$(basename "$dir")
    source_id=$(bash "$POINTER" --source-id "$link" 2>/dev/null)
    [ -n "$source_id" ] || continue

    # spec-sync answers this precisely: 0 already in sync, 3 upstream moved,
    # 1 a spec was copied in or the id is gone. Asking it is what keeps one
    # implementation of "is this current".
    bash "$SPEC_SYNC" "$source_id" >/dev/null 2>&1
    case "$?" in
      0) echo "ok: $local_id is at the revision it records" ;;
      3)
        if [ -n "$active_spec" ] && { [ "$active_spec" = "$local_id" ] || [ "$active_spec" = "$source_id" ]; }; then
          block "$local_id: the spec moved upstream since it was last reviewed here. Run /sdd-sync $source_id and review what it invalidates before continuing."
        else
          warn "$local_id: the spec moved upstream since it was last reviewed here. Not blocking — it is not the spec being worked on."
        fi
        ;;
      *) block "$local_id: scripts/spec-sync.sh $source_id could not confirm it. Run it to see why." ;;
    esac
  done
fi

echo
if [ "$blocked" -ne 0 ]; then
  echo "BLOCKED. Nothing was changed; fix what is reported above and run it again."
  exit 1
fi

printf 'READY for this invocation. %d warning(s).\n' "$warned"
