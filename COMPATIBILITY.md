# NEXORA Compatibility

> NEXORA does not claim unsupported compatibility. Compatibility is only
> claimed after it has been tested (§77, §87).

## Application support goals (§23)

Targeted support architecture for:

- Native Linux applications
- Flatpak
- AppImage
- Distribution packages
- NEXORA packages (`.nexa`, §24)
- Windows applications (via Wine/Proton through NEXORA Compatibility
  Manager, §26)
- Android applications (via legitimate runtime/container technologies; §28;
  bypassing proprietary protections is prohibited)
- Web/PWA applications
- Virtual-machine applications

**Not claimed:** "100% Windows compatibility" or "universal iOS app
compatibility" (§26, §29, §92).

## Windows compatibility stage pipeline (design, §26)

```
EXE/MSI → Analyzer → Compatibility database → Wine/Proton → Run
If compatibility fails → VM fallback
```

Current status: `NOT IMPLEMENTED` (Phase 10). No compatibility is claimed.

## The compatibility matrix

Hardware and software compatibility is recorded in a maintained matrix.
Real-hardware testing is required before any hardware support claim (§80).

Matrix columns (to be populated as testing happens):

- Component (CPU/GPU/NPU/RAM/storage/display/Wi-Fi/Bluetooth/USB/audio)
- Make/model
- Driver / configuration
- Tested by / date
- Result (boot / full / partial / fails)
- Notes

Current status: empty — **no hardware compatibility is claimed yet**.

## Devices and architectures (§3)

Devices: NEXORA Desktop (PC/laptop), NEXORA Mobile (smartphone, foldable),
NEXORA Tablet, future NEXORA XR.

Architectures: x86_64 first; ARM64 next; future RISC-V (§73).

Current status: only x86_64 is targeted for Phase 1. Nothing ships for other
architectures.

## Honest-marketing clauses (§87)

Never claim, without evidence:

- "first in the world", "first in India"
- "100% Windows compatibility"
- "100% iOS compatibility"
- "virus-proof", "unhackable"

## Third-party licensing (§84)

Before integrating third-party technology: verify license, redistribution and
modification rights, trademark restrictions, patent considerations, and
compatibility with NEXORA's distribution model. Maintain third-party license
notices under `docs/`. Never include proprietary software illegally.