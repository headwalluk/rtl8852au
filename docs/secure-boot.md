# Secure Boot

If Secure Boot is enabled, the kernel will refuse to load an unsigned module.
Check with:

```bash
mokutil --sb-state
```

## DKMS install (recommended)

DKMS 3.x (Debian 12+, Ubuntu 22.04+, Fedora, Arch, openSUSE) signs every
module it builds automatically. On first use it generates a key pair at
`/var/lib/dkms/mok.key` / `/var/lib/dkms/mok.pub` (paths are configurable in
`/etc/dkms/framework.conf`). All you need to do is enrol that public key with
shim **once**:

```bash
sudo ./install-dkms.sh                     # builds, signs, installs
sudo mokutil --import /var/lib/dkms/mok.pub
```

`mokutil` asks for a one-time password. **Reboot**; the firmware shows the
MOK enrolment screen — choose *Enroll MOK* and enter that password.

From then on, every DKMS rebuild (kernel updates, re-running
`install-dkms.sh`) is signed with the same enrolled key — nothing further to
do. If `dkms --version` reports 2.x, upgrade DKMS or follow the manual
section below.

To confirm a module is signed:

```bash
modinfo 8852au | grep -E '^(signer|sig_key)'
```

## Manual install (no DKMS)

The Makefile has a `sign-install` target for the non-DKMS `make install`
path:

```bash
make
sudo make sign-install
```

This generates a Machine Owner Key (`MOK.priv` / `MOK.der`) in the source
tree, imports it via `mokutil --import`, signs `8852au.ko`, and installs it to
`/lib/modules/$(uname -r)/realtek/rtw89/`. Reboot to complete enrolment as
above.

> **Gotcha:** `make sign` regenerates `MOK.der` on every invocation, which
> invalidates the previously enrolled key. After the first run, re-sign new
> builds with the existing key instead:
>
> ```bash
> sudo /lib/modules/$(uname -r)/build/scripts/sign-file sha256 MOK.priv MOK.der 8852au.ko
> sudo make install
> ```
>
> Wiring the key generation to only fire when `MOK.der` is absent is tracked
> in [docs/TODO.md](TODO.md).

**Don't mix the two paths.** `install-dkms.sh` deletes a manually installed
`realtek/rtw89/8852au.ko`, and while both copies exist `depmod` picks only
one of them — so on a DKMS system, sign via DKMS's key, not
`make sign-install`.
