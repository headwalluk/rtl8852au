# Install / Update / Uninstall

## Requirements

You need `git`, `make`, `gcc`, `dkms`, and the kernel headers for your running kernel.

**Ubuntu / Debian**
```bash
sudo apt update
sudo apt install -y git make gcc dkms linux-headers-$(uname -r) build-essential
```

**Fedora**
```bash
sudo dnf install git dkms kernel-headers kernel-devel
sudo dnf group install "C Development Tools and Libraries"
```

**openSUSE**
```bash
sudo zypper install git make gcc dkms kernel-devel kernel-default-devel libopenssl-devel
```

**Arch Linux**
```bash
sudo pacman -S --needed base-devel git dkms linux-headers
```

## Install

```bash
git clone https://github.com/headwalluk/rtl8852au.git
cd rtl8852au
sudo ./install-dkms.sh
```

DKMS will rebuild the module automatically the next time you upgrade your kernel — no further manual action needed on kernel updates.

Verify after install:

```bash
modinfo 8852au | head -5
lsmod | grep 8852au
```

`modinfo` should report `version: v1.17.0` and a `filename:` under `/lib/modules/<kernel>/updates/dkms/`.

## Update (after `git pull`)

```bash
cd rtl8852au
git pull
sudo ./install-dkms.sh
```

`install-dkms.sh` is idempotent: it unloads the running module, removes any prior DKMS registration of `rtl8852au` (at any version — including older releases inherited from upstream forks), removes a legacy manual-install `.ko` if one is present at `/lib/modules/<kernel>/realtek/rtw89/`, then registers, builds, installs, and loads the current source tree.

## Uninstall

```bash
sudo ./uninstall-dkms.sh
```

Removes all DKMS registrations of `rtl8852au` and cleans up the legacy manual-install `.ko` path. Safe to run even if nothing is currently installed.

## Manual DKMS commands

If you prefer to drive DKMS by hand, the script does the equivalent of:

```bash
version=$(grep PACKAGE_VERSION dkms.conf | cut -d'"' -f2)
sudo dkms add .
sudo dkms build  rtl8852au/${version}
sudo dkms install rtl8852au/${version}
sudo modprobe 8852au
```

If a prior version of the package is already registered with DKMS, remove it first with `sudo dkms remove rtl8852au/<old-version> --all`.
