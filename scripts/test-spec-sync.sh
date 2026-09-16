#!/usr/bin/env bash
# Behavioral fixtures for source authority in spec-sync.sh.

set -euo pipefail

if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$root"
fi

sync_script="$PWD/scripts/spec-sync.sh"
pointer_script="$PWD/scripts/spec-pointer-check.sh"
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

mkdir -p "$work/project/.sdd" "$work/project/specs" "$work/project/scripts"
cp "$sync_script" "$pointer_script" "$work/project/scripts/"
git -C "$work/project" init -q

write_config() {
  local path=$1 remote=$2
  printf 'spec_repo:\n  name: fixture\n  path: %s\n  remote: %s\n  ref: main\n  specs_dir: specs\n' \
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

# A sync writes a pointer and no copy of the spec.
write_config "$work/cache" "$work/upstream.git"
preview=$(cd "$work/project" && bash scripts/spec-sync.sh 001-one) && preview_exit=0 || preview_exit=$?
[ "$preview_exit" -eq 3 ] || { echo "preview should exit 3, got $preview_exit" >&2; exit 1; }
[ -e "$work/project/specs/001-one" ] && { echo 'preview wrote something' >&2; exit 1; }

(cd "$work/project" && bash scripts/spec-sync.sh --write "$published" 001-one) >/dev/null
[ -f "$work/project/specs/001-one/spec.link.yml" ] || { echo 'no pointer written' >&2; exit 1; }
for copied in spec.md wireframe.html; do
  [ -e "$work/project/specs/001-one/$copied" ] && { echo "sync copied $copied" >&2; exit 1; }
done
grep -Fq "commit: $published" "$work/project/specs/001-one/spec.link.yml"
grep -Fq 'local_id: 001-one' "$work/project/specs/001-one/spec.link.yml"
grep -Eq '^files:' "$work/project/specs/001-one/spec.link.yml" && { echo 'pointer still records hashes' >&2; exit 1; }

# Re-running on the same revision is a no-op, not a rewrite.
again=$(cd "$work/project" && bash scripts/spec-sync.sh 001-one)
printf '%s\n' "$again" | grep -Fq 'Already in sync.'

# A spec copied back in beside the pointer is what the pointer check exists for.
printf '%s\n' '# Spec 001 - One' > "$work/project/specs/001-one/spec.md"
if (cd "$work/project" && bash scripts/spec-pointer-check.sh) >"$work/copied.out" 2>&1; then
  echo 'pointer check accepted a copied spec' >&2
  exit 1
fi
grep -Fq 'never copied here' "$work/copied.out"
rm "$work/project/specs/001-one/spec.md"

# The local id is the directory the pointer sits in.
sed -i.bak 's/local_id: 001-one/local_id: 009-elsewhere/' "$work/project/specs/001-one/spec.link.yml"
if (cd "$work/project" && bash scripts/spec-pointer-check.sh) >"$work/localid.out" 2>&1; then
  echo 'pointer check accepted a mismatched local_id' >&2
  exit 1
fi
grep -Fq 'local id is the directory name' "$work/localid.out"

echo '9 spec-sync authority fixture(s) passed.'