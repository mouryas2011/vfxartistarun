#!/usr/bin/env bash
# NEXORA installer — install the running live system to a target disk.
#
# Runs inside the NEXORA live environment (booted from the development ISO)
# as root. It creates a GPT layout (ESP + ext4 root), copies the live
# filesystem, writes /etc/fstab, and installs GRUB (EFI).
#
# Usage:
#   nexora-install /dev/sdX            # interactive (asks for confirmation)
#   nexora-install --yes /dev/sdX      # unattended (CI / scripted use)
#
# When invoked with no arguments, the target disk is read from the kernel
# command line parameter nexora.install=/dev/sdX. In unattended mode the
# machine powers off automatically after a successful install.
#
# NOTE: the target disk is WIPED. This is a real installer, not a simulation.

set -euo pipefail

EUID_IS_ROOT=0
if [[ $EUID -eq 0 ]]; then EUID_IS_ROOT=1; fi

usage() {
  echo "Usage: nexora-install [--yes] /dev/sdX" >&2
  echo "  --yes   unattended; no confirmation prompt (CI/scripted)" >&2
  exit 1
}

if [[ $EUID_IS_ROOT -ne 1 ]]; then
  echo "ERROR: installer must run as root." >&2
  exit 1
fi

YES=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --yes) YES=1 ;;
    /dev/*) TARGET="$arg" ;;
    -h|--help) usage ;;
    *) echo "unknown argument: $arg" >&2; usage ;;
  esac
done

AUTO=0
if [[ -z "$TARGET" ]] && [[ -r /proc/cmdline ]]; then
  CMD="$(tr ' ' '\n' < /proc/cmdline)"
  TARGET="$(printf '%s\n' "$CMD" | sed -n 's/^nexora.install=//p' | head -1)"
  if [[ -n "$TARGET" ]]; then
    AUTO=1
    YES=1
    echo "Auto-install target from kernel cmdline: $TARGET"
  fi
fi

if [[ -z "$TARGET" ]]; then
  echo "ERROR: no target disk given. Installer will not guess." >&2
  echo "Detected disks:" >&2
  lsblk -dpno NAME,SIZE,MODEL 2>/dev/null || true
  usage
fi

if [[ ! -b "$TARGET" ]]; then
  echo "ERROR: $TARGET is not a block device." >&2
  exit 1
fi

echo "== NEXORA installer =="
echo "  target disk : $TARGET  (ALL DATA WILL BE DESTROYED)"
echo "  source      : running live system"
echo "  layout      : GPT (ESP 512MiB FAT32 + ext4 root)"
echo "  bootloader  : GRUB 2 (EFI, x86_64)"

if [[ $YES -ne 1 ]]; then
  echo "Type YES to continue:"
  read -r CONFIRM
  if [[ "$CONFIRM" != "YES" ]]; then
    echo "Install aborted." >&2
    exit 1
  fi
fi

SQUASHFS=""
for p in \
  /run/live/medium/live/filesystem.squashfs \
  /lib/live/mount/medium/live/filesystem.squashfs \
  /media/live/live/filesystem.squashfs; do
  if [[ -f "$p" ]]; then SQUASHFS="$p"; break; fi
done
if [[ -z "$SQUASHFS" ]]; then
  SQUASHFS="$(find / -maxdepth 6 -name filesystem.squashfs 2>/dev/null | head -1 || true)"
fi
if [[ -z "$SQUASHFS" ]]; then
  echo "ERROR: filesystem.squashfs not found. Run from the live medium." >&2
  exit 1
fi
echo "  live rootfs : $SQUASHFS"

for tool in parted partprobe mkfs.vfat mkfs.ext4 blkid unsquashfs grub-install; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: missing required tool: $tool" >&2
    exit 1
  fi
done

echo "== wiping $TARGET =="
wipefs -a "$TARGET"

echo "== partitioning (GPT) =="
parted -s "$TARGET" mklabel gpt
parted -s "$TARGET" mkpart ESP fat32 1MiB 513MiB
parted -s "$TARGET" set 1 esp on
parted -s "$TARGET" mkpart NEXORA ext4 513MiB 100%
partprobe "$TARGET" || true
sleep 2

ESP="${TARGET}1"
ROOT="${TARGET}2"
[[ -b "$ESP" ]] || { echo "ERROR: $ESP was not created." >&2; exit 1; }
[[ -b "$ROOT" ]] || { echo "ERROR: $ROOT was not created." >&2; exit 1; }

echo "== formatting =="
mkfs.vfat -F 32 -n NEXORA_ESP "$ESP"
mkfs.ext4 -F -L NEXORA_ROOT "$ROOT"

echo "== installing rootfs =="
MNT="$(mktemp -d)"
trap 'umount -R "$MNT" 2>/dev/null || true; rm -rf "$MNT"' EXIT
mount "$ROOT" "$MNT"
mkdir -p "$MNT/boot/efi"
mount "$ESP" "$MNT/boot/efi"

unsquashfs -f -d "$MNT" "$SQUASHFS"

ROOT_UUID="$(blkid -s UUID -o value "$ROOT")"
ESP_UUID="$(blkid -s UUID -o value "$ESP")"
if [[ -z "$ROOT_UUID" || -z "$ESP_UUID" ]]; then
  echo "ERROR: could not read filesystem UUIDs." >&2
  exit 1
fi

cat > "$MNT/etc/fstab" <<EOF
UUID=$ROOT_UUID / ext4 errors=remount-ro 0 1
UUID=$ESP_UUID /boot/efi vfat umask=0077 0 1
EOF

echo "== preparing chroot =="
for d in /dev /proc /sys; do
  mount --bind "$d" "$MNT$d"
done
mount -t devpts devpts "$MNT/dev/pts" 2>/dev/null || true

echo "== bootloader (GRUB EFI) =="
cat > "$MNT/etc/default/grub" <<'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_CMDLINE_LINUX="console=ttyS0,115200 console=tty0"
EOF
chroot "$MNT" /bin/bash -euxc '
set -e
grub-install --target=x86_64-efi --efi-directory=/boot/efi \
  --bootloader-id=NEXORA --removable --recheck
update-grub
'

echo "== finalize installed system =="
chroot "$MNT" systemctl enable nexora-boot.service 2>/dev/null || true
if command -v ssh-keygen >/dev/null 2>&1; then
  chroot "$MNT" ssh-keygen -A 2>/dev/null || true
fi

echo "== installed /etc/fstab =="
cat "$MNT/etc/fstab"

sync
umount -R "$MNT"
rm -rf "$MNT"
trap - EXIT

echo "== NEXORA INSTALL OK: $TARGET =="
printf 'NEXORA INSTALL OK target=%s\n' "$TARGET" > /dev/ttyS0 2>/dev/null || true

if [[ $AUTO -eq 1 ]]; then
  echo "Auto-install finished; powering off."
  sync
  systemctl poweroff -f || true
fi
