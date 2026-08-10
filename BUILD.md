# Building NEXORA

This document describes how to obtain a build environment and produce a
NEXORA development image.

> **Host requirements:** building a Linux image requires a Linux environment
> (or a Linux CI runner). The current development host note is recorded below.

## Current status

**Phase 0.** The repository defines the structure, tooling, and CI for
building the first success criterion (a reproducible NEXORA development image
that boots under UEFI in QEMU, §99).

State of the build chain:

| Stage | Tooling | Status |
|-------|---------|--------|
| Image assembly | Debian-based rootfs via `debootstrap`, XORRISO ISO, GRUB EFI | PARTIAL — designed, CI-ready |
| ISO production | `scripts/build-iso.sh` | PARTIAL |
| QEMU boot test | `scripts/run-qemu.sh` (UEFI via OVMF) | PARTIAL |
| Minimal NEXORA kernel/runtime image | — | NOT IMPLEMENTED (Phase 1) |

Nothing is claimed complete until it boot-tests (§77).

## Host prerequisites (Linux or CI runner)

```
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y \
    build-essential make git \
    debootstrap xorriso \
    qemu-system-x86 ovmf \
    squashfs-tools dosfstools
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

## Building on Windows

A Linux environment is required for image/USB production. On a Windows host
use one of:

1. **GitHub Actions CI** (primary path; `.github/workflows/ci.yml`) —
   `git push` triggers lint → unit tests → build → ISO → QEMU boot gate →
   artifacts.
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