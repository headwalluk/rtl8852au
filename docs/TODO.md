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

- [ ] **Delete dead `core/rtw_mem.c`.** Leftover from Realtek's
  separate `rtkm` RX-buffer preallocation module. It's in no object
  list (`common.mk` / `phl/phl.mk`), so it is never compiled — its
  stray `MODULE_VERSION("DRIVERVERSION")` literal is harmless. Remove
  it together with `include/rtw_mem.h` and the
  `CONFIG_PREALLOC_RX_SKB_BUFFER` include in `include/drv_types.h`
  once nothing else needs the header.

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

- [ ] **Port to Linux 7.1+.** Builds fail from 7.1 on (CI's
  current-stable and `rc` jobs are red until this lands). Needed:
  7.1 moved the cfg80211 key ops (`add/get/del_key`,
  `set_default_key`, `set_default_mgmt_key`, …) and station ops
  (`get/add/del/change_station`, `dump_station`) from
  `struct net_device *` to `struct wireless_dev *`, and
  `cfg80211_new_sta()` / `cfg80211_del_sta()` likewise; 7.2 removed
  `WIPHY_FLAG_SUPPORTS_5_10_MHZ` and `strncpy` is no longer declared
  (`ioctl_cfg80211.c`, `os_intfs.c`); 7.3-rc changes the
  `remain_on_channel` / `mgmt_tx` cookie arguments.

- [ ] **Cross-arch CI coverage.** The current workflow only builds
  on `ubuntu-24.04` (amd64). Add an `aarch64` cross-build job so
  Raspberry Pi regressions get caught in CI rather than in the field.

## Bugs

- [ ] **`make sign` regenerates `MOK.der` on every run.** The
  `NO_SKIP_SIGN` guard in `Makefile:30-32` looks like it was meant
  to detect an existing key and skip regeneration, but the variable
  is never actually consumed by the `sign` target. Either wire it up
  or drop it. `docs/secure-boot.md` warns users for now.

- [ ] **DKMS installs never get the suspend hook.** `suspend_rtw8852au`
  is only copied to `/usr/lib/systemd/system-sleep/` by `make
  install`; `install-dkms.sh` (the recommended path) doesn't install
  it, and `uninstall-dkms.sh` wouldn't remove it. Decide whether the
  unload-around-suspend workaround is still needed, then either wire
  it into the DKMS scripts or drop it.

## Process

- [ ] **Tidy up inherited `feature/*` branches.** Three branches
  remain on origin from the pulponair tree:
  `feature/27-bring-retry-and-failed-counter`,
  `feature/30-Cleanup-Makefile-and-Remove-Configurion-Options`, and
  `feature/32-Stabilize-rsn-ei-assoc`. None are part of this fork's
  workflow — `main` is canonical. Audit each for any salvageable
  changes, then `git push origin --delete <branch>` for the rest.
  (The previously-stale `origin/main` was already removed as part of
  the develop → main rename in 1.17.0.)

- [ ] **Decide on a release cadence.** Versions inherited from
  pulponair were bumped opportunistically; with semver now in place
  it would help to write down what triggers a major / minor / patch
  bump in this fork (e.g. minor = new kernel support, patch = bugfix
  only).
