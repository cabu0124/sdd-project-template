#!/usr/bin/env bash
#
# The mechanical half of /sdd-sync: resolve the Spec Repository to one commit
# and record which spec this repository implements. It never copies the spec.
#
#   scripts/spec-sync.sh --list                  # the spec ids available upstream
#   scripts/spec-sync.sh <id>                    # preview a new sync or re-sync
#   scripts/spec-sync.sh --write <commit> <id>  # apply exactly what was previewed
#   scripts/spec-sync.sh --offline <id>          # use the last remote ref cached at path
#   scripts/spec-sync.sh --resolve               # the commit ref points at, alone
#   scripts/spec-sync.sh --show <path>           # a file from the source at that commit
#
# --resolve and --show exist so scripts/sdd-preflight.sh reads the Spec
# Repository through this one resolution rather than repeating it.
#
# Everything here is the same every time: resolving a ref, reading a blob,
# writing a pointer. What is left to /sdd-sync is the part that needs judgement
# — reading the spec, and saying whether a changed requirement invalidates the
# plan and the tasks built on it.
#
# The spec stays in the Spec Repository and is read from there at `ref`. What is
# written here is specs/<NNN-slug>/spec.link.yml, whose `source.commit` records
# the revision last reviewed — which is what makes "a requirement moved since
# you planned" a reviewable diff rather than a silent change.
#
# It never writes plan.md, tasks.md, code, or any spec content. A matching
# path cache may receive fetched Git objects and refs. See docs/spec-repo.md.

set -euo pipefail

here=$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$root"
fi

. "$here/sdd-lib.sh" || { echo "spec-sync: scripts/sdd-lib.sh is missing" >&2; exit 1; }

SPEC_POINTER=scripts/spec-pointer-check.sh
CONFIG=.sdd/config.yml

die() { echo "spec-sync: $1" >&2; exit "${2:-1}"; }

# A value from the `spec_repo:` block of .sdd/config.yml, by key.
config_field() {
  sed -n '/^spec_repo:/,/^[^[:space:]#]/p' "$CONFIG" \
    | sed -n "s/^[[:space:]][[:space:]]*$1:[[:space:]]*//p" \
    | head -n1 \
    | sed -e 's/[[:space:]]*#.*$//' -e 's/\r$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'\$//" -e 's/[[:space:]]*$//'
}

write=0
offline=0
mode=sync
id=""
requested_commit=""
show_path=""

# A spec diff is the one thing here worth reading closely, but not at any
# length: past the head and tail the rest stays one recall away.
show_patch() {
  if sdd_verbose; then
    cat "$1"
    return
  fi
  sdd_truncate_lines 40 10 < "$1"
  if [ "$(wc -l < "$1")" -gt 50 ]; then
    printf '[full output: scripts/sdd-recall.sh %s]\n' "$(bash "$here/sdd-recall.sh" --save < "$1")"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --write|-w)
      write=1
      shift
      [ "$#" -gt 0 ] || die "--write needs the commit shown by the preview" 2
      requested_commit=$1
      ;;
    --offline) offline=1 ;;
    --verbose|-v) SDD_VERBOSE=1 ;;
    --list|-l) mode=list ;;
    --resolve) mode=resolve ;;
    --show)
      mode=show
      shift
      [ "$#" -gt 0 ] || die "--show needs a path inside the Spec Repository" 2
      show_path=$1
      ;;
    --help|-h) awk 'NR > 1 && /^#/ { sub(/^#[[:space:]]?/, ""); print; next } NR > 1 { exit }' "$0"; exit 0 ;;
    -*) die "unknown option: $1" 2 ;;
    *) id=$1 ;;
  esac
  shift
done

if [ "$write" -eq 1 ] && ! printf '%s' "$requested_commit" | grep -qE '^([0-9a-f]{40}|[0-9a-f]{64})$'; then
  die "--write commit must be a full 40- or 64-character sha" 2
fi

[ -f "$CONFIG" ] || die "$CONFIG not found — /sdd-init writes it" 2
grep -qE '^spec_repo:[[:space:]]*none[[:space:]]*(#.*)?$' "$CONFIG" \
  && die "spec_repo is none: this repository writes its own specs with /sdd-specify" 2

name=$(config_field name)
path=$(config_field path)
remote=$(config_field remote)
ref=$(config_field ref)
specs_dir=$(config_field specs_dir)

for pair in "ref:$ref" "specs_dir:$specs_dir"; do
  case "${pair#*:}" in
    ''|*'<'*) die "${pair%%:*} in $CONFIG is empty or still a <placeholder> — /sdd-init fills it" 2 ;;
  esac
done

# With both configured, `remote` is the authority and `path` is only a cache
# when its origin URL matches exactly. With no remote, path is a local authority.
src=""
tmp=""
kind=""
source_kind=""

# Returns 0 whatever it finds: under set -e a failing cleanup would replace the
# script's own exit status, so a correct run would report as a failure.
cleanup() {
  [ -n "$tmp" ] && rm -rf "$tmp"
  return 0
}
trap cleanup EXIT

