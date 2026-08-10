# NEXORA Security

Security is a first-class, day-one concern (spec §82), not a later phase.
A feature is not complete until it is secure.

## Security architecture principle (§70)

AI and security enforcement are **separate layers**.

```
AI
↓
Security Policy
↓
Trusted Security Subsystem
↓
Enforcement
```

- AI may analyze, explain, recommend, assist.
- Trusted components must enforce, block, isolate, protect.
- **The AI never receives unrestricted root access (§16).**

The system may rely on AI for analysis but never for enforcement alone.

## AI permission model (§16)

Every privileged AI-driven operation:

```
AI request
→ Intent validation
→ Policy engine
→ Permission check
→ User confirmation if required
→ Execution
→ Verification
→ Audit log
```

Sensitive actions require explicit confirmation, including: deleting files,
formatting disks, modifying partitions, modifying the bootloader, installing
drivers, changing firewall/security policies, accessing private folders,
camera, microphone, passwords, and modifying system files.

## Security center components (§32)

- NEXORA Shield
- Anti-malware (built-in; §33) — reputation → signature → heuristic →
  behavior → optional AI analysis → allow/warn/block/quarantine
- Real-time protection (§34)
- Ransomware protection (§35)
- Web protection (§37)
- USB protection (§39)
- Firewall (§38)
- Application sandbox (§36)
- Application reputation
- AI threat analysis (decision support only)
- Privacy protection
- Secure updates
- Quarantine (§40)
- Security monitor, audit logs

## Platform security (§43, §44)

Architecture support target for:

- UEFI Secure Boot, TPM 2.0, encrypted storage, measured boot where practical,
  hardware-backed credentials, signed packages/updates
- Passkeys, TPM-backed credentials, PIN, fingerprint, face authentication,
  hardware security keys

## Anti-tamper (§41)

Security components must resist unauthorized modification. Malware must not
easily disable antivirus, firewall, sandbox, security policy, or update
security.

## Privacy (§42, §94)

- NEXORA Privacy Center: camera, microphone, screen capture, file access,
  location, network access, AI access, clipboard access usage; user can revoke.
- Defaults: local processing where practical, minimal data collection,
  explicit permission, transparent logs, encrypted sensitive data.
- **No hidden AI recording, no hidden screen recording, no hidden telemetry.**
- BTRFS snapshots + rollback protect data during updates (§22, §45).
- Self-healing (NEXORA AutoRecover, §46): failures → diagnostics → AI
  analysis → snapshot/repair → verification → boot. AI never makes dangerous
  irreversible changes without required authorization.

## Development security (§82)

Every feature considers: authentication, authorization, input validation,
sandboxing, least privilege, secrets handling, logging, encryption, dependency
security, update security.

- **Never store API keys or secrets in source code.**
- Never bypass security or licensing restrictions.
- Never disable security to pass tests (§77).

## Reporting

Security issues should be reported privately (details to be confirmed once a
security contact is established). Do **not** open public security issues.