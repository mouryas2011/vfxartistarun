#!/usr/bin/env bash
# NEXORA lint — static checks that run before any build.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FAIL=0

echo "== shellcheck =="
if command -v shellcheck >/dev/null 2>&1; then
  while IFS= read -r -d '' f; do
    echo "linting $f"
    shellcheck "$f" || FAIL=1
  done < <(find scripts tests -name '*.sh' -print0)
else
  echo "shellcheck not found — skipping (run 'make bootstrap')."
fi

echo "== config validation =="
while IFS= read -r -d '' f; do
  echo "validating $f"
  python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" || FAIL=1
done < <(find packaging -name '*.json' -print0)

echo "== no-secrets scan =="
if rg -i -U --glob '!docs/**' --glob '!.git/**' '(API[_-]?KEY|SECRET|PASSWORD|PRIVATE KEY)=["'"'"]?[A-Za-z0-9+/]{16,}' . >/dev/null 2>&1; then
  echo "ERROR: possible secret-like content found." >&2
  FAIL=1
fi

if [[ $FAIL -ne 0 ]]; then
  echo "LINT FAILED"
  exit 1
fi
echo "LINT OK"