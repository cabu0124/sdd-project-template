#!/usr/bin/env bash
#
# The one place a mirrored spec is hashed.
#
# /sdd-sync writes the hashes, /sdd-analyze and the spec-mirror job read them
# back. When each of those computes the digest its own way — a different tool,
# a different case, a different line ending — two people syncing the same spec
# record two different hashes for the same bytes, and the mirror check fails on
# a file nobody edited. So they all call this script instead.
#
#   scripts/spec-hash.sh docs/specs/007-password-reset   # the files: block to record
#   scripts/spec-hash.sh --check                         # verify every mirror
#   scripts/spec-hash.sh --check docs/specs/007-...      # verify one
#
# See docs/spec-repo.md.

set -euo pipefail

# Run from the repository root whatever the caller's directory is, so the paths
# printed here are the paths written in spec.link.yml.
if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$root"
fi

# sha256sum is GNU, shasum is what macOS ships, openssl is the fallback.
# All three print lowercase hex; the digest is the same, only the wrapper differs.
if command -v sha256sum >/dev/null 2>&1; then
  sha256_stdin() { sha256sum | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
  sha256_stdin() { shasum -a 256 | cut -d' ' -f1; }
elif command -v openssl >/dev/null 2>&1; then
  sha256_stdin() { openssl dgst -sha256 | awk '{ print $NF }'; }
else
  echo "spec-hash: no sha256 tool found (sha256sum, shasum or openssl)" >&2
  exit 2
fi

sha256_of() { sha256_stdin < "$1"; }

# Hash of the file with CR stripped. Only used to tell "someone edited this"
# apart from "this was committed with Windows line endings", which are the same
# mismatch to sha256 and very different problems to the person reading the log.
sha256_lf_of() { tr -d '\r' < "$1" | sha256_stdin; }

# The files copied by /sdd-sync, from .sdd/config.yml. Both the block form and
# the inline `mirror: [spec.md, wireframe.html]` form appear in the docs; when
# neither is there to read, the template's own two files are the answer.
mirror_files() {
  local names=""

  if [ -f .sdd/config.yml ]; then
    names=$(awk '
      { sub(/\r$/, "") }

      /^[[:space:]]*mirror:[[:space:]]*\[/ {
        line = $0
        sub(/^[^[]*\[/, "", line)
        sub(/\].*$/, "", line)
        n = split(line, item, /,/)
        for (i = 1; i <= n; i++) {
          gsub(/[^A-Za-z0-9._-]/, "", item[i])
          if (item[i] != "") print item[i]
        }
        exit
      }

      /^[[:space:]]*mirror:[[:space:]]*(#.*)?$/ { in_list = 1; next }

      in_list && /^[[:space:]]*-[[:space:]]*[^[:space:]#]/ {
        name = $2
        gsub(/[^A-Za-z0-9._-]/, "", name)
        if (name != "") print name
        next
      }

      in_list && /^[[:space:]]*(#.*)?$/ { next }
      in_list { exit }
    ' .sdd/config.yml)
  fi

  if [ -n "$names" ]; then
    printf '%s\n' "$names"
  else
    printf '%s\n' spec.md wireframe.html
  fi
}

# The `files:` block of a spec.link.yml, as "name hash" pairs. Tolerant on the
# way in — CR, quotes and uppercase hex are all somebody else's editor, not a
# changed spec — and canonical on the way out.
recorded_files() {
  awk '
    { sub(/\r$/, "") }
    /^files:/ { in_files = 1; next }
    in_files && /^[^[:space:]#]/ { exit }
    in_files && /^[[:space:]]*(#.*)?$/ { next }
    in_files {
      name = $1
      gsub(/[^A-Za-z0-9._-]/, "", name)
      digest = $2
      gsub(/[^A-Fa-f0-9]/, "", digest)
      if (name != "") print name, tolower(digest)
    }
  ' "$1"
}

emit() {
  local dir=$1 name
  [ -d "$dir" ] || { echo "spec-hash: no such directory: $dir" >&2; exit 2; }

  echo "files:"
  while read -r name; do
    [ -n "$name" ] || continue
    [ -f "$dir/$name" ] || continue
    printf '  %s: %s\n' "$name" "$(sha256_of "$dir/$name")"
  done < <(mirror_files)
}

checked=0
failed=0

check_one() {
  local link=$1 dir name want got found=0
  dir=$(dirname "$link")

  while read -r name want; do
    [ -n "$name" ] || continue
    checked=$((checked + 1))
    found=1
    local file="$dir/$name"

    if [ ! -f "$file" ]; then
      echo "::error file=$link::$name is recorded in spec.link.yml but is not in $dir"
      failed=1
      continue
    fi

    got=$(sha256_of "$file")
    [ "$got" = "$want" ] && continue

    if [ -n "$want" ] && [ "$(sha256_lf_of "$file")" = "$want" ]; then
      echo "::error file=$file::$name matches $link only once CR is stripped: it was committed with CRLF line endings, and the hash was recorded on the LF bytes."
      echo "::error file=$file::Fix it where it was introduced, not here: \`git config core.autocrlf input\`, then re-run /sdd-sync. .gitattributes keeps mirrors at LF once the file is normalised."
    else
      echo "::error file=$file::$name does not match the hash recorded in $link"
      echo "::error file=$file::The mirror is read-only. Correct the spec in the Spec Repository and re-run /sdd-sync — never edit it here."
    fi
    failed=1
  done < <(recorded_files "$link")

  # A link file recording nothing checks nothing, which would pass in silence.
  if [ "$found" -eq 0 ]; then
    echo "::error file=$link::spec.link.yml has no usable \`files:\` block, so nothing about this mirror is verifiable. Re-run /sdd-sync to rewrite it."
    failed=1
  fi
}

check() {
  # nullglob: this template ships with no specs at all, and a repository whose
  # spec_repo is `none` never has a spec.link.yml. Both must pass.
  shopt -s nullglob

  # No argument means every mirror. The glob may expand to nothing; "$@" is the
  # one expansion that stays safe under `set -u` when it does.
  if [ "$#" -eq 0 ]; then
    set -- docs/specs/*/spec.link.yml
  fi

  local link
  for link in "$@"; do
    # Accept a spec directory as well as the link file itself.
    [ -d "$link" ] && link="${link%/}/spec.link.yml"
    [ -f "$link" ] || continue
    check_one "$link"
  done

  if [ "$failed" -ne 0 ]; then
    echo "A mirrored spec no longer matches the hash recorded for it. docs/spec-repo.md says what to do."
    exit 1
  fi

  if [ "$checked" -eq 0 ]; then
    echo "No mirrored specs to check."
  else
    echo "$checked mirrored file(s) match their recorded hashes."
  fi
}

case "${1:-}" in
  --check|-c) shift; check "$@" ;;
  --help|-h|"") awk 'NR > 1 && /^#/ { sub(/^#[[:space:]]?/, ""); print; next } NR > 1 { exit }' "$0" ;;
  -*) echo "spec-hash: unknown option: $1" >&2; exit 2 ;;
  *) emit "${1%/}" ;;
esac
