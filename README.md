# rtl8852au

[![CI](https://github.com/headwalluk/rtl8852au/actions/workflows/kernel-build.yml/badge.svg?branch=main)](https://github.com/headwalluk/rtl8852au/actions)
[![License](https://img.shields.io/badge/license-GPL--2.0-blue)](LICENSE)
[![Kernel](https://img.shields.io/badge/kernel-5.15--6.18-orange)](docs/install.md)

Out-of-tree Linux kernel driver for the Realtek **RTL8852AU** / **RTL8832AU** USB Wi-Fi 6 chipsets.

## What this is

A community-maintained fork of Realtek's vendor driver, kept building against current Linux kernels for users of RTL8852AU-based USB Wi-Fi adapters (D-Link DWA-X1850, ASUS USB-AX56, TP-Link AX1800, BUFFALO WI-U3-1200AX2, ELECOM WDC-X1201DU3, and others — see [supported hardware](docs/supported-hardware.md) for the full list).

If you have one of these adapters and your distro's stock kernel doesn't see it as Wi-Fi, this driver is for you.

### Lineage

- **Realtek Corporation** — original vendor release `RTL8852AU_WiFi_linux_v1.15.0.1` (July 2021).
- **Larry Finger** — long-time community maintainer of Realtek wireless drivers on Linux.
- **[pulponair/rtl8852au](https://github.com/pulponair/rtl8852au)** — carried the fork forward after Larry's passing, modernised for kernels through 6.16.
- **headwalluk/rtl8852au** (this repo) — continues to track current kernel releases.

## Install

```bash
git clone https://github.com/headwalluk/rtl8852au.git
cd rtl8852au
sudo ./install-dkms.sh
```

`install-dkms.sh` registers the source with DKMS so the module rebuilds automatically on kernel updates. The script is idempotent — re-run it after `git pull` to upgrade. See [docs/install.md](docs/install.md) for distro-specific prerequisites and the manual DKMS recipe.

## Documentation

- [Install / update / uninstall](docs/install.md) — distro requirements, the install script, manual DKMS commands.
- [Secure Boot](docs/secure-boot.md) — module signing and MOK enrolment.
- [Supported hardware](docs/supported-hardware.md) — chipsets, known device IDs, and the USB modeswitch quirk for the D-Link DWA-X1850.
- [TODO / backlog](docs/TODO.md) — deferred cleanup, known bugs, planned work.
- [Original reference documents](./reference-docs/) — the PDFs shipped with the Realtek vendor drop (config, certification, mode-specific guides).
- [CHANGELOG](CHANGELOG.md).

## License

GPL-2.0 — see [LICENSE](LICENSE).
