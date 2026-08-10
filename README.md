# NEXORA OS

> **One OS. Multiple Worlds.**

**The AI-Native Operating System** — Built in India. Designed for the World.

NEXORA is a real, bootable, installable, graphical operating system based on
mature open-source foundations (Linux, systemd, Wayland, PipeWire, Mesa)
enhanced with a proprietary NEXORA technology layer:

- **NEXORA Core** — system services, permissions, policies, security
- **NEXORA AI** — local / cloud / hybrid AI with NPU-aware scheduling
- **NSOL** — NEXORA Semantic OS Layer
- **NEXORA AIP** — the NEXORA AI Interaction Protocol
- **NEXORA Shield** — built-in security (anti-malware, firewall, sandbox)
- **NEXORA Connect** — phone ↔ PC continuity
- **NEXORA SDK** — application developer platform

This is **not** a UI mockup, a browser-based desktop, or a Linux theme.
It is a software platform built incrementally, verified at every stage.

---

## Status

**Phase 0 — Architecture, repository, CI, documentation**

The current repository contains the master engineering foundation, repository
structure, build tooling, and CI pipeline. No feature is claimed to be
implemented until it is built, tested, documented, secured, and usable
(spec §100).

Every incomplete feature is explicitly marked `NOT IMPLEMENTED`,
`EXPERIMENTAL`, or `PARTIAL` (§77). We never fake functionality.

## Current Phase / Version

| Scope | Value |
|-------|-------|
| Current phase | Phase 0 (§89) |
| Target version | 0.1 — bootable developer release (§90) |
| First success criterion | Reproducible dev image: builds → bootable ISO → UEFI boot → boots in QEMU (§99) |

## Quick start for contributors

Read, in order: `AGENTS.md` → `ARCHITECTURE.md` → `BUILD.md` → `DEVELOPMENT.md`.

```
git clone <repo>
cd nexora-os
make bootstrap    # installs host build prerequisites (Linux/CI)
make build        # builds the NEXORA development image
make test         # runs unit + integration tests
make qemu         # boots the image in QEMU (UEFI)
```

Detailed instructions: [BUILD.md](BUILD.md), [TESTING.md](TESTING.md).

## Documentation index

| Document | Purpose |
|----------|---------|
| [AGENTS.md](AGENTS.md) | Mandatory rules for AI coding agents |
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture and design |
| [ROADMAP.md](ROADMAP.md) | Phased release roadmap |
| [SECURITY.md](SECURITY.md) | Security model and requirements |
| [BUILD.md](BUILD.md) | Build system and prerequisites |
| [TESTING.md](TESTING.md) | Testing strategy and requirements |
| [COMPATIBILITY.md](COMPATIBILITY.md) | Compatibility claims and matrix |
| [DEVELOPMENT.md](DEVELOPMENT.md) | Development workflow and conventions |

## License and third-party

All third-party integrations must comply with spec §84 (licensing review)
and third-party license notices are maintained under `docs/`.

See [SECURITY.md](SECURITY.md) and [COMPATIBILITY.md](COMPATIBILITY.md) for
honest, evidence-backed claims. NEXORA does not claim "100% compatibility",
"virus-proof", or "unhackable".