# TODO / Future Work

A backlog of known cleanup, bugs, and improvements for this fork.
Items here are **not blocking** for the current release — they're
recorded so they don't get lost between sessions.

## Cleanup

- [ ] **Complete HWSIM excision.** The build glue is gone (commit
  trail in CHANGELOG under 1.17.0), but `#ifdef CONFIG_HWSIM` blocks
  still exist in `include/drv_types.h`, `include/osdep_service_linux.h`,
  `os_dep/osdep_service.c`, `os_dep/linux/ioctl_cfg80211.c`, and
  `core/rtw_ap.c`. The orphaned `include/rtw_hwsim_intf.h` header and
  the unused `bup_hwsim` field in the adapter struct should go too.
  Nothing in the tree can set `CONFIG_HWSIM=y` and build successfully
  any more, so these blocks are unreachable.

- [ ] **Cull pre-5.15 kernel version guards.** The README states
  Linux 5.15+ is required, but `LINUX_VERSION_CODE` checks for 2.x,
  3.x, and pre-5.15 4.x kernels are still scattered across
  `os_dep/linux/`. Each one is a maintenance trap — the legacy branch
  isn't compiled, isn't tested, and rots silently. Big sweep
  (50+ files), best done as its own PR with a clear "5.15 is the
  floor" commit message.

- [ ] **Relocate support scripts and snippets out of the project root.**
  `suspend_rtw8852au` currently lives at the repo root because the
  `install:` target in `Makefile` copies it from there to
  `/usr/lib/systemd/system-sleep/`. A tidier home would be a
  `scripts/` directory (for executable helpers) and/or an `etc/`
  directory (for config snippets / udev rules / systemd units). When
  doing this, update the Makefile install rule to point at the new
  path, and check whether any user-facing docs need adjusting.
  Bundle with whatever else lands at the root over time (e.g. helper
  scripts spun off from `install-dkms.sh`).

- [ ] **Audit the dead `CONFIG_*` switches in `Makefile`.** Several
  toggles are set to `n` and never flipped by anything we care about:
  `CONFIG_MP_INCLUDED`, `CONFIG_CONCURRENT_MODE`, `CONFIG_BTC`,
  `CONFIG_WAPI_SUPPORT`, `CONFIG_TDLS`, `CONFIG_MCC_MODE`,
  `CONFIG_FSM`, `CONFIG_DRV_FAKE_AP`, etc. Each one carries a
  matching `ifeq ... endif` block + a `-D...` cflag + (sometimes)
  conditional OBJS in `common.mk` / `phl/phl.mk`. Same logic as the
  HWSIM cleanup — if no one can flip them, remove them. Do one
  feature at a time.

## Build / CI

- [ ] **Add Linux 6.18 to the CI matrix.** We've confirmed the
  `hmac_sha256` fix produces a working module on a Pi 5 running
  6.18. Add `"6.18"` to the matrix in
  `.github/workflows/kernel-build.yml` once Ubuntu mainline has a
  stable 6.18 build at `kernel.ubuntu.com/mainline/v6.18/amd64/` (the
  workflow scrapes that index).

- [ ] **Tag `v1.17.0` once Pi build and load are confirmed.** Sequence:
  rename `[Unreleased]` → `[1.17.0] — <date>` in `CHANGELOG.md`, add
  a fresh empty `[Unreleased]` above, commit, `git tag v1.17.0`,
  push tag, cut a GitHub release.

- [ ] **Cross-arch CI coverage.** The current workflow only builds
  on `ubuntu-24.04` (amd64). Add an `aarch64` cross-build job so
  Raspberry Pi regressions get caught in CI rather than in the field.

## Bugs

- [ ] **Stray `MODULE_VERSION("DRIVERVERSION")` in `core/rtw_mem.c:22`.**
  Passes the literal string `"DRIVERVERSION"` rather than the macro.
  There's also a correct `MODULE_VERSION(DRIVERVERSION)` in
  `os_dep/linux/os_intfs.c:22`, so the module ends up with two
  `MODULE_VERSION` declarations — the kbuild output keeps one and
  silently drops the other. Remove the broken duplicate.

- [ ] **`make sign` regenerates `MOK.der` on every run.** The
  `NO_SKIP_SIGN` guard in `Makefile:30-32` looks like it was meant
  to detect an existing key and skip regeneration, but the variable
  is never actually consumed by the `sign` target. Either wire it up
  or drop it. README's Secure Boot section warns users for now.

## Process

- [ ] **Decide on a release cadence.** Versions inherited from
  pulponair were bumped opportunistically; with semver now in place
  it would help to write down what triggers a major / minor / patch
  bump in this fork (e.g. minor = new kernel support, patch = bugfix
  only).
