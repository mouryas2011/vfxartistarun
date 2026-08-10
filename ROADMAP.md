# NEXORA Roadmap

## Release phases (spec §89)

| Phase | Deliverable | Status |
|-------|-------------|--------|
| Phase 0 | Architecture, repository, CI, documentation | **IN PROGRESS** |
| Phase 1 | Bootable Linux foundation (UEFI boot in QEMU) | pending |
| Phase 2 | Wayland + graphical desktop | pending |
| Phase 3 | NEXORA Shell + Files + Settings | pending |
| Phase 4 | Installer + Recovery | pending |
| Phase 5 | Package Manager + NEXORA Store | pending |
| Phase 6 | Security + NEXORA Shield | pending |
| Phase 7 | AI Foundation | pending |
| Phase 8 | AI Desktop Integration | pending |
| Phase 9 | NSOL + NEXORA AIP | pending |
| Phase 10 | Windows Compatibility | pending |
| Phase 11 | KVM/QEMU VM Manager | pending |
| Phase 12 | Gaming | pending |
| Phase 13 | Cross-device Connect | pending |
| Phase 14 | Mobile/Tablet | pending |
| Phase 15 | Developer SDK | pending |
| Phase 16 | Enterprise | pending |
| Phase 17 | Hardware certification | pending |
| Phase 18 | Production Release | pending |

## Version strategy (spec §90)

| Version | Milestone |
|---------|-----------|
| 0.1 | Bootable developer release |
| 0.5 | Usable graphical desktop |
| 0.7 | Installer + applications + security |
| 0.8 | AI platform |
| 0.9 | Compatibility + recovery |
| 1.0 | Stable Desktop |
| 1.5 | Mobile/Tablet |
| 2.0 | Full cross-device NEXORA ecosystem |

## Principles

- Work phase-by-phase; never build the whole OS blindly in one generation (§76).
- Do not implement advanced features before foundational dependencies exist (§96).
- A phase gate passes only when its features are
  **IMPLEMENTED + TESTED + DOCUMENTED + SECURE + USABLE** (§100).

## Phase 1 gate (first success criterion, §99)

A reproducible NEXORA development image that:

1. Builds successfully.
2. Produces a bootable ISO/image.
3. Boots under UEFI.
4. Boots successfully in QEMU.
5. Reaches the initial NEXORA graphical foundation when implemented.
6. Produces logs.
7. Has automated tests.
8. Can be rebuilt from documented instructions.

## NEXORA 1.0 must-have scope (spec §91)

UEFI boot, Linux foundation, GUI, desktop, login, file manager, settings,
network, audio, Bluetooth, USB, multi-monitor, application installation,
software center, updates, recovery, snapshots, security center, built-in
anti-malware architecture, firewall, application sandbox, privacy center,
local AI, cloud AI abstraction, AI permissions, voice AI, semantic search,
NSOL foundation, multilingual framework, Linux app support, Windows
compatibility foundation, VM support, developer tools, basic gaming support,
offline operation, easy installer, recovery environment.

## Explicitly NOT V1 (spec §92)

Universal iOS compatibility, full XR, production RISC-V, robotics, custom
kernel, custom browser engine, custom GPU driver ecosystem, training a
foundation AI model from scratch, universal Windows compatibility. Architecture
stays extensible in these areas instead.