#!/usr/bin/env bash
# NEXORA graphical gate (§Phase 2). Boots the live ISO under UEFI with a
# virtual GPU (virtio-gpu), waits for the compositor to render real pixels
# (NEXORA_GRAPHICAL_READY marker, written only after a Wayland client's frame
# callback), then captures the display with QEMU screendump and verifies the
# screenshot is a real rendered frame (multiple distinct colours).
#
# Usage:
#   ./scripts/run-qemu-graphical.sh --iso build/nexora-0.1.iso
# Options:
#   --iso PATH      ISO to boot (default build/nexora-<VERSION>.iso)
#   --ram MB        RAM (default 2048)
#   --timeout SEC   gate timeout (default 300)
#   --port PORT     QEMU monitor TCP port (default random 21000-31000)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.1}"
ISO="$ROOT/build/nexora-$VERSION.iso"
LOG="$ROOT/build/qemu-graphical.log"
PPM="$ROOT/build/nexora-graphical-screen.ppm"
RAM=2048
TIMEOUT=300
PORT=$((21000 + RANDOM % 10000))

while [[ $# -gt 0 ]]; do
  case "$1" in
    --iso) ISO="$2"; shift 2 ;;
    --ram) RAM="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: run-qemu-graphical.sh requires Linux and QEMU." >&2
  echo "  Use GitHub Actions CI or a Linux environment. See BUILD.md." >&2
  exit 1
fi

for tool in qemu-system-x86_64 python3; do
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

PFLASH_VARS="$ROOT/build/graphical-OVMF_VARS.fd"
cp "$OVMF_VARS" "$PFLASH_VARS"
chmod 644 "$PFLASH_VARS"

rm -f "$LOG" "$PPM"
echo "Graphical gate; serial log -> $LOG, monitor TCP port $PORT (timeout ${TIMEOUT}s)"

qemu-system-x86_64 \
  -machine 'q35,accel=tcg' -cpu qemu64 -m "$RAM" -smp 2 \
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE" \
  -drive "if=pflash,format=raw,file=$PFLASH_VARS" \
  -cdrom "$ISO" -boot order=d \
  -vga none -device virtio-gpu-pci \
  -display egl-headless \
  -monitor "tcp:127.0.0.1:$PORT,server,nowait" \
  -serial "file:$LOG" &
QPID=$!

GATE=0
for _ in $(seq 1 "$TIMEOUT"); do
  if ! kill -0 "$QPID" 2>/dev/null; then
    wait "$QPID" 2>/dev/null || true
    break
  fi
  if grep -q "NEXORA_GRAPHICAL_READY" "$LOG" 2>/dev/null; then GATE=1; break; fi
  sleep 1
done

# The compositor may finish a frame just after the poll; re-check full log.
if [[ $GATE -eq 0 ]] && grep -q "NEXORA_GRAPHICAL_READY" "$LOG" 2>/dev/null; then
  GATE=1
fi

PIXELS=0
if [[ $GATE -eq 1 ]]; then
  sleep 3
  echo "compositor ready; capturing screenshot"
  # screendump via the QEMU HMP monitor (raw TCP socket).
  if exec 3<>"/dev/tcp/127.0.0.1/$PORT" 2>/dev/null; then
    printf 'screendump %s\n' "$PPM" >&3
    sleep 2
    exec 3>&-
  fi
  if [[ -f "$PPM" ]]; then
    if python3 - "$PPM" <<'PY'
import sys

path = sys.argv[1]
with open(path, "rb") as fh:
    assert fh.readline().strip() == b"P6", "not a P6 PPM"
    dims = fh.readline().split()
    while len(dims) != 2:
        dims = fh.readline().split()
    w, h = int(dims[0]), int(dims[1])
    maxv = fh.readline().strip()
    assert maxv in (b"255", b"255\r"), "unexpected max value"
    data = fh.read(w * h * 3)

if len(data) < w * h * 3:
    raise SystemExit("short PPM data")

step = max(1, min(w, h) // 40)
colors = set()
samples = 0
for y in range(0, h, step):
    for x in range(0, w, step):
        i = (y * w + x) * 3
        colors.add(data[i:i + 3])
        samples += 1

if len(colors) < 2:
    raise SystemExit(
        "frame is blank/single-colour: %d samples, %d colours" % (samples, len(colors)))
print("pixels ok: %d samples, %d distinct colours, %dx%d" % (samples, len(colors), w, h))
PY
    then PIXELS=1; fi
  fi
fi

kill "$QPID" 2>/dev/null || true
wait "$QPID" 2>/dev/null || true

echo "---- graphical serial log tail ----"
tail -n 30 "$LOG" 2>/dev/null || true

if [[ $GATE -eq 1 && $PIXELS -eq 1 ]]; then
  echo "GRAPHICAL GATE PASS: compositor rendered real pixels ($PPM)."
  exit 0
fi
echo "GRAPHICAL GATE FAIL: marker=$GATE pixels=$PIXELS" >&2
exit 1