case "$path" in ''|*'<'*) path="" ;; esac
case "$remote" in ''|*'<'*) remote="" ;; esac

# Neither filled in is the unfilled template, which is exit 2 by this script's
# contract — not a Spec Repository that failed to resolve.
if [ -z "$path" ] && [ -z "$remote" ]; then
  die "neither path nor remote is filled in $CONFIG — /sdd-init fills them" 2
fi

path_valid=0
if [ -n "$path" ] && git -C "$path" rev-parse --git-dir >/dev/null 2>&1; then
  path_valid=1
fi

if [ -n "$remote" ] && [ "$path_valid" -eq 1 ]; then
  path_remote=$(git -C "$path" remote get-url origin 2>/dev/null || true)
  if [ "$path_remote" = "$remote" ]; then
    src=$path
    kind=cache
    source_kind="path cache $path for remote $remote"
  else
    echo "note: ignoring path $path because its origin '$path_remote' does not match remote '$remote'." >&2
  fi
fi

if [ -z "$src" ] && [ -n "$remote" ]; then
  [ "$offline" -eq 0 ] || die "--offline needs path to be a git repository whose origin matches remote"
  tmp=$(mktemp -d)
  git -C "$tmp" init --quiet spec-repo
  src="$tmp/spec-repo"
  git -C "$src" remote add origin "$remote"
  kind=remote
  source_kind="remote $remote"
elif [ -z "$src" ] && [ "$path_valid" -eq 1 ]; then
  src=$path
  kind=local
  source_kind="local-only path $path"
elif [ -z "$src" ]; then
  die "neither path nor remote resolves to a git repository — check $CONFIG"
fi

# One commit, resolved once. Apply resolves the reviewed commit itself rather
# than the branch or tag again, so a moving ref cannot change what gets written.
target=${requested_commit:-$ref}
if [ "$kind" = remote ]; then
  git -C "$src" fetch --quiet --depth 1 origin "$target" 2>/dev/null \
    || die "could not fetch $target from $remote"
  commit=$(git -C "$src" rev-parse --verify FETCH_HEAD^{commit})
elif [ "$kind" = cache ] && [ "$offline" -eq 0 ]; then
  git -C "$src" fetch --quiet origin "$target" 2>/dev/null \
    || die "could not refresh $target from $remote; use --offline only to accept the last cached remote ref"
  commit=$(git -C "$src" rev-parse --verify FETCH_HEAD^{commit})
elif [ "$kind" = cache ]; then
  offline_target=$target
  if git -C "$src" show-ref --verify --quiet "refs/remotes/origin/$target"; then
    offline_target="refs/remotes/origin/$target"
  elif git -C "$src" show-ref --verify --quiet "refs/tags/$target"; then
    offline_target="refs/tags/$target"
  fi
  commit=$(git -C "$src" rev-parse --verify "$offline_target^{commit}" 2>/dev/null) \
    || die "$target is not cached in $path"
  echo "note: offline mode; freshness against $remote was not verified." >&2
else
  commit=$(git -C "$src" rev-parse --verify "$target^{commit}" 2>/dev/null) \
    || die "$target does not resolve in $path"
fi

if [ -n "$requested_commit" ] && [ "$commit" != "$requested_commit" ]; then
  die "reviewed commit $requested_commit resolved as $commit; nothing written"
fi

available() { git -C "$src" ls-tree --name-only "$commit:$specs_dir" 2>/dev/null | sed 's#/$##'; }

if [ "$mode" = list ]; then
  echo "$name at $ref ($commit), read from $source_kind:"
  available
  exit 0
fi

if [ "$mode" = resolve ]; then
  echo "$commit"
  exit 0
fi

if [ "$mode" = show ]; then
  git -C "$src" cat-file -e "$commit:$show_path" 2>/dev/null \
    || die "$show_path is not at $commit in $name" 1
  git -C "$src" show "$commit:$show_path"
  exit 0
fi

[ -n "$id" ] || die "which spec? Pass an id, or --list to see them" 2

git -C "$src" cat-file -e "$commit:$specs_dir/$id/spec.md" 2>/dev/null || {
  echo "spec-sync: $specs_dir/$id/spec.md is not at $commit. Available:" >&2
  available >&2
  exit 1
}

# Re-sync keeps the directory the spec already has here; the local number never
# changes once a plan, a branch and commits refer to it.
dir=""
shopt -s nullglob
for link in specs/*/spec.link.yml; do
  [ "$(bash "$SPEC_POINTER" --source-id "$link" 2>/dev/null)" = "$id" ] || continue
  dir=$(dirname "$link")
  break
done

if [ -z "$dir" ]; then
  max=0
  for existing in specs/*/; do
    n=$(basename "$existing" | sed -n 's/^\([0-9][0-9]*\)-.*/\1/p')
    [ -n "$n" ] || continue
    n=$((10#$n))
    [ "$n" -gt "$max" ] && max=$n
  done
  slug=$(printf '%s' "$id" | sed 's/^[0-9][0-9]*-//')
  dir=$(printf 'specs/%03d-%s' $((max + 1)) "$slug")
  fresh=1
else
  fresh=0
fi

# The provenance recorded here, if this spec is already registered.
recorded_field() {
  sed -n '/^source:/,/^[^[:space:]#]/p' "$dir/spec.link.yml" \
    | sed -n "s/^[[:space:]][[:space:]]*$1:[[:space:]]*//p" | head -n1 \
    | sed -e 's/[[:space:]]*#.*$//' -e 's/\r$//' -e 's/[[:space:]]*$//'
}

# Every file the spec has upstream at one commit.
files_at() { git -C "$src" ls-tree --name-only "$1:$specs_dir/$id" 2>/dev/null; }

echo "spec:   $id at $commit"
echo "source: $source_kind"
echo "local:  $dir"

changed=0
recorded_commit=""

if [ "$fresh" -eq 0 ]; then
  # A spec copied in beside the pointer is not a re-sync question: it is a
  # repository that gave itself its own version of what everyone agreed.
  bash "$SPEC_POINTER" "$dir" >/dev/null || {
    echo "spec-sync: $dir does not hold a valid pointer. Nothing written." >&2
    bash "$SPEC_POINTER" "$dir" >&2 || true
    exit 1
  }

  recorded_commit=$(recorded_field commit)

  if [ "$recorded_commit" = "$commit" ]; then
    echo "Already in sync."
    exit 0
  fi

  # Both revisions are read from git: nothing was copied here, so there is no
  # local file to compare and no way for this repository to have edited either.
  if ! git -C "$src" cat-file -e "$recorded_commit^{commit}" 2>/dev/null; then
    echo
    echo "The revision last reviewed here ($recorded_commit) is not available from"
    echo "$source_kind, so the change cannot be shown. Read the spec upstream before applying."
    changed=1
  else
    while read -r file; do
      [ -n "$file" ] || continue
      if ! git -C "$src" cat-file -e "$recorded_commit:$specs_dir/$id/$file" 2>/dev/null; then
        echo "new upstream: $file"
        changed=1
        continue
      fi
      if ! git -C "$src" cat-file -e "$commit:$specs_dir/$id/$file" 2>/dev/null; then
        echo "gone upstream: $file"
        changed=1
        continue
      fi
      patch=$(mktemp)
      diff -u \
        <(git -C "$src" show "$recorded_commit:$specs_dir/$id/$file") \
        <(git -C "$src" show "$commit:$specs_dir/$id/$file") \
        --label "a/$file ($recorded_commit)" --label "b/$file ($commit)" > "$patch" \
        && { rm -f "$patch"; continue; }
      show_patch "$patch"
      rm -f "$patch"
      changed=1
    done < <({ files_at "$recorded_commit"; files_at "$commit"; } | sort -u)
  fi
fi

if [ "$write" -eq 0 ]; then
  echo
  if [ "$fresh" -eq 1 ]; then
    echo "Nothing written. Read the source spec first, then register this exact revision:"
  elif [ "$changed" -eq 0 ]; then
    echo "Only the source revision changed; the spec itself is byte-identical."
    echo "No re-planning is required. Apply the provenance update with:"
  else
    echo "Nothing written. A changed requirement or acceptance criterion invalidates"
    echo "plan.md and tasks.md. Review the diff, then apply this exact revision:"
  fi
  echo "scripts/spec-sync.sh --write $commit $id"
  exit 3
fi

status=$(git -C "$src" show "$commit:$specs_dir/$id/spec.md" \
  | sed -n 's/^- \*\*Status:\*\*[[:space:]]*//p' | head -n1 \
  | sed -e 's/<!--.*-->//' -e 's/[[:space:]]*$//')

mkdir -p "$dir"
{
  printf '# Which spec this directory implements. Written by scripts/spec-sync.sh — do not edit by hand.\n'
  printf '#\n'
  printf '# The spec is not copied here: it is read from the Spec Repository at ref.\n'
  printf '# source.commit is the revision last reviewed, which is what /sdd-sync diffs\n'
  printf '# against to report that a requirement moved since the plan was written.\n\n'
  printf 'spec_repo: %s\n\n' "${name:-unknown}"
  printf 'source:\n'
  printf '  id: %s\n' "$id"
  printf '  path: %s/%s\n' "$specs_dir" "$id"
  printf '  ref: %s\n' "$ref"
  printf '  commit: %s\n' "$commit"
  printf '  status: %s\n\n' "${status:-unknown}"
  printf 'synced:\n'
  printf '  at: %s\n' "$(date +%Y-%m-%d)"
  printf '  local_id: %s\n' "$(basename "$dir")"
} > "$dir/spec.link.yml"

bash "$SPEC_POINTER" "$dir"

echo "status upstream: ${status:-unknown}"
echo "plan.md and tasks.md were not touched. /sdd-plan $(basename "$dir") is next."
