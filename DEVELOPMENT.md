# NEXORA Development

## How to work on NEXORA

1. Read `AGENTS.md` first — its rules are mandatory.
2. Read `README.md`, `ARCHITECTURE.md`, `BUILD.md`, `TESTING.md`.
3. Follow the task workflow in §76 / §96:

> Inspect → read docs → analyze architecture → implementation plan →
> identify dependencies → implement smallest stable unit → compile →
> unit tests → integration tests → QEMU tests → fix → document → report.

## Workflow

1. Pick a task from the current phase in `ROADMAP.md`.
2. Report **before** implementation (spec §97 format) in the PR/commit body.
3. Implement the smallest stable unit. Keep it compiling and tested.
4. Add tests with the code.
5. Run `make lint`, `make unit`, `make build`, `make qemu` (as applicable).
6. Update `README.md`/`ARCHITECTURE.md`/`ROADMAP.md`/`COMPATIBILITY.md` as
   reality changes.
7. Report **after** implementation (spec §97 format) in the PR/commit body.

## Conventions

- **Languages:** Rust for NEXORA Core and services; C/C++ where required for
  Linux/graphics/ecosystem integration; Python for AI orchestration/tooling;
  QML for UI (Rust backend) (§5).
- **Do not add comments unless asked.** Let code express intent through names.
- Follow the existing style of the file/module you touch.
- Never store API keys or secrets in the repository (§82).
- Do not change repository structure (§75) without documenting the
  architectural reason in `ARCHITECTURE.md`.
- Mark incomplete features `NOT IMPLEMENTED`, `EXPERIMENTAL`, or `PARTIAL`
  with a short note (§77).
- Preserve working code. Do not destroy existing functionality without
  justification.

## Localization rule (§19)

Internationalization exists from day one:
- No user-facing strings hard-coded in application logic.
- Use localization keys.
- Language selection affects installer, login, desktop, settings, file
  manager, notifications, help, recovery, AI, voice, system messages.

## Branch strategy

- Work on a branch per task/phase (e.g. `phase/1-bootable-foundation`).
- Keep commits small and focused. Never commit generated `build/` artifacts
  (see `.gitignore`).

## Reporting issues / PRs

Follow the §97 report blocks so reviews and CI confirmation can be checked
against intent.

## Environment

- The reference development host is Windows (win32) with no Linux/QEMU
  installed; local builds run in CI (Linux) or a Linux environment such as
  WSL2. See `BUILD.md`.
- Never fake success: if something cannot be built on the current machine,
  state it explicitly (§96).