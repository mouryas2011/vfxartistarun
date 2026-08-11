# Building NEXORA

This document describes how to obtain a build environment and produce a
NEXORA development image.

> **Host requirements:** building a Linux image requires a Linux environment
> (or a Linux CI runner). The current development host note is recorded below.

## Current status

**Phase 1 complete — Phase 2 (installer) in progress.**

Phase 1 success criteria are met: a reproducible NEXORA development image is
built and verified to boot under UEFI in QEMU (CI-green). Phase 2 adds a real
installer: a machine can be installed to a disk from the live medium and the
installed system verified to boot on its own.

State of the build chain:

| Stage | Tooling | Status |
|-------|---------|--------|
| Image assembly | Debian-based rootfs via `debootstrap`, XORRISO ISO, GRUB EFI | DONE — CI-green |
| ISO production | `scripts/build-iso.sh` | DONE |
| QEMU boot test | `scripts/run-qemu.sh` (UEFI via OVMF) | DONE |
| Installer | `scripts/install-system.sh` (+ `nexora-install.service`) | DONE — gate green |
| QEMU install test | `scripts/run-qemu-install.sh` | DONE — gate green |
| Real hardware install | manual, not yet exercised on physical hardware | NOT TESTED |

Nothing is claimed complete until it boot-tests (§77).

## Host prerequisites (Linux or CI runner)

```
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y \
    build-essential make git \
    debootstrap xorriso \
    qemu-system-x86 ovmf qemu-utils \
    squashfs-tools dosfstools mtools
```

## Build steps

```
make bootstrap     # verify/install host prerequisites
make lint          # lint all scripts (shellcheck) and configs
make unit          # run unit tests for repository-local code
make build         # produce build/nexora-<version>.iso
make test          # run full automated test suite
make qemu          # boot the ISO in QEMU under UEFI (interactive)
make qemu-serial   # boot headless, capture serial logs to build/qemu-serial.log
make qemu-install  # install ISO to a scratch disk and boot the installed system
make install       # alias for qemu-install
make clean
```

## Make targets

Run `make help` for the full, current target list.

## What the build produces

- `build/` — all intermediate artifacts
- `build/nexora-<version>.iso` — bootable UEFI ISO
- `build/nexora-<version>.sha256` — checksum
- `build/build-metadata.json` — inputs, commit, tool versions, timestamps
- `build/qemu-serial.log` — serial console log from the QEMU boot test
- `build/qemu-install.log` / `build/qemu-installed-boot.log` — logs from the
  installer gate

## Reproducibility

- Pinned base image components via a lockfile (`packaging/lock/`).
- `build-metadata.json` records exact inputs for every build.
- CI builds the same way as `make build`.
- Rebuildable from these documented instructions only.

## QEMU boot test (Phase 1 gate)

```
make qemu-serial
# PASS = serial log contains early boot output and reaches the login
#        prompt / init target without crash.
```

Exit code non-zero on timeout or crash. See `TESTING.md`.

## Installer (Phase 2 gate)

```
make qemu-install
```

Two phases:

1. **Install:** boots the live ISO in QEMU with a scratch disk, passing
   `nexora.install=/dev/vda` on the kernel command line. The
   `nexora-install.service` runs `nexora-install.sh` (installed in the live
   rootfs as `/usr/sbin/nexora-install.sh`): wipes the disk, creates a GPT
   layout (512 MiB FAT32 ESP + ext4 root), unpacks `filesystem.squashfs`,
   writes `/etc/fstab` by UUID, installs GRUB EFI (with `--removable` so the
   ESP's `EFI/BOOT/BOOTX64.EFI` fallback path is present), re-enables the boot
   marker, then powers off.
2. **Boot installed system:** reboots from the installed disk under OVMF and
   requires `NEXORA_BOOT_MARKER` in the serial log, proving the installed
   system boots on its own.

PASS = both phases reach their markers (`NEXORA INSTALL OK` then
`NEXORA_BOOT_MARKER`). The scratch disk is `build/install-disk.img`.

Installing on real hardware follows the same flow: boot the ISO, then either
run `nexora-install /dev/sdX` interactively (types YES to confirm), use
`nexora-install --yes /dev/sdX`, or add `nexora.install=/dev/sdX` to the
kernel command line for automatic install + poweroff. **The target disk is
wiped.**

## Building on Windows

A Linux environment is required for image/USB production. On a Windows host
use one of:

1. **GitHub Actions CI** (primary path; `.github/workflows/ci.yml`) —
   `git push` triggers lint → unit tests → build → ISO → QEMU boot gate →
   installer gate → artifacts.
2. **WSL2** — install WSL2 + an Ubuntu distro and run all `make` targets inside.
3. A Linux VM / remote Linux builder.

USB creation from a Windows/macOS host is a development tool (NEXORA USB
Creator, §50); it is `NOT IMPLEMENTED` at this time.

## Troubleshooting

- Missing `shellcheck` → run `make bootstrap` or install it manually.
- QEMU "no bootable device" → ensure `ovmf` package is installed so UEFI
  firmware is available.
- QEMU requires virtualization or software emulation; ensure nested virt is
  available in the CI runner (KVM) or fall back to TCG acceleration.