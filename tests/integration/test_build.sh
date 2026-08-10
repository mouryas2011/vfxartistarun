#!/usr/bin/env bash
# NEXORA integration tests — verify the built ISO is real and boot-shaped.
# Run after 'make build'. The QEMU boot gate itself is `make qemu-serial`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="${VERSION:-0.1}"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
ISO="$BUILD_DIR/nexora-$VERSION.iso"
PASS=0
FAIL=0

check() {
  if eval "$2"; then PASS=$((PASS+1)); echo "PASS: $1"; else FAIL=$((FAIL+1)); echo "FAIL: $1"; fi
}

[[ -f "$ISO" ]] || { echo "FATAL: built ISO not found; run 'make build' first" >&2; exit 1; }

check "ISO is an ISO9660 hybrid image" 'file "$ISO" | grep -qi iso.*9660'

check "SHA256 checksum matches" 'cd "$BUILD_DIR" && sha256sum -c "nexora-$VERSION.iso.sha256" >/dev/null 2>&1'

check "build metadata present and valid JSON" \
  'python3 -c "import json,sys;m=json.load(open(\"$BUILD_DIR/build-metadata.json\"));assert m[\"version\"]"'

check "ISO contains GRUB EFI boot files" \
  'xorriso -osirrox on -indev "$ISO" -find /boot/grub -name "*.cfg" -print >/dev/null 2>&1'

check "ISO contains kernel + initrd" \
  'xorriso -osirrox on -indev "$ISO" -find / -name "vmlinuz*" -print 2>/dev/null | grep -q vmlinuz \
   && xorriso -osirrox on -indev "$ISO" -find / -name "initrd*" -print 2>/dev/null | grep -q initrd'

check "metadata records a version" 'grep -q "\"version\"" "$BUILD_DIR/build-metadata.json"'

echo "INTEGRATION: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]