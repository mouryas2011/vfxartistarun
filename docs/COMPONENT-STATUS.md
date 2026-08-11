# NEXORA component status register

For every feature we record current status (§77). A feature is not claimed
until it is **IMPLEMENTED + TESTED + DOCUMENTED + SECURE + USABLE** (§100).
Incomplete features are marked explicitly. This register is updated as phases
progress.

## Phase 0 — Foundation (CURRENT)

| Component | Status | Notes |
|-----------|--------|-------|
| Documentation suite | IMPLEMENTED + TESTED | README/AGENTS/ARCHITECTURE/ROADMAP/SECURITY/BUILD/TESTING/COMPATIBILITY/DEVELOPMENT; asserted by `tests/unit/test_configs.sh` |
| Repository structure (§75) | IMPLEMENTED + TESTED | 65 leaf dirs; asserted by unit tests |
| Build tooling (Makefile, scripts) | IMPLEMENTED + PARTIAL | Scripts written and lint-ready; required to run on Linux/CI |
| Lint (shellcheck + JSON + no-secrets) | IMPLEMENTED + TESTED | runs in CI |
| Unit tests | IMPLEMENTED + TESTED | repository invariants |
| Integration tests (ISO shape) | IMPLEMENTED + TESTED | runs after `make build` |
| CI pipeline (lint→unit→build→ISO→QEMU gate) | IMPLEMENTED | `.github/workflows/ci.yml`; execution requires GitHub push |
| Windows dev-host wrapper | IMPLEMENTED | honestly reports inability to run QEMU on this host (§77) |

## Phase 1 — Bootable Linux foundation (DONE, CI-green)

| Component | Status | Notes |
|-----------|--------|-------|
| Linux rootfs via debootstrap | IMPLEMENTED + TESTED | CI-green |
| Kernel + initramfs (live-boot) | IMPLEMENTED + TESTED | CI-green; virtio drivers pinned in initramfs for QEMU |
| UEFI bootable ISO (grub-mkrescue) | IMPLEMENTED + TESTED | `/live/vmlinuz` + `/live/initrd.img` + `/live/filesystem.squashfs` |
| QEMU UEFI boot gate | IMPLEMENTED + TESTED | OVMF via pflash; marker reached in CI |
| NEXORA boot marker / log | IMPLEMENTED + TESTED | `nexora-boot.service` writes `NEXORA_BOOT_MARKER` to ttyS0 |

## Phase 2 — Installer (IN PROGRESS)

| Component | Status | Notes |
|-----------|--------|-------|
| Real installer (`scripts/install-system.sh`) | IMPLEMENTED + TESTED | GPT (ESP + ext4 root), unsquashfs, fstab by UUID, GRUB EFI `--removable`; auto mode via `nexora.install=`; interactive + `--yes` modes |
| Auto-install service | IMPLEMENTED + TESTED | `nexora-install.service`, `ConditionKernelCommandLine=nexora.install`, powers off when done |
| QEMU install gate (`scripts/run-qemu-install.sh`) | IMPLEMENTED + TESTED | install to scratch virtio disk + reboot installed disk under OVMF; both markers reached in CI |
| Real hardware install | NOT TESTED | requires physical machine; installer flow documented in BUILD.md |

## Later phases (§89)

All Phase 2+ components (Wayland desktop, NEXORA Shell, Files, Settings,
Recovery, Store, Security/Shield, AI, NSOL/AIP, Windows compatibility, VM
manager, Gaming, Connect, Mobile/Tablet, SDK, Enterprise) are **NOT
IMPLEMENTED** until their phase begins. See `ROADMAP.md`.