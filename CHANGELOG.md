# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project loosely tracks `PACKAGE_VERSION` in `dkms.conf`; entries before
this file was introduced are not backfilled — see the git log for prior history.

## [Unreleased]

### Fixed
- Build failure on Linux 6.18 caused by a symbol clash with the kernel's new
  `hmac_sha256()` in `<crypto/sha2.h>`. The local `hmac_sha256()` was unused,
  so it (and the dead `hmac_sha256_kdf` declaration) have been removed rather
  than version-gated.
