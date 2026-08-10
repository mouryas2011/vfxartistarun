# NEXORA QEMU boot test — Windows convenience wrapper.
#
# QEMU and a Linux build environment are NOT available on this Windows host.
# This wrapper exists to fail honestly with guidance instead of pretending to
# run the QEMU suite (§77, §96). Preferred paths:
#   1. GitHub Actions CI (.github/workflows/ci.yml) — runs the QEMU gate on push.
#   2. WSL2 — install WSL2 + an Ubuntu distro, then run `make qemu-serial`.
Write-Output "NEXORA QEMU test cannot run on this Windows host:"
Write-Output "  - qemu-system-x86_64: not installed"
Write-Output "  - WSL/ Linux build environment: not installed"
Write-Output ""
Write-Output "Use one of:"
Write-Output "  a) GitHub Actions CI (primary): git push -> CI builds ISO and"
Write-Output "     runs the QEMU UEFI boot gate automatically."
Write-Output "  b) WSL2 with Ubuntu: inside WSL run 'make bootstrap && make qemu-serial'."
Write-Output ""
Write-Output "QEMU STATUS: NOT RUN (see TESTING.md / BUILD.md)."
exit 1