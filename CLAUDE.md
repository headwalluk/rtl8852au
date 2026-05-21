# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Out-of-tree Linux kernel driver for the Realtek RTL8852AU / RTL8832AU USB Wi-Fi 6 chipsets. Community fork (pulponair/rtl8852au) of the original Realtek vendor driver, modernized for current kernels. Default branch is `develop`. Required kernel ≥ 5.15; CI builds against 6.8, 6.13–6.17.

The build produces a single kernel module: **`8852au.ko`** (module name derived in `Makefile` from `CONFIG_RTL8852A=y` + `CONFIG_USB_HCI=y`). PCI/SDIO/GSPI scaffolding exists but is disabled.

## Build / install / clean

```bash
make                       # build 8852au.ko against running kernel
make -j$(nproc) KSRC=...   # build against an explicit kernel headers tree (used by CI)
make clean                 # the in-Makefile `clean` target — recursive .o/.mod/.ko sweep, NOT `make -C $KSRC clean`
sudo make install          # installs to /lib/modules/$(uname -r)/realtek/rtw89/ + runs depmod + drops systemd-sleep hook
sudo make uninstall
make sign                  # generate MOK + sign 8852au.ko for Secure Boot (interactive — runs mokutil --import)
make sign-install          # all + sign + install
```

DKMS is the recommended path for users. `dkms.conf` carries the canonical version (`PACKAGE_VERSION`); `docs/install.md` has the human-facing recipe; `install-dkms.sh` / `uninstall-dkms.sh` wrap the full register/build/install/cleanup dance idempotently.

There are no unit tests. "Test" = build cleanly against a target kernel and load the module on real hardware. CI (`.github/workflows/kernel-build.yml`) downloads mainline kernel headers from `kernel.ubuntu.com/mainline/v<ver>/amd64/` and runs `make clean && make -j$(nproc) KSRC=...` against each matrix kernel — replicate that locally when validating kernel-compat changes.

## How the build is wired

The top-level `Makefile` runs **twice**: once outside the kernel build (the `modules:` target shells out to `$(MAKE) -C $(KSRC) M=$(PWD) modules`), and once recursively inside kbuild where `KERNELRELEASE` is set. The `ifneq ($(KERNELRELEASE),)` block at line ~588 is the kbuild side; everything above it runs in both passes.

`EXTRA_CFLAGS` is assembled from a long list of `CONFIG_*` toggles defined at the top of `Makefile`. These are **not** Kconfig — they are plain make variables that gate `-D...` flags and which `.o` files end up in `OBJS`. When changing a feature, grep both the Makefile (for the toggle) and the source (for the `-D` symbol it defines).

Object file lists live in two includes pulled in only on the kbuild pass:
- `common.mk` — adds `os_dep/**` and `core/**` objects to `OBJS`, gated by `CONFIG_*`.
- `phl/phl.mk` — adds the PHL/HAL objects.

So: adding a new `.c` file means appending to `_OS_INTFS_FILES` / `_CORE_FILES` in `common.mk` (or the appropriate list in `phl/phl.mk`), not just dropping it in the directory.

`platform/*.mk` is wildcard-included before the kbuild pass and can override `KSRC` / `CROSS_COMPILE` — the default `i386_pc.mk` points `KSRC` at `/lib/modules/$(shell uname -r)/build`.

## Releasing / bumping the version

The version is declared **once** in `dkms.conf` (`PACKAGE_VERSION`). The Makefile reads it via an `awk` shell-substitution and `-D`s `DRIVERVERSION=\"v<version>\"` into the build, so `modinfo`, `ethtool -i`, `/proc/net/rtl8852au/`, and the kernel's `MODULE_VERSION` macro all update automatically on the next build. `include/rtw_version.h` is a fallback header that only defines `DRIVERVERSION` if the macro hasn't already been set on the command line — relevant for IDE / standalone builds that bypass the project Makefile.

To cut a release (e.g. bumping to `1.18.0`):

