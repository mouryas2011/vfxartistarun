#!/usr/bin/env bash
# NEXORA Phase 1 — build a reproducible bootable UEFI development ISO.
#
# Approach: debootstrap a minimal Debian rootfs, add live-boot + kernel + a
# NEXORA marker service, then produce a UEFI-bootable ISO with grub-mkrescue.
# This is the smallest stable unit for the Phase 1 gate (§99): a real,
# bootable Linux image verified later in QEMU (§79).
#
# Requires a Linux host (or CI runner) and network access. Requires root for
# debootstrap/chroot steps (uses sudo when not already root).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
VERSION="${VERSION:-0.1}"
ARCH="amd64"
RELEASE="$(cat "$ROOT/packaging/lock/debian-release.txt")"
MIRROR="${DEBIAN_MIRROR:-http://deb.debian.org/debian}"
CHROOT="$BUILD_DIR/rootfs"
STAGE="$BUILD_DIR/stage"
ISO="$BUILD_DIR/nexora-$VERSION.iso"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "ERROR: build-iso.sh requires Linux (use CI or a Linux environment). See BUILD.md." >&2
  exit 1
fi

if [[ $EUID -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: missing required tool: $1 (run 'make bootstrap')" >&2
    exit 1
  fi
}
require debootstrap
require grub-mkrescue
require xorriso

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$STAGE"

echo "== [1/6] debootstrap $RELEASE ($ARCH) =="
$SUDO debootstrap --variant=minbase --arch=$ARCH "$RELEASE" "$CHROOT" "$MIRROR"

echo "== [2/6] share package lockfile + bind mounts for chroot =="
$SUDO cp "$ROOT/packaging/lock/packages.txt" "$CHROOT/tmp/packages.txt"
for d in /proc /sys /dev; do
  $SUDO mount --bind "$d" "$CHROOT$d"
done
$SUDO mkdir -p "$CHROOT/dev/pts"
$SUDO mount -t devpts devpts "$CHROOT/dev/pts"
# shellcheck disable=SC2154
trap 'for m in dev/pts dev sys proc; do "$SUDO" umount "$CHROOT/$m" 2>/dev/null || true; done' EXIT

echo "== [3/6] install minimal packages =="
# shellcheck disable=SC2024
$SUDO chroot "$CHROOT" /bin/bash -euxc '
export DEBIAN_FRONTEND=noninteractive
apt-get update
mapfile -t PKGS < <(grep -vE "^[[:space:]]*(#|\$)" /tmp/packages.txt)
apt-get install -y --no-install-recommends "${PKGS[@]}"
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -f /tmp/packages.txt
'

echo "== [4/6] NEXORA identification + boot marker =="
$SUDO hostname nexora
$SUDO tee "$CHROOT/etc/os-release" >/dev/null <<EOF
NAME="NEXORA OS"
ID=nexora
PRETTY_NAME="NEXORA OS $VERSION (development)"
VERSION_ID=$VERSION
HOME_URL="https://nexora.example.invalid"
EOF

$SUDO tee "$CHROOT/usr/sbin/nexora-bootmark.sh" >/dev/null <<EOF
#!/bin/sh
printf 'NEXORA_BOOT_MARKER version=%s\n' "$VERSION" >> /dev/ttyS0 2>/dev/null || true
printf 'NEXORA_BOOT_MARKER version=%s\n' "$VERSION" >> /var/log/nexora-boot.log
EOF
$SUDO chmod 755 "$CHROOT/usr/sbin/nexora-bootmark.sh"

$SUDO tee "$CHROOT/etc/systemd/system/nexora-boot.service" >/dev/null <<EOF
[Unit]
Description=NEXORA boot marker
DefaultDependencies=no
After=systemd-remount-fs.service
[Service]
Type=oneshot
ExecStart=/usr/sbin/nexora-bootmark.sh
[Install]
WantedBy=sysinit.target
EOF

$SUDO chroot "$CHROOT" /bin/bash -euxc '
systemctl enable nexora-boot.service
echo nexora > /etc/hostname
printf "NEXORA dev image %s\n" "$VERSION" > /etc/nexora-version
'

echo "== [5/6] build initramfs and copy kernel =="
$SUDO chroot "$CHROOT" /bin/bash -euxc 'update-initramfs -u -k all'
$SUDO cp "$CHROOT/boot/vmlinuz-"* "$STAGE/vmlinuz"
$SUDO cp "$CHROOT/boot/initrd.img-"* "$STAGE/initrd.img"
$SUDO chmod 644 "$STAGE/vmlinuz" "$STAGE/initrd.img"

echo "== [6/6] grub-mkrescue (UEFI ISO) =="
$SUDO mkdir -p "$STAGE/boot/grub"
$SUDO tee "$STAGE/boot/grub/grub.cfg" >/dev/null <<EOF
set timeout=5
set default=0
menuentry "NEXORA OS $VERSION (development)" {
  linux /vmlinuz boot=live quiet console=ttyS0,115200 console=tty0
  initrd /initrd.img
}
EOF
$SUDO grub-mkrescue --output="$ISO" "$STAGE" 2>/dev/null
$SUDO chown -R "$(id -un):$(id -gn)" "$BUILD_DIR"

(
  cd "$BUILD_DIR"
  sha256sum "nexora-$VERSION.iso" > "nexora-$VERSION.iso.sha256"
  {
    echo "{"
    echo "  \"image\": \"$ISO\","
    echo "  \"version\": \"$VERSION\","
    echo "  \"debian_release\": \"$RELEASE\","
    echo "  \"arch\": \"$ARCH\","
    echo "  \"build_time\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"commit\": \"$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)\""
    echo "}"
  } > build-metadata.json
)

echo "== done: $ISO =="
ls -l "$ISO"