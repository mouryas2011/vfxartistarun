#!/usr/bin/env bash
# NEXORA build bootstrap — install host build prerequisites (Linux only).
# Idempotent: safe to run repeatedly. Requires sudo for package install.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="$ROOT/packaging/lock"

echo "== NEXORA bootstrap =="
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: build bootstrap requires Linux. Use the GitHub Actions CI pipeline"
  echo "  or a Linux environment (WSL2/VM/remote). See BUILD.md." >&2
  exit 1
fi

source "$LOCK/tools.env"

MISSING=()
for t in $REQUIRED_TOOLS; do
  if ! command -v "$t" >/dev/null 2>&1; then
    MISSING+=("$t")
  fi
done

if [[ ${#MISSING[@]} -eq 0 ]]; then
  echo "All required tools present: $REQUIRED_TOOLS"
  exit 0
fi

if command -v apt-get >/dev/null 2>&1; then
  echo "Installing via apt: ${MISSING[*]}"
  sudo apt-get update
  # shellcheck disable=SC2086
  sudo apt-get install -y ${MISSING[*]}
else
  echo "Missing tools: ${MISSING[*]}" >&2
  echo "Install them manually, or add your distro's path to packaging/lock/tools.env" >&2
  exit 1
fi

echo "Bootstrap complete."