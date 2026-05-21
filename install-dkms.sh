#!/usr/bin/env bash
#
# Install the rtl8852au driver via DKMS.
#
# Run from the repository root:
#
#     sudo ./install-dkms.sh
#
# Idempotent: removes any prior DKMS registration of rtl8852au (at any
# version) and any legacy manual-install module before registering the
# current source tree.

set -euo pipefail

MODULE="8852au"
PACKAGE="rtl8852au"
LEGACY_KO_PATH="/lib/modules/$(uname -r)/realtek/rtw89/${MODULE}.ko"

die()  { echo "error: $*" >&2; exit 1; }
info() { echo "==> $*"; }
warn() { echo "warning: $*" >&2; }

[[ $EUID -eq 0 ]]                         || die "must be run as root (try: sudo $0)"
[[ -f dkms.conf ]]                        || die "dkms.conf not found in $(pwd) — run this from the repository root"
command -v dkms >/dev/null                || die "dkms is not installed — install it via your package manager"
command -v make >/dev/null                || die "make is not installed — install build-essential / base-devel / equivalent"

VERSION=$(awk -F'"' '/^PACKAGE_VERSION=/ {print $2; exit}' dkms.conf)
[[ -n "$VERSION" ]]                       || die "could not extract PACKAGE_VERSION from dkms.conf"

info "Installing ${PACKAGE} ${VERSION} via DKMS (kernel $(uname -r))"

# Unload the currently-loaded module (best-effort — may fail if in use)
if lsmod | awk '{print $1}' | grep -qx "${MODULE}"; then
    info "Unloading currently-loaded ${MODULE} module"
    modprobe -r "${MODULE}" || warn "could not unload ${MODULE} (still in use?) — continuing"
fi

# Remove any prior DKMS registrations for this package, regardless of version.
# Handles both the modern "pkg/ver, kver, arch: status" and legacy
# "pkg, ver, kver, arch: status" dkms-status formats.
mapfile -t EXISTING < <(
    dkms status -m "${PACKAGE}" 2>/dev/null | \
    awk -F'[,/]' '{
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2);
        if ($2 != "") print $2
    }' | sort -u
)

for ver in "${EXISTING[@]}"; do
    info "Removing prior DKMS registration: ${PACKAGE}/${ver}"
    dkms remove "${PACKAGE}/${ver}" --all || warn "failed to remove ${PACKAGE}/${ver} — continuing"
done

# Remove a legacy manual-install module if present so depmod can't pick the
# wrong one after DKMS installs into /lib/modules/$(uname -r)/updates/dkms/.
if [[ -e "${LEGACY_KO_PATH}" ]]; then
    info "Removing legacy manual-install module at ${LEGACY_KO_PATH}"
    rm -f "${LEGACY_KO_PATH}"
fi

# Strip build artifacts so `dkms add .` doesn't drag ~50 MB into /usr/src/.
info "Cleaning build artifacts (make clean)"
make clean >/dev/null

info "Registering source with DKMS"
dkms add .

info "Building module"
dkms build "${PACKAGE}/${VERSION}"

info "Installing module"
dkms install "${PACKAGE}/${VERSION}"

info "Loading ${MODULE}"
modprobe "${MODULE}"

info "Done. modinfo summary:"
modinfo "${MODULE}" | sed -n '1,5p'