1. **`dkms.conf`** — set `PACKAGE_VERSION="1.18.0"`. *This is the only file that touches the version number.* Do not edit `include/rtw_version.h` or `docs/install.md`'s example `modinfo` output by hand.
2. **`CHANGELOG.md`** — rename `## [Unreleased]` to `## [1.18.0] — YYYY-MM-DD`, then add a fresh empty `## [Unreleased]` block above it. Entries should already be sorted into Keep-a-Changelog categories (Added / Changed / Deprecated / Removed / Fixed / Security).
3. **`README.md`** — only if the supported-kernel range changed (e.g. CI matrix gained a new version): update the **Kernel** badge URL (`https://img.shields.io/badge/kernel-5.15--6.18-orange`) and the lineage paragraph's "tracks current kernel releases" claim if relevant.
4. **Verify** — `make clean && make` locally, then `modinfo 8852au.ko | grep ^version` should report the new `v1.18.0`.
5. **Tag** — commit (style: `[RELEASE] Cut v1.18.0`), `git tag v1.18.0`, `git push origin develop --follow-tags`, then cut a GitHub release citing the relevant `CHANGELOG.md` section.

Do **not** bump `RTK_CORE_TAGINFO` in `phl/phl_git_info.h` as part of fork releases — that macro is the original Realtek upstream tag (frozen at the 2021 vendor drop) and has a different semantic.

## Source layout (the parts you need to know)

The codebase is divided into three layers that talk through narrow interfaces — when fixing a kernel-API breakage, identify which layer the symbol lives in first.

- **`os_dep/linux/`** — Linux/cfg80211 glue. This is where kernel API churn shows up: `usb_intf.c` (USB probe/disconnect), `ioctl_cfg80211.c` (nl80211 ops), `os_intfs.c` (netdev ops — `ndo_*`), `rtw_proc.c` (`/proc/net/rtl8852au/` debug interfaces), `xmit_linux.c` / `recv_linux.c`. `osdep_service_linux.c` wraps timers/locks/skb helpers. Recent commits ("Migrate to ndo_get_stats64", "Support kernel 6.17") almost all touched this directory.
- **`core/`** — OS-agnostic driver core: 802.11 state machine (`rtw_mlme*.c`, `rtw_mlme_ext.c`), TX/RX paths (`rtw_xmit*.c`, `rtw_recv*.c`, plus `*_shortcut.c` fast paths), security/crypto (`rtw_security.c`, `core/crypto/` software AES/CCMP/GCMP), command queue (`rtw_cmd.c`), STA/scan/AP/P2P/TDLS modules. `rtw_phl.c` / `rtw_phl_cmd.c` are the bridge into the PHL layer.
- **`phl/`** — Realtek's PHY/HAL layer (largely vendor code). `phl/hal_g6/` is the gen-6 HAL implementation; `phl/hci/` contains bus-specific bits. `phl_cmd_dispatcher.c` runs the asynchronous command queue between core and HAL. Touch this layer sparingly — most kernel-compat work belongs in `os_dep/linux/`.

`include/` holds shared headers used across layers (`drv_types.h` is the central context type). `include/autoconf.h` is generated/copied from `autoconf_<ic>_<hci>_linux.h` when `CONFIG_AUTOCFG_CP=y` (default `n`, so the checked-in file is used).

## Things that will bite you

- **Editing `Makefile` or `*.mk`?** Run `make clean` before rebuilding. kbuild's `.cmd` cache files don't track make-variable changes and will happily link a stale `.o`.
- **Per-kernel guards** use `LINUX_VERSION_CODE` / `KERNEL_VERSION(x,y,z)` checks scattered across `os_dep/linux/`. When supporting a new kernel, search for the most recent existing guard (e.g., `KERNEL_VERSION(6, 17`) and follow its pattern rather than inventing a new style.
- **Module is USB-only** in shipped config. `CONFIG_PCI_HCI` / `CONFIG_SDIO_HCI` source files exist but are not compiled. Don't waste time chasing PCI-only bugs unless explicitly enabling that HCI.
- **`CONFIG_RTW_DEBUG=0`** by default — bumping it and rebuilding is the standard way to get verbose logs. `CONFIG_PROC_DEBUG=y` enables `/proc/net/rtl8852au/` interfaces.
- **`make clean` is custom**, not kbuild's clean. It hand-removes `.o`/`.mod`/`.ko`/`.*.cmd` under `core/`, `os_dep/`, `phl/` (`$(HAL)`), `platform/`. New source directories won't be cleaned unless added there.
- README's "Secure Boot" section ends with `make` / `sudo make` which is misleading — the real signing target is `make sign` (or `make sign-install`).
