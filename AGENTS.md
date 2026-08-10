# AGENTS.md — Rules for AI Coding Agents

These rules are **mandatory** for any AI coding agent (or human) modifying this
repository. They derive from the Master Engineering Specification (§76, §77,
§96, §97, §98, §99).

---

## 1. Read before you act

For **every** task:

1. Inspect the repository.
2. Read the relevant documentation (`README.md`, `ARCHITECTURE.md`,
   `BUILD.md`, `DEVELOPMENT.md`, etc.).
3. Analyze the current architecture.
4. Create an implementation plan.
5. Identify dependencies.
6. Implement the **smallest stable unit**.
7. Compile / build.
8. Run unit tests.
9. Run integration tests.
10. Run QEMU tests where applicable.
11. Fix errors.
12. Update documentation.
13. Report status (spec §97 format).
14. Only then proceed.

## 2. Development rules

- Work **phase-by-phase**. Never build the whole OS blindly in one generation.
- Do **not** implement advanced features before foundational dependencies
  exist (e.g. no AI desktop integration before a working graphical session).
- Preserve working code. Do not destroy existing functionality without
  justification.
- Minimize unnecessary dependencies. Reuse mature open-source technologies.
- Follow existing code conventions and style. Do not add comments unless asked.
- Never store API keys or secrets in source code (§82).

## 3. No fake implementation (§77)

**NEVER:**

- create fake APIs or fake OS behavior
- simulate installation while claiming it is real
- create placeholder security presented as production security
- claim Windows/Android/antivirus/hardware compatibility without testing
- hide compilation errors
- disable security to make tests pass
- remove tests to make CI pass

If a feature is incomplete, explicitly mark it:

```
NOT IMPLEMENTED
EXPERIMENTAL
PARTIAL
```

with a short note describing exactly what is and is not done.

## 4. AI engineering rules (§96)

- The AI agent must never be given unrestricted root/system access by the
  product design (§70). This refers to the OS's own AI, not the build agent.
- The build agent must never bypass security or licensing restrictions.
- Write tests for new code. Run builds. Run QEMU tests. Document changes.
- Never fake success. If something cannot be built on this machine, say so.

## 5. Testing rules

- Every feature must have tests before it is marked complete (§78, §100).
- A feature is complete only when: **IMPLEMENTED + TESTED + DOCUMENTED +
  SECURE + USABLE**.
- Minimum Phase 1 gate: the image boots successfully under UEFI in QEMU.

## 6. Task report format (§97)

**Before implementation:**

```
CURRENT PHASE:
CURRENT TASK:
OBJECTIVE:
FILES TO CHANGE:
DEPENDENCIES:
RISKS:
TEST PLAN:
```

**After implementation:**

```
IMPLEMENTED:
FILES CHANGED:
BUILD STATUS:
TEST RESULTS:
QEMU STATUS:
SECURITY STATUS:
KNOWN LIMITATIONS:
NEXT TASK:
```

## 7. Directory structure rule

Do not change the repository structure (spec §75) without documenting the
architectural reason in `ARCHITECTURE.md`.

## 8. First objective (§98, §99)

The first success criterion of this repository is a **reproducible NEXORA
development image** that:

1. Builds successfully.
2. Produces a bootable ISO/image.
3. Boots under UEFI.
4. Boots successfully in QEMU.
5. Reaches the initial NEXORA graphical foundation when the phase is
   implemented.
6. Produces logs.
7. Has automated tests.
8. Can be rebuilt from documented instructions.