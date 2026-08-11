#!/usr/bin/env bash
# NEXORA installer gate (§Phase 2). Verifies a real, reproducible install:
#   1. Boot the live ISO in QEMU with a scratch disk; the auto-install service
#      (triggered by nexora.install= on the kernel cmdline) installs to it.
#   2. Reboot from the installed disk under UEFI (OVMF) and require the
#      NEXORA_BOOT_MARKER, proving the installed system boots on its own.
#
# This is a real install test (partition/format/grub), not a simulation.
#
# Usage:
#   ./scripts/run-qemu-install.sh --iso build/nexora-0.1.iso
# Options:
#   --iso PATH     ISO to install from (default build/nexora-<VERSION>.iso)
#   --ram MB       RAM (default 2048)
#   --timeout SEC  per-phase timeout (default 300)
#   --disk-size G  scratch disk size (default 4G)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.1}"
ISO="$ROOT/build/nexora-$VERSION.iso"
DISK="$ROOT/build/install-disk.img"
INSTALL_LOG="$ROOT/build/qemu-install.log"
BOOT_LOG="$ROOT/build/qemu-installed-boot.log"
RAM=2048
TIMEOUT=300
DISK_SIZE="4G"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --iso) ISO="$2"; shift 2 ;;
    --ram) RAM="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --disk-size) DISK_SIZE="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: run-qemu-install.sh requires Linux and QEMU." >&2
  echo "  Use GitHub Actions CI or a Linux environment. See BUILD.md." >&2
  exit 1
fi

for tool in qemu-system-x86_64 qemu-img xorriso; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 1; }
done
[[ -f "$ISO" ]] || { echo "ISO not found: $ISO (run 'make build')" >&2; exit 1; }

OVMF_CODE=""
OVMF_VARS=""
for code in \
  /usr/share/OVMF/OVMF_CODE_4M.fd \
  /usr/share/OVMF/OVMF_CODE.fd \
  /usr/share/ovmf/OVMF_CODE_4M.fd \
  /usr/share/ovmf/OVMF_CODE.fd; do
  if [[ -f "$code" ]]; then OVMF_CODE="$code"; break; fi
done
for vars in \
  /usr/share/OVMF/OVMF_VARS_4M.fd \
  /usr/share/OVMF/OVMF_VARS.fd \
  /usr/share/ovmf/OVMF_VARS_4M.fd \
  /usr/share/ovmf/OVMF_VARS.fd; do
  if [[ -f "$vars" ]]; then OVMF_VARS="$vars"; break; fi
done
if [[ -z "$OVMF_CODE" || -z "$OVMF_VARS" ]]; then
  echo "ERROR: OVMF (UEFI firmware) not found. Install the 'ovmf' package." >&2
  exit 1
fi

echo "== phase 1: install live ISO to scratch disk =="
rm -f "$DISK" "$INSTALL_LOG" "$BOOT_LOG"
qemu-img create -f raw "$DISK" "$DISK_SIZE" >/dev/null
echo "scratch disk: $DISK ($DISK_SIZE)"

# Direct-boot the live kernel so we control the cmdline (nexora.install=).
VMLINUZ="$ROOT/build/live-vmlinuz"
INITRD="$ROOT/build/live-initrd.img"
xorriso -osirrox on -indev "$ISO" \
  -extract /live/vmlinuz "$VMLINUZ" \
  -extract /live/initrd.img "$INITRD" >/dev/null 2>&1

qemu-system-x86_64 \
  -machine 'q35,accel=tcg' -cpu qemu64 -m "$RAM" -smp 2 \
  -kernel "$VMLINUZ" -initrd "$INITRD" \
  -append "boot=live console=ttyS0,115200 console=tty0 nexora.install=/dev/vda" \
  -cdrom "$ISO" \
  -drive "file=$DISK,format=raw,if=none,id=inst0" \
  -device virtio-blk-pci,drive=inst0 \
  -display none -nographic \
  -serial "file:$INSTALL_LOG" &
QPID=$!

GATE_INSTALL=0
for _ in $(seq 1 "$TIMEOUT"); do
  if ! kill -0 "$QPID" 2>/dev/null; then
    wait "$QPID" 2>/dev/null || true
    break
  fi
  if grep -q "NEXORA INSTALL OK" "$INSTALL_LOG" 2>/dev/null; then GATE_INSTALL=1; break; fi
  sleep 1
done
kill "$QPID" 2>/dev/null || true
wait "$QPID" 2>/dev/null || true
# the VM powers off immediately after the marker, so re-check the full log
if [[ $GATE_INSTALL -eq 0 ]] && grep -q "NEXORA INSTALL OK" "$INSTALL_LOG" 2>/dev/null; then
  GATE_INSTALL=1
fi

echo "---- install log tail ----"
tail -n 20 "$INSTALL_LOG" 2>/dev/null || true
if [[ $GATE_INSTALL -eq 1 ]]; then
  echo "INSTALL PHASE PASS: installer completed."
else
  echo "INSTALL PHASE FAIL: installer did not report success." >&2
  exit 1
fi

echo "== phase 2: boot installed disk under UEFI =="
PFLASH_VARS="$ROOT/build/install-OVMF_VARS.fd"
cp "$OVMF_VARS" "$PFLASH_VARS"
chmod 644 "$PFLASH_VARS"

qemu-system-x86_64 \
  -machine 'q35,accel=tcg' -cpu qemu64 -m "$RAM" -smp 2 \
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
  -drive "if=pflash,format=raw,file=$PFLASH_VARS" \
  -drive "file=$DISK,format=raw,if=none,id=inst0" \
  -device virtio-blk-pci,drive=inst0 \
  -boot order=c \
  -display none -nographic \
  -serial "file:$BOOT_LOG" &
QPID=$!

GATE_BOOT=0
for _ in $(seq 1 "$TIMEOUT"); do
  if ! kill -0 "$QPID" 2>/dev/null; then
    wait "$QPID" 2>/dev/null || true
    break
  fi
  if grep -q "NEXORA_BOOT_MARKER" "$BOOT_LOG" 2>/dev/null; then GATE_BOOT=1; break; fi
  sleep 1
done
kill "$QPID" 2>/dev/null || true
wait "$QPID" 2>/dev/null || true
# the guest may power itself off after the marker; re-check the full log
if [[ $GATE_BOOT -eq 0 ]] && grep -q "NEXORA_BOOT_MARKER" "$BOOT_LOG" 2>/dev/null; then
  GATE_BOOT=1
fi

echo "---- installed-boot log tail ----"
tail -n 25 "$BOOT_LOG" 2>/dev/null || true
if [[ $GATE_BOOT -eq 1 ]]; then
  echo "INSTALL GATE PASS: installed system boots under UEFI (marker reached)."
  exit 0
fi
echo "INSTALL GATE FAIL: installed system did not reach the boot marker." >&2
exit 1
