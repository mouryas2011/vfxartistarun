#!/usr/bin/env bash
# NEXORA one-command developer setup for a fresh Ubuntu Linux box/VM.
#
# Installs all build + QEMU test tools, clones the repository, builds the ISO,
# and runs the full automated installer gate (make qemu-install).
#
# Run inside Ubuntu (e.g. a VirtualBox VM) as a single command:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/mouryas2011/vfxartistarun/master/scripts/dev-setup-ubuntu.sh)"
#
# Or after cloning the repo:
#   ./scripts/dev-setup-ubuntu.sh

set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: this script requires Linux (Ubuntu). Use a VM or CI." >&2
  exit 1
fi

echo "== [1/5] base tools (git, curl) =="
if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y git curl
fi

echo "== [2/5] clone repository =="
REPO_DIR="${NEXORA_DIR:-$HOME/nexora}"
if [[ ! -d "$REPO_DIR" ]]; then
  git clone https://github.com/mouryas2011/vfxartistarun.git "$REPO_DIR"
else
  echo "repo already at $REPO_DIR (updating)"
  git -C "$REPO_DIR" pull --ff-only 2>/dev/null || true
fi
cd "$REPO_DIR"

echo "== [3/5] install build + QEMU tools =="
sudo apt-get update
sudo apt-get install -y \
  build-essential make git bash python3 shellcheck \
  debootstrap xorriso \
  squashfs-tools dosfstools mtools \
  qemu-system-x86 qemu-utils ovmf
make bootstrap

echo "== [4/5] build ISO + run the installer gate =="
make qemu-install

echo ""
echo "SETUP DONE: installer gate PASS"
echo "  install log : $REPO_DIR/build/qemu-install.log"
echo "  boot log    : $REPO_DIR/build/qemu-installed-boot.log"
