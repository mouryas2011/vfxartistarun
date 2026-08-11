#!/usr/bin/env bash
# NEXORA unit tests — Phase 0 repository invariants.
# These validate the repository itself (structure, locking, configs, docs).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
PASS=0
FAIL=0

check() { # name, condition-result
  if eval "$2"; then
    PASS=$((PASS+1)); echo "PASS: $1"
  else
    FAIL=$((FAIL+1)); echo "FAIL: $1"
  fi
}

check "docs index complete" \
  '[[ -f README.md && -f AGENTS.md && -f ARCHITECTURE.md && -f ROADMAP.md
      && -f SECURITY.md && -f BUILD.md && -f TESTING.md
      && -f COMPATIBILITY.md && -f DEVELOPMENT.md ]]'

check "required lock files exist" \
  '[[ -f packaging/lock/debian-release.txt && -f packaging/lock/packages.txt
      && -f packaging/lock/tools.env ]]'

check "debian-release is pinned, not empty" \
  '[[ -s packaging/lock/debian-release.txt ]]'

check "packages lockfile has entries" \
  '[[ -s packaging/lock/packages.txt ]]'

RELEASE_SUPPORTED="bookworm"
check "debian release is in supported set ($RELEASE_SUPPORTED)" \
  'grep -qx "$RELEASE_SUPPORTED" packaging/lock/debian-release.txt'

check "scripts exist" \
  '[[ -x scripts/build-iso.sh && -x scripts/run-qemu.sh && -x scripts/bootstrap.sh && -x scripts/lint.sh && -x scripts/install-system.sh && -x scripts/run-qemu-install.sh && -x scripts/run-qemu-graphical.sh ]]'

check "graphical foundation sources exist" \
  '[[ -f desktop/compositor/nexora-pixel-client.c && -f desktop/compositor/nexora-graphical.sh ]]'

check "core structure dirs exist (sample, §75)" \
  'for d in kernel boot hal core semantic desktop mobile apps ai compatibility virtualization package-manager store installer recovery updates; do [[ -d $d ]] || exit 1; done'

check "no secrets in repo (fast scan)" \
  '! grep -riIlE --exclude-dir=.git "(API[_-]?KEY|SECRET|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY)=*[A-Za-z0-9+/]{16,}" . 2>/dev/null'

check "build dir absent from version control" \
  '! grep -qx "build/" .gitignore 2>/dev/null || true; grep -qx "build/" .gitignore'

check "lockfiles are JSON-valid where applicable" \
  'shopt -s nullglob; for f in packaging/lock/*.json; do python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$f" || exit 1; done'

echo "UNIT: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]