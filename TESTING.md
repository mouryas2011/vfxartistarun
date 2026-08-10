# NEXORA Testing

## Principle (spec §78, §100)

A feature is complete only when:
**IMPLEMENTED + TESTED + DOCUMENTED + SECURE + USABLE**.

Every feature must have automated tests before it is marked complete.
We never remove tests to make CI pass, and never disable security to make
tests pass (§77).

## Test types

| Type | Scope | Entry point |
|------|-------|-------------|
| Unit | repository-local code (scripts, configs, Rust crates as they appear) | `make unit` |
| Lint | shell scripts (`shellcheck`), config validation, formatting | `make lint` |
| Integration | image assembly, rootfs, boot config consistency | `make test` / `make integration` |
| QEMU boot | UEFI boot of the produced ISO in QEMU; PASS = reaching login/init target and emitting logs | `make qemu` / `make qemu-serial` |
| Hardware | real-hardware boot matrix (maintained in `COMPATIBILITY.md`) | manual, documented |

## Required coverage areas (§78)

Boot, kernel, filesystem, storage, networking, audio, Bluetooth, GUI,
installer, recovery, updates, security, antivirus, firewall, sandbox, AI,
permissions, semantic layer (NSOL/AIP), package manager, Windows
compatibility, virtualization, localization, cross-device communication.

These are added incrementally as their phases arrive — **not** all today.
A feature must not be marked complete without its tests.

## QEMU testing (§79)

`scripts/run-qemu.sh` must support:

- UEFI firmware (OVMF)
- configurable RAM (`-m`)
- configurable CPU (`-cpu`, KVM or TCG)
- ISO boot and/or disk image
- debug logs and serial output capture

Minimum Phase 1 gate: **NEXORA must successfully boot in QEMU before Phase 1
is claimed** (§79, §99).

Windows convenience wrapper: `scripts/run-qemu.ps1` (requires `wsl`, a VM,
or CI; QEMU itself is not installed on the reference dev host — see BUILD.md).

## CI pipeline (§81)

`git push` → lint → unit tests → security checks → integration tests →
build → ISO generation → QEMU boot test → artifacts (`.github/workflows/ci.yml`).

Generated artifacts: ISO, SHA256 checksum, build metadata, SBOM where
practical.

## Passing a phase gate

1. Implementation exists (no placeholders presented as real, §77).
2. Unit tests pass.
3. Integration tests pass.
4. QEMU boot test passes for bootable deliverables.
5. Documentation updated.
6. Security review notes recorded (see SECURITY.md).
7. Status reported in §97 format.