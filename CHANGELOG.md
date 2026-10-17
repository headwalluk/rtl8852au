# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project loosely tracks `PACKAGE_VERSION` in `dkms.conf`; entries before
this file was introduced are not backfilled — see the git log for prior history.

## [Unreleased]

## [1.17.1] — 2026-10-17

Patch release: restores builds on current 6.1 / 6.6 / 6.12 stable
kernels (broken by upstream stable backports), rebuilds CI so those
backports get caught automatically, and corrects the Secure Boot docs.
Build-verified against 5.15.223, 6.1.190, 6.6.159, 6.8.12, 6.12.113,
6.18.57, 6.19.14 and 7.0.14. Linux 7.1+ is not yet supported (see
`docs/TODO.md`).

### Added
- README "Before you install: do you actually need this?" section
  pointing users at `modinfo rtw89_8852au` to check whether the
  mainline in-tree driver already covers their adapter. The
  in-tree `rtw89` driver has been adding USB chipset support over
  recent kernels, so an honest exit-ramp before the DKMS install
  saves users a step they may not need.

### Changed
- Default branch renamed from `develop` to `main` (with the stale
  inherited `origin/main` removed first). `main` is now the canonical
  trunk and the only long-lived branch. Tags continue to mark stable
  release points. README CI badge URL, CLAUDE.md release flow, and
  `docs/TODO.md` updated accordingly.

- CI rewritten: the matrix now tracks *series* (5.15, 6.1, 6.6, 6.8,
  6.12, 6.18, current stable, newest `-rc`) and resolves each to its
  latest point release at run time, so stable backports of API
  changes are caught as they ship. Each series builds in the Ubuntu
  container matching the compiler Ubuntu's mainline headers were
  built with (gcc-11 / gcc-13 / gcc-15). Also runs weekly on a
  schedule, and `actions/checkout` is bumped to v7 (Node 24 — the
  v4/Node 20 runtime was removed from GitHub runners in September
  2026).
- README **Kernel** badge now reflects the verified build range,
  5.15–7.0 (7.1+ needs porting work; see `docs/TODO.md`).
- `docs/secure-boot.md` rewritten around DKMS 3.x's automatic module
  signing (`mokutil --import /var/lib/dkms/mok.pub`, once). The old
  advice to run `make sign-install` on DKMS systems produced a second,
  separately-installed module that `install-dkms.sh` deletes.

### Fixed
- Build failure on 6.12.101+ stable kernels (e.g. Debian trixie
  6.12.113): the 6.13 `set_monitor_channel` signature change (extra
  `struct net_device *` arg) was backported to 6.12.101, so the
  `>= 6.13` guard in `ioctl_cfg80211.c` now also covers that range.
- Build failure on 6.1.188+ and 6.6.157+ stable kernels: the 6.8
  removal of `usb_driver.drvwrap` was backported to those branches;
  the guard in `usb_intf.c` now accounts for it.
- `suspend_rtw8852au` sleep hook used the bash-only `==` under
  `#!/bin/sh`, so on dash-based systems (Debian, Ubuntu) both tests
  errored and the module was never unloaded/reloaded around suspend.
- `make clean` now removes the top-level `.module-common.o` that
  kbuild ≥ 6.13 generates (it was being copied into `/usr/src` by
  `dkms add`).

## [1.17.0] — 2026-05-21

First release under the headwalluk fork. Establishes baseline quality of life
improvements over the inherited tree: kernel 6.18 support, single-source-of-
truth versioning, an idempotent DKMS install flow, and a restructured `docs/`
tree.

### Added
- `install-dkms.sh` and `uninstall-dkms.sh` for one-shot, idempotent DKMS
  install and removal. The install script handles the upgrade path from
  prior fork versions (e.g. `1.16.0.0` from pulponair) and cleans up any
  legacy manual-install `.ko` left in `/lib/modules/.../realtek/rtw89/`.
- `CLAUDE.md` onboarding notes for code-assistant agents and new
  contributors (build flow, source layout, common footguns).
- This `CHANGELOG.md`.
- `docs/TODO.md` tracking deferred cleanup and known bugs.
- `LICENSE` file with the canonical GPL-2.0 text (the project was
  already GPL-2.0 per `MODULE_LICENSE` and file headers, but no
  top-level licence file existed — GitHub can now auto-detect it).
- `docs/install.md`, `docs/secure-boot.md`, `docs/supported-hardware.md`
  — focused docs for each topic, linked from the README.

### Changed
- Project version bumped to `1.17.0` (continuing monotonically from the
  prior fork's `1.16.0.0` so DKMS upgrades cleanly).
- `dkms.conf` (`PACKAGE_VERSION`) is now the single source of truth for
  the driver version. The Makefile reads it via shell substitution and
  injects `-DDRIVERVERSION="v<version>"` at build time, so `modinfo`,
  `ethtool -i`, `/proc/net/rtl8852au/`, and `MODULE_VERSION` all update
  automatically. `include/rtw_version.h` is reduced to a fallback that
  only fires when the macro hasn't been defined on the command line
  (for IDE / standalone builds). Previously the two locations had to be
  kept in sync by hand, and `DRIVERVERSION` had silently drifted for
  several fork generations. The release process is now documented in
  `CLAUDE.md`.
- README rebranded to the headwalluk fork: CI badge, clone URLs, and
  lineage paragraph all updated. Lineage now credits pulponair as the
  prior community maintainer.
- README slimmed: badges (CI / GPL-2.0 / kernel support), short
  "what this is" + lineage, single-command install, and a links
  section pointing at the new `docs/` files and `reference-docs/`.
  All distro requirements, manual DKMS commands, Secure Boot flow,
  and hardware lists moved out to dedicated docs.
- README manual-clone snippet switched from the deprecated `git://`
  protocol to `https://`.
- `document/` directory renamed to `reference-docs/` to better
  describe what it contains (the Realtek vendor PDFs shipped with
  the original driver drop). `ReleaseNotes.pdf` (Realtek's release
  notes for the v1.15.0.1 vendor drop) also moved here from the
  repo root, alongside its siblings.
- Vendor-era helper scripts moved out of the project root into
  `archive/`: `clean` (runs `rmmod` against rtl8192-family modules
  unrelated to this driver), `runwpa` (refers to a `wpa1.conf` that
  was never in-tree), `wlan0dhcp` (pre-NetworkManager DIY DHCP
  driver), and `ifcfg-wlan0` (RHEL-style snippet only used by
  `wlan0dhcp`). `archive/README.md` documents what each file was
  and why it's no longer at the root.

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
