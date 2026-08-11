#!/bin/bash
# NEXORA Wayland graphical session (Phase 2 foundation).
#
# Starts the NEXORA compositor session (weston) — on the DRM device when one
# is present (real GPU, e.g. virtio-gpu), falling back to the headless
# backend otherwise. Then it verifies the session with two real checks:
#   1. wayland-info performs a protocol round-trip to the compositor.
#   2. nexora-pixel-client renders a checkerboard frame through Wayland
#      (frame callback = the compositor really presented the buffer).
# Only then NEXORA_GRAPHICAL_READY is written to the serial console.
#
# Installed in the image as /usr/sbin/nexora-graphical.sh.

set -u

export XDG_RUNTIME_DIR=/run/nexora
export WAYLAND_DISPLAY=wayland-0
mkdir -p "$XDG_RUNTIME_DIR"
chmod 0700 "$XDG_RUNTIME_DIR"

MARKLOG=/var/log/nexora-graphical.log
LOG=/var/log/nexora-weston.log

BACKEND=headless
if [[ -e /dev/dri/card0 ]]; then
  BACKEND=drm
fi

start_compositor() {
  local args
  args=(--backend="$BACKEND" --log="$LOG")
  if [[ "$BACKEND" == drm ]]; then
    args+=(--use-pixman --seat=seat0 --tty=1)
  fi
  echo "nexora-graphical: starting weston ($BACKEND)" >> "$MARKLOG"
  weston "${args[@]}" &
  WPID=$!
}

wait_socket() {
  local i
  for i in $(seq 1 30); do
    [[ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]] && return 0
    kill -0 "$WPID" 2>/dev/null || return 1
    sleep 1
  done
  return 1
}

verify_compositor() {
  wayland-info "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" >/dev/null 2>&1
}

mark_ready() {
  printf 'NEXORA_GRAPHICAL_READY backend=%s\n' "$BACKEND" \
    >> /dev/ttyS0 2>/dev/null || true
  printf 'NEXORA_GRAPHICAL_READY backend=%s\n' "$BACKEND" >> "$MARKLOG"
}

start_compositor

READY=0
if wait_socket && verify_compositor; then
  READY=1
fi

if [[ $READY -eq 0 && "$BACKEND" != headless ]]; then
  echo "nexora-graphical: drm backend failed, retrying headless" >> "$MARKLOG"
  kill "$WPID" 2>/dev/null || true
  wait "$WPID" 2>/dev/null || true
  BACKEND=headless
  start_compositor
  if wait_socket && verify_compositor; then
    READY=1
  fi
fi

if [[ $READY -eq 1 ]]; then
  if /usr/libexec/nexora/nexora-pixel-client > /var/log/nexora-pixel-client.log 2>&1; then
    echo "nexora-graphical: pixel client rendered a frame" >> "$MARKLOG"
    mark_ready
  else
    echo "nexora-graphical: pixel client failed (see /var/log/nexora-pixel-client.log)" >> "$MARKLOG"
  fi
else
  echo "nexora-graphical: compositor did not become ready" >> "$MARKLOG"
fi

wait "$WPID" 2>/dev/null || true
