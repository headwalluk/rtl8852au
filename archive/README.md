# Archive

Files in this directory are **not part of normal usage**. They're kept for
historical reference and may be removed in a future release.

| File | What it is | Why archived |
| --- | --- | --- |
| `clean` | Shell script that runs `rmmod` against `8192cu / 8192ce / 8192du / 8192de`. | Copy-paste residue from a different Realtek driver tree (the rtl8192 family). Does not reference this driver at all. |
| `runwpa` | Shell wrapper for `wpa_supplicant -c wpa1.conf -i wlan0`. | The referenced `wpa1.conf` was never in this tree. Predates the modern `wpa_supplicant` packaging that ships its own config. |
| `wlan0dhcp` | DIY `dhclient` driver that copies a static `ifcfg-wlan0` snippet into `/etc/sysconfig/network-scripts/`. | Pre-NetworkManager / pre-systemd-networkd RHEL-ism. Replaced on every modern distro by `NetworkManager`, `systemd-networkd`, `iwd`, etc. |
| `ifcfg-wlan0` | Static RHEL-style network config snippet. | Only referenced by `wlan0dhcp` above. |

If you want any of these to come back to the project root, file an issue
explaining the use case — otherwise they're candidates for deletion next
time the tree is cleaned up.
