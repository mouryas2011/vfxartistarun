# NEXORA Architecture

NEXORA is an AI-native operating system. It is built on a mature Linux
foundation with a proprietary technology layer above it (spec §4, §9).

## Architectural principle

Traditional:

```
User → Applications → Operating System → Hardware
```

NEXORA:

```
User
↓
NEXORA AI
↓
NEXORA Semantic OS (NSOL)
↓
NEXORA Core
↓
Applications + Hardware + Network + Cloud
↓
Hardware
```

> **The computer should understand what the user wants, not merely execute
> low-level commands.**

## Ecosystem view (spec §101)

```
                NEXORA ECOSYSTEM
                       │
    ┌──────────────────┼──────────────────┐
    │                  │                  │
  DESKTOP            MOBILE             TABLET
    │                  │                  │
    └──────────────────┼──────────────────┘
                       │
                NEXORA EXPERIENCE
                       │
  ┌────────────────────┼────────────────────┐
  │                    │                    │
 GUI                 NEXORA AI          APP PLATFORM
  │                    │                    │
  │               Local/Cloud/Hybrid       │
  │                    │                    │
  └────────────────────┼────────────────────┘
                       │
                NSOL / NEXORA AIP
                       │
                NEXORA CORE
                       │
   ┌───────────────────┼────────────────────┐
   │                   │                    │
Security          Compatibility         Hardware
   │                   │                    │
Shield/AV          Linux/Windows/        HAL/NPU/
Firewall           Android/Web/VM        GPU/CPU
│                   │                    │
└───────────────────┼────────────────────┘
│
Linux Kernel
│
Hardware
```

## Layer stack (spec §9)

```
Hardware
↓
Linux Kernel
↓
NEXORA HAL            hardware detection and abstraction (§10)
↓
NEXORA Core           state, services, IPC, permissions, policies (§9)
↓
NEXORA Services
↓
NEXORA UI / AI / Apps
```

## Foundation choices (spec §4)

| Concern | Technology | Status |
|---------|-----------|--------|
| Kernel | Linux | PARTIAL — Phase 1 |
| Boot | UEFI | PARTIAL — Phase 1 |
| Bootloader | GRUB or systemd-boot (TBD by engineering) | PARTIAL — Phase 1 |
| Init system | systemd | PARTIAL — Phase 1 |
| Graphics | Wayland compositor | NOT IMPLEMENTED — Phase 2 |
| Audio | PipeWire | NOT IMPLEMENTED |
| Graphics stack | Mesa + Vulkan | NOT IMPLEMENTED |
| IPC | D-Bus | NOT IMPLEMENTED |
| Virtualization | KVM + QEMU | NOT IMPLEMENTED — Phase 11 |
| Windows compatibility | Wine / Proton | NOT IMPLEMENTED — Phase 10 |
| Containers | OCI-compatible | NOT IMPLEMENTED |
| Filesystem | BTRFS (snapshots/rollback) | PARTIAL — Phase 1 |

NEXORA's differentiation lives **above** the Linux foundation.

## Core design components

### NEXORA Core
- system state, services, hardware, IPC, permissions, policies,
  application management, security, device management, user sessions.
- Primary language: **Rust**.

### NEXORA HAL
- Detects CPU, GPU, NPU, RAM, storage, display, input, camera, microphone,
  audio, network, USB, printer, battery, thermals, biometrics.
- Degrades gracefully when hardware is unavailable (§10).

### NEXORA AI platform (§11)
- AI Interface → AI Orchestrator → Planner → Policy/Permission Engine →
  Tools → NEXORA Core → Verification → Result.
- Local / Cloud / Hybrid modes (§12), provider-abstracted, no single vendor.
- NPU/GPU/CPU scheduler with fallbacks (§13).

### NSOL — NEXORA Semantic OS Layer (§14)
- Applications expose semantic capabilities (`create_document()`,
  `save_document()`, `play()`, `send()`, …).
- AI acts through capabilities + permissions, not unrestricted screen control.

### NEXORA AIP (§15)
- Standardized, permission-controlled protocol between applications and AI.
- Extensible and documented for third parties.

### Security architecture (§70)
- AI and security enforcement are **separate**.
- AI may analyze/explain/recommend/assist. Trusted components
  enforce/block/isolate/protect.
- AI never receives unrestricted root access (§16).

## Repository structure (spec §75)

Defined in the file tree at the repository root. Any change to this structure
must be justified architecturally and documented in this file.

## Platform strategy

- One common core/API; device-specific experiences (Desktop, Mobile, Tablet,
  future XR, §8).
- Development priority: x86_64 Desktop → ARM64 → Tablet → Mobile → Foldable →
  XR → RISC-V (§3).
- RISC-V must be addable without rewriting NEXORA Core (§73).

## Design goals

STABILITY · SECURITY · PERFORMANCE · USER EXPERIENCE · COMPATIBILITY ·
PRIVACY · MAINTAINABILITY · OPENNESS · RELIABILITY (§100).

A feature is complete only when **IMPLEMENTED + TESTED + DOCUMENTED +
SECURE + USABLE**.