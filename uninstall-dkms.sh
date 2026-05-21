#!/usr/bin/env bash
#
# Remove the rtl8852au driver from DKMS and clean up the legacy
# manual-install module if present.
#
# Run from anywhere:
#
#     sudo ./uninstall-dkms.sh

set -euo pipefail

MODULE="8852au"
PACKAGE="rtl8852au"
LEGACY_KO_PATH="/lib/modules/$(uname -r)/realtek/rtw89/${MODULE}.ko"

die()  { echo "error: $*" >&2; exit 1; }
info() { echo "==> $*"; }
warn() { echo "warning: $*" >&2; }

[[ $EUID -eq 0 ]]          || die "must be run as root (try: sudo $0)"
command -v dkms >/dev/null || die "dkms is not installed"

# Unload if loaded
if lsmod | awk '{print $1}' | grep -qx "${MODULE}"; then
    info "Unloading ${MODULE}"
    modprobe -r "${MODULE}" || warn "could not unload (still in use?) — continuing"
fi

# Remove all DKMS registrations for this package, regardless of version
mapfile -t EXISTING < <(
    dkms status -m "${PACKAGE}" 2>/dev/null | \
    awk -F'[,/]' '{
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2);
        if ($2 != "") print $2
    }' | sort -u
)

if [[ ${#EXISTING[@]} -eq 0 ]]; then
    info "No DKMS registrations found for ${PACKAGE}"
else
    for ver in "${EXISTING[@]}"; do
        info "Removing ${PACKAGE}/${ver}"
        dkms remove "${PACKAGE}/${ver}" --all
    done
fi

# Remove the legacy manual-install .ko if present
if [[ -e "${LEGACY_KO_PATH}" ]]; then
    info "Removing legacy manual-install module at ${LEGACY_KO_PATH}"
    rm -f "${LEGACY_KO_PATH}"
    depmod -a
fi

info "Done"
