# Secure Boot

If Secure Boot is enabled, the kernel will refuse to load an unsigned module. The Makefile provides a `sign-install` target that builds, signs, and installs the module in one step:

```bash
sudo make sign-install
```

This does three things:

1. Generates a one-time Machine Owner Key (`MOK.priv` / `MOK.der`) in the source tree.
2. Imports the public key via `mokutil --import`. You will be prompted for a one-time password.
3. Signs `8852au.ko` with that key and installs it.

**Reboot afterwards** to complete MOK enrolment in shim. On the next boot the firmware will present an enrolment screen and ask for the password you set during `mokutil --import`.

After MOK is enrolled, kernel updates that rebuild the module via DKMS will produce an unsigned `.ko`. To sign it for the new kernel, re-run the sign step from the source tree:

```bash
sudo make sign-install
```

> **Gotcha:** `make sign` regenerates `MOK.der` on every invocation, which invalidates any earlier signatures. Run the full signing step only once during initial setup. For subsequent kernel updates, sign the freshly-built module with your existing key rather than re-generating one. See the `sign:` rule in the `Makefile` for the exact `sign-file` command — wiring the key-regeneration step to only fire when `MOK.der` is absent is tracked in [docs/TODO.md](TODO.md).

## DKMS users

If you installed via `install-dkms.sh`, DKMS will rebuild the module on kernel upgrades. The rebuild produces an unsigned `.ko`; signing has to happen after the rebuild. The simplest workflow is:

1. Install via the script normally.
2. Sign once via `sudo make sign-install` from the source tree (which also imports the MOK).
3. On future kernel updates, run `sudo make sign-install` again to re-sign the newly-built module.

A future improvement (tracked in TODO) is to teach `install-dkms.sh` to optionally sign with an existing `MOK.priv`/`MOK.der` pair.
