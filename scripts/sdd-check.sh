#!/usr/bin/env bash
#
# Every check this repository runs, in one command — the same one for a
# developer, for an agent and for CI. A check only the pipeline knows how to
# run is a check you meet after review.
#
#   scripts/sdd-check.sh
#
# It writes nothing. See docs/spec-repo.md.

set -uo pipefail

if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$root"
fi

failed=0

run() {
  local label=$1
  shift
  echo "==> $label"
  "$@" || failed=1
  echo
}

case "${1:-}" in
  --help|-h)
    awk 'NR > 1 && /^#/ { sub(/^#[[:space:]]?/, ""); print; next } NR > 1 { exit }' "$0"
    exit 0
    ;;
  "") ;;
  *) echo "sdd-check: unknown option: $1" >&2; exit 2 ;;
esac

run "Specs have valid structure, statuses and traceability" bash scripts/spec-check.sh --root docs/specs
run "Spec validator behavioral fixtures" bash scripts/test-spec-check.sh
run "Mirrored specs match their hashes and name their source" bash scripts/spec-hash.sh --check

exit "$failed"
