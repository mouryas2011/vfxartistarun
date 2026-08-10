#!/usr/bin/env bash
# NEXORA QEMU boot test (§79). Boots the NEXORA development ISO under UEFI.
#
# Usage:
#   ./scripts/run-qemu.sh --iso build/nexora-0.1.iso                 # interactive
#   ./scripts/run-qemu.sh --iso build/nexora-0.1.iso --headless      # serial log + gate check
#
# Options:
#   --iso PATH      ISO to boot (default: build/nexora-<VERSION>.iso)
#   --ram MB        RAM (default 2048)
#   --cpu CPU       QEMU CPU model (default qemu64, no KVM requirement)
#   --headless      run detached, capture serial log, gate on NEXORA_BOOT_MARKER
#   --timeout SEC   headless timeout (default 240)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.1}"
ISO="$ROOT/build/nexora-$VERSION.iso"
RAM=2048
CPU="qemu64"
HEADLESS=0
TIMEOUT=240

while [[ $# -gt 0 ]]; do
  case "$1" in
    --iso) ISO="$2"; shift 2 ;;
    --ram) RAM="$2"; shift 2 ;;
    --cpu) CPU="$2"; shift 2 ;;
    --headless) HEADLESS=1; shift ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: run-qemu.sh requires Linux and QEMU. This host has neither."
  echo "  Use GitHub Actions CI or a Linux environment. See BUILD.md." >&2
  exit 1
fi

command -v qemu-system-x86_64 >/dev/null || { echo "qemu-system-x86_64 missing (make bootstrap)" >&2; exit 1; }
[[ -f "$ISO" ]] || { echo "ISO not found: $ISO (run 'make build')" >&2; exit 1; }

OVMF=""
for f in \
  /usr/share/OVMF/OVMF_CODE.fd \
  /usr/share/OVMF/OVMF_CODE_4M.fd \
  /usr/share/ovmf/OVMF_CODE.fd \
  /usr/share/ovmf/OVMF_CODE_4M.fd \
  /usr/share/qemu/OVMF_CODE.fd; do
  if [[ -f "$f" ]]; then OVMF="$f"; break; fi
done
if [[ -z "$OVMF" ]]; then
  echo "ERROR: OVMF (UEFI firmware) not found. Install the 'ovmf' package." >&2
  exit 1
fi
echo "UEFI firmware: $OVMF"

COMMON=(
  -machine q35,accel=tcg
  -cpu "$CPU"
  -m "$RAM"
  -smp 2
  -bios "$OVMF"
  -cdrom "$ISO"
  -boot order=d
)

if [[ $HEADLESS -eq 1 ]]; then
  LOG="$ROOT/build/qemu-serial.log"
  echo "Headless UEFI boot test; serial log -> $LOG (timeout ${TIMEOUT}s)"
  qemu-system-x86_64 "${COMMON[@]}" \
    -display none -nographic \
    -serial "file:$LOG" &
  QPID=$!
  # wait for either exit or timeout
  GATE=0
  for _ in $(seq 1 "$TIMEOUT"); do
    if ! kill -0 "$QPID" 2>/dev/null; then
      wait "$QPID" 2>/dev/null || true
      break
    fi
    if grep -q "NEXORA_BOOT_MARKER" "$LOG" 2>/dev/null; then GATE=1; break; fi
    sleep 1
  done
  kill "$QPID" 2>/dev/null || true
  wait "$QPID" 2>/dev/null || true
  echo "---- serial log tail ----"
  tail -n 30 "$LOG" || true
  if [[ $GATE -eq 1 ]]; then
    echo "QEMU BOOT TEST PASS: NEXORA_BOOT_MARKER reached."
    exit 0
  fi
  echo "QEMU BOOT TEST FAIL: marker not reached within ${TIMEOUT}s." >&2
  exit 1
else
  echo "Interactive QEMU (UEFI). Use Ctrl-A X to quit."
  qemu-system-x86_64 "${COMMON[@]}" -serial mon:stdio
fi