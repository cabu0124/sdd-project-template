#!/usr/bin/env bash
# Behavioral fixtures for sdd-preflight.sh: repository freshness, the consumers
# registry, and when a moved spec blocks rather than warns.

set -euo pipefail

if root=$(git rev-parse --show-toplevel 2>/dev/null); then
  cd "$root"
fi

scripts="$PWD/scripts"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

git config --global --get init.defaultBranch >/dev/null 2>&1 || true

new_repo() { # name -> a working clone on develop with a bare origin
  local name=$1
  git init -q --bare "$work/$name.git"
  git clone -q "$work/$name.git" "$work/$name" 2>/dev/null
  git -C "$work/$name" config user.email fixture@example.com
  git -C "$work/$name" config user.name Fixture
  echo "$name" > "$work/$name/README.md"
  git -C "$work/$name" add .
  git -C "$work/$name" commit -qm init
  git -C "$work/$name" branch -M develop
  git -C "$work/$name" push -q -u origin develop
}

# The Spec Repository: a bare remote plus the clone the project caches.
git init -q --bare "$work/upstream.git"
git clone -q "$work/upstream.git" "$work/cache" 2>/dev/null
git -C "$work/cache" config user.email fixture@example.com
git -C "$work/cache" config user.name Fixture
mkdir -p "$work/cache/specs/001-one" "$work/cache/docs"
printf '%s\n' '# Spec 001 - One' '- **Status:** approved' > "$work/cache/specs/001-one/spec.md"
cat > "$work/cache/docs/consumers.md" <<'REGISTRY'
# Consumers

<!-- sdd:consumers:start -->
```json
{
  "version": 1,
  "consumers": [
    { "name": "acme-web", "builds": "the web app" },
    { "name": "acme-api", "builds": "the API" }
  ]
}
```
<!-- sdd:consumers:end -->
REGISTRY
git -C "$work/cache" add .
git -C "$work/cache" commit -qm published
git -C "$work/cache" branch -M main
git -C "$work/cache" push -q -u origin main

new_repo acme-web
new_repo acme-api

mkdir -p "$work/acme-web/.sdd" "$work/acme-web/specs" "$work/acme-web/scripts"
cp "$scripts/spec-sync.sh" "$scripts/spec-pointer-check.sh" "$scripts/sdd-preflight.sh" \
  "$scripts/sdd-lib.sh" "$scripts/sdd-recall.sh" "$work/acme-web/scripts/"
printf 'spec_repo:\n  name: acme-specs\n  path: %s\n  remote: %s\n  ref: main\n  specs_dir: specs\n' \
  "$work/cache" "$work/upstream.git" > "$work/acme-web/.sdd/config.yml"
git -C "$work/acme-web" add .
git -C "$work/acme-web" commit -qm scaffold
git -C "$work/acme-web" push -q origin develop

run() { (cd "$work/acme-web" && bash scripts/sdd-preflight.sh "$@" 2>&1); }

# 1. Everything fresh: ready, and the sibling in the registry was checked.
out=$(run) || { echo 'preflight should pass when everything is fresh' >&2; echo "$out" >&2; exit 1; }
printf '%s\n' "$out" | grep -Fq 'READY'
printf '%s\n' "$out" | grep -Fq 'ok: acme-api'
printf '%s\n' "$out" | grep -Fq 'acme-specs resolved main'

# 2. A consumer left behind blocks, and says so by name.
echo change > "$work/acme-api/other.md"
git -C "$work/acme-api" add .
git -C "$work/acme-api" commit -qm ahead
git -C "$work/acme-api" push -q origin develop
git -C "$work/acme-api" reset -q --hard HEAD~1
if out=$(run); then
  echo 'preflight should block on a consumer that is behind' >&2
  echo "$out" >&2
  exit 1
fi
printf '%s\n' "$out" | grep -Fq 'acme-api'
printf '%s\n' "$out" | grep -Fq 'behind origin/develop'
git -C "$work/acme-api" merge -q --ff-only origin/develop

# 3. A registered spec at its recorded revision is current.
commit=$(cd "$work/acme-web" && bash scripts/spec-sync.sh --resolve)
(cd "$work/acme-web" && bash scripts/spec-sync.sh --write "$commit" 001-one) >/dev/null
out=$(run) || { echo 'preflight should pass with a current pointer' >&2; echo "$out" >&2; exit 1; }
printf '%s\n' "$out" | grep -Fq 'ok: 001-one is at the revision it records'

# 4. The spec moves upstream. It warns for a spec nobody named...
printf '%s\n' '- **R1** - A new requirement.' >> "$work/cache/specs/001-one/spec.md"
git -C "$work/cache" commit -qam amended
git -C "$work/cache" push -q origin main
out=$(run) || { echo 'an unrelated moved spec should warn, not block' >&2; echo "$out" >&2; exit 1; }
printf '%s\n' "$out" | grep -Fq 'Not blocking'

# ...and blocks the one being worked on.
if out=$(run --spec 001-one); then
  echo 'preflight should block when the active spec moved upstream' >&2
  echo "$out" >&2
  exit 1
fi
printf '%s\n' "$out" | grep -Fq 'moved upstream'
printf '%s\n' "$out" | grep -Fq 'BLOCKED'

# 5. A spec copied in beside the pointer blocks whatever else is true.
printf '%s\n' '# Spec 001 - One' > "$work/acme-web/specs/001-one/spec.md"
if out=$(run); then
  echo 'preflight should block on a copied spec' >&2
  echo "$out" >&2
  exit 1
fi
printf '%s\n' "$out" | grep -Fq 'never copied here'
rm "$work/acme-web/specs/001-one/spec.md"

echo '6 sdd-preflight fixture(s) passed.'
