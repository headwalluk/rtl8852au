# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project loosely tracks `PACKAGE_VERSION` in `dkms.conf`; entries before
this file was introduced are not backfilled — see the git log for prior history.

## [Unreleased]

### Added
- `install-dkms.sh` and `uninstall-dkms.sh` for one-shot, idempotent DKMS
  install and removal. The install script handles the upgrade path from
  prior fork versions (e.g. `1.16.0.0` from pulponair) and cleans up any
  legacy manual-install `.ko` left in `/lib/modules/.../realtek/rtw89/`.
- `CLAUDE.md` onboarding notes for code-assistant agents and new
  contributors (build flow, source layout, common footguns).
- This `CHANGELOG.md`.
- `docs/TODO.md` tracking deferred cleanup and known bugs.

### Changed
- Project version bumped to `1.17.0` (continuing monotonically from the
  prior fork's `1.16.0.0` so DKMS upgrades cleanly).
- `DRIVERVERSION` in `include/rtw_version.h` now tracks `PACKAGE_VERSION`;
  it had been frozen at the original 2021 Realtek vendor string despite
  years of fork activity, and is user-visible via `modinfo`, `ethtool -i`,
  and `/proc/net/rtl8852au/`.
- README rebranded to the headwalluk fork: CI badge, clone URLs, and
  lineage paragraph all updated. Lineage now credits pulponair as the
  prior community maintainer.
- README Secure Boot section rewritten to document the real `make
  sign-install` flow and the MOK enrolment gotcha (`make sign`
  regenerates `MOK.der` on every run).
- README tested-kernel list synced to what CI actually runs (now
  includes 6.17).
- README manual-clone snippet switched from the deprecated `git://`
  protocol to `https://`.

### Removed
- HWSIM build infrastructure (`CONFIG_HWSIM` switch, `HAL = hal_sim`
  branch, dead `_OS_INTFS_FILES` entries in `common.mk`, broken
  `cd os_dep/linux/hwsim` line in the `clean` target). The HWSIM
  source directories had already been deleted from the tree in an
  earlier fork commit but the build glue was left behind referencing
  files that no longer existed. Source-level `#ifdef CONFIG_HWSIM`
  blocks are unreachable now and are tracked for removal in
  `docs/TODO.md`.

### Fixed
- Build failure on Linux 6.18 caused by a symbol clash with the kernel's new
  `hmac_sha256()` in `<crypto/sha2.h>`. The local `hmac_sha256()` was unused,
  so it (and the dead `hmac_sha256_kdf` declaration) have been removed rather
  than version-gated.
- `make clean` no longer prints `cd: can't cd to os_dep/linux/hwsim`
  (cosmetic; the missing directory was harmless but noisy).
