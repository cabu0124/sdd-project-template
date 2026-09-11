#!/usr/bin/env bash
# Behavioral fixtures for source authority in spec-sync.sh.

set -euo pipefail

if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$root"
fi

sync_script="$PWD/scripts/spec-sync.sh"
hash_script="$PWD/scripts/spec-hash.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

git init -q --bare "$work/upstream.git"
git clone -q "$work/upstream.git" "$work/cache" 2>/dev/null
git -C "$work/cache" config user.email fixture@example.com
git -C "$work/cache" config user.name Fixture
mkdir -p "$work/cache/specs/001-one"
printf '%s\n' '# Spec 001 - One' '- **Status:** approved' > "$work/cache/specs/001-one/spec.md"
git -C "$work/cache" add .
git -C "$work/cache" commit -qm published
git -C "$work/cache" branch -M main
git -C "$work/cache" push -q -u origin main
published=$(git -C "$work/cache" rev-parse HEAD)

printf '%s\n' '# unpublished local change' >> "$work/cache/specs/001-one/spec.md"
git -C "$work/cache" commit -qam unpublished
unpublished=$(git -C "$work/cache" rev-parse HEAD)

mkdir -p "$work/project/.sdd" "$work/project/docs/specs" "$work/project/scripts"
cp "$sync_script" "$hash_script" "$work/project/scripts/"
git -C "$work/project" init -q

write_config() {
  local path=$1 remote=$2
  printf 'spec_repo:\n  name: fixture\n  path: %s\n  remote: %s\n  ref: main\n  specs_dir: specs\n  mirror: [spec.md]\n' \
    "$path" "$remote" > "$work/project/.sdd/config.yml"
}

write_config "$work/cache" "$work/upstream.git"
online=$(cd "$work/project" && bash scripts/spec-sync.sh --list)
printf '%s\n' "$online" | grep -Fq "$published"
if printf '%s\n' "$online" | grep -Fq "$unpublished"; then
  echo 'matching cache exposed an unpublished local commit' >&2
  exit 1
fi

offline=$(cd "$work/project" && bash scripts/spec-sync.sh --offline --list 2>&1)
printf '%s\n' "$offline" | grep -Fq "$published"
printf '%s\n' "$offline" | grep -Fq 'freshness against'

git init -q --bare "$work/other.git"
git -C "$work/cache" remote set-url origin "$work/other.git"
write_config "$work/cache" "$work/upstream.git"
mismatch=$(cd "$work/project" && bash scripts/spec-sync.sh --list 2>&1)
printf '%s\n' "$mismatch" | grep -Fq 'ignoring path'
printf '%s\n' "$mismatch" | grep -Fq "remote $work/upstream.git"
printf '%s\n' "$mismatch" | grep -Fq "$published"

write_config "$work/cache" ''
local_only=$(cd "$work/project" && bash scripts/spec-sync.sh --list)
printf '%s\n' "$local_only" | grep -Fq 'local-only path'
printf '%s\n' "$local_only" | grep -Fq "$unpublished"

echo '4 spec-sync authority fixture(s) passed.'