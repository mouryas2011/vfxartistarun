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

## Phase 1 — Bootable Linux foundation (NEXT)

| Component | Status | Notes |
|-----------|--------|-------|
| Linux rootfs via debootstrap | PARTIAL | scripted; not yet executed on a Linux host |
| Kernel + initramfs (live-boot) | PARTIAL | scripted; not yet executed |
| UEFI bootable ISO (grub-mkrescue) | PARTIAL | scripted; not yet executed |
| QEMU UEFI boot gate | PARTIAL | scripted; requires Linux/QEMU host |
| NEXORA boot marker / log | PARTIAL | `nexora-boot.service`; not yet executed |
| Graphical foundation | NOT IMPLEMENTED | Phase 2 (Wayland) |

## Later phases (§89)

All Phase 2+ components (Wayland desktop, NEXORA Shell, Files, Settings,
Installer, Recovery, Store, Security/Shield, AI, NSOL/AIP, Windows
compatibility, VM manager, Gaming, Connect, Mobile/Tablet, SDK, Enterprise)
are **NOT IMPLEMENTED** until their phase begins. See `ROADMAP.md`.