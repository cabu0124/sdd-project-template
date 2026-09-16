#!/usr/bin/env bash
#
# The one place a spec pointer is validated.
#
# A spec from a Spec Repository is not copied into this repository: specs/<id>/
# holds a spec.link.yml naming it, and the spec itself is read from the Spec
# Repository at the configured ref. There is no local copy, so there is nothing
# to hash and nothing that can disagree with the source — what this checks is
# that the pointer says which spec, and that nobody put a copy back.
#
#   scripts/spec-pointer-check.sh                        # every pointer
#   scripts/spec-pointer-check.sh specs/007-password-reset  # one
#   scripts/spec-pointer-check.sh --source-id <spec.link.yml>  # the id it names
#
# The last form exists so scripts/spec-sync.sh reads the provenance the same
# way this does, rather than parsing it a second time.
#
# It reads nothing outside this repository and needs no credentials.
#
# `spec_repo: none` means this repository writes its own specs with
# /sdd-specify. Then there are no pointers, every spec is local and legitimate,
# and scripts/spec-check.sh is what validates them.
#
# See docs/spec-repo.md.

set -euo pipefail

if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$root"
fi

CONFIG=.sdd/config.yml

# "spec_repo: none" collapses the whole block to one line; anything else, or no
# file at all, means specs come from somewhere else and are never written here.
spec_repo_configured() {
  [ -f "$CONFIG" ] || return 1
  grep -qE '^spec_repo:[[:space:]]*none[[:space:]]*(#.*)?$' "$CONFIG" && return 1
  return 0
}

# A value from the `spec_repo:` block of .sdd/config.yml, by key.
config_field() {
  [ -f "$CONFIG" ] || return 0
  sed -n '/^spec_repo:/,/^[^[:space:]#]/p' "$CONFIG" \
    | sed -n "s/^[[:space:]][[:space:]]*$1:[[:space:]]*//p" \
    | head -n1 \
    | sed -e 's/[[:space:]]*#.*$//' -e 's/\r$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'\$//" -e 's/[[:space:]]*$//'
}

# A value from a block of a spec.link.yml, by key. Tolerant on the way in: a CR,
# a quote or a trailing comment is the editor that saved the file, not the
# provenance it records.
block_field() {
  sed -n "/^$2:/,/^[^[:space:]#]/p" "$1" \
    | sed -n "s/^[[:space:]][[:space:]]*$3:[[:space:]]*//p" \
    | head -n1 \
    | sed -e 's/[[:space:]]*#.*$//' -e 's/\r$//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'\$//" -e 's/[[:space:]]*$//'
}

source_field() { block_field "$1" source "$2"; }

# The files a sync used to copy. Nothing copies them now, so this is the list of
# names that must NOT be sitting next to a pointer.
COPIED_NAMES="spec.md wireframe.html"

checked=0
failed=0

check_one() {
  local link=$1 dir id local_id path ref commit name
  dir=$(dirname "$link")
  checked=$((checked + 1))

  # The spec is read from the Spec Repository. A copy here is a second WHAT: it
  # can be edited, and then this repository quietly has its own version of what
  # everyone agreed, with nothing upstream to contradict it.
  for name in $COPIED_NAMES; do
    [ -e "$dir/$name" ] || continue
    echo "::error file=$dir/$name::the spec is read from the Spec Repository, never copied here. Delete it and keep spec.link.yml — /sdd-sync writes the pointer."
    failed=1
  done

  id=$(source_field "$link" id)
  path=$(source_field "$link" path)
  ref=$(source_field "$link" ref)
  commit=$(source_field "$link" commit)
  local_id=$(block_field "$link" synced local_id)

  if [ -z "$id" ] || printf '%s' "$id" | grep -q '<'; then
    echo "::error file=$link::source.id is missing or still the template's placeholder, so this pointer names no spec upstream. Re-run /sdd-sync."
    failed=1
  fi

  # The local number is this repository's own — the template does not require it
  # to match the id upstream — but it does have to be the directory it is in, or
  # the pointer describes a spec that lives somewhere else.
  if [ -n "$local_id" ] && [ "$local_id" != "$(basename "$dir")" ]; then
    echo "::error file=$link::synced.local_id is '$local_id' but this is $dir. The local id is the directory name. Re-run /sdd-sync."
    failed=1
  fi

  local configured_specs_dir
  configured_specs_dir=$(config_field specs_dir)
  if [ -n "$configured_specs_dir" ] && [ -n "$id" ] && [ "$path" != "$configured_specs_dir/$id" ]; then
    echo "::error file=$link::source.path is '${path:-(empty)}'; expected $configured_specs_dir/$id."
    failed=1
  fi

  # Everyone has to read one ref, or two repositories implement two specs.
  local configured_ref
  configured_ref=$(config_field ref)
  case "$configured_ref" in ''|*'<'*) configured_ref="" ;; esac
  if [ -n "$configured_ref" ] && [ "$ref" != "$configured_ref" ]; then
    echo "::error file=$link::source.ref is '${ref:-(empty)}', but $CONFIG reads $configured_ref. Re-run /sdd-sync."
    failed=1
  fi

  # The revision last reviewed here. The spec is read at the tip of ref, so this
  # is not what gets read — it is what /sdd-sync compares against to tell you
  # that a requirement moved since the plan was written.
  if ! printf '%s' "$commit" | grep -qE '^([0-9a-f]{40}|[0-9a-f]{64})$'; then
    echo "::error file=$link::source.commit is '${commit:-(empty)}' — it must be the full sha this spec was last reviewed at. Re-run /sdd-sync."
    failed=1
  fi
}

check() {
  # nullglob: this template ships with no specs at all, and a repository whose
  # spec_repo is `none` never has a spec.link.yml. Both must pass.
  shopt -s nullglob

  # No argument means every pointer. The glob may expand to nothing; "$@" is the
  # one expansion that stays safe under `set -u` when it does.
  if [ "$#" -eq 0 ]; then
    set -- specs/*/spec.link.yml
  fi

  local link
  for link in "$@"; do
    # Accept a spec directory as well as the link file itself.
    [ -d "$link" ] && link="${link%/}/spec.link.yml"
    [ -f "$link" ] || continue
    check_one "$link"
  done

  # A spec directory with no pointer is a spec this repository wrote itself.
  # That is the whole arrangement when spec_repo is none, and a contradiction
  # when a Spec Repository owns the specs.
  if spec_repo_configured; then
    local dir
    for dir in specs/*/; do
      [ -f "${dir%/}/spec.link.yml" ] && continue
      echo "::error file=${dir%/}::this spec directory has no spec.link.yml, so nothing says which spec it implements. Run /sdd-sync, or remove it if it does not belong."
      failed=1
    done
  fi

  if [ "$failed" -ne 0 ]; then
    echo "A spec pointer is wrong, or a spec was copied into this repository. docs/spec-repo.md says what to do."
    exit 1
  fi

  if [ "$checked" -eq 0 ]; then
    echo "No spec pointers to check."
  else
    echo "$checked spec pointer(s) are well formed, with no copied spec content."
  fi
}

case "${1:-}" in
  --source-id) shift; source_field "${1:?spec-pointer-check: --source-id needs a spec.link.yml}" id ;;
  --help|-h) awk 'NR > 1 && /^#/ { sub(/^#[[:space:]]?/, ""); print; next } NR > 1 { exit }' "$0" ;;
  -*) echo "spec-pointer-check: unknown option: $1" >&2; exit 2 ;;
  *) check "$@" ;;
esac
