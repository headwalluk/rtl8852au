# MAC Address (Static vs. Random)

The driver always uses the adapter's burned-in MAC address, read from the
chip's efuse at probe time. It does **not** randomise it. If you see a
different address, your network manager has changed it.

## Finding the real MAC

```bash
ip -d link show <iface> | grep -o 'permaddr [0-9a-f:]*'
```

`permaddr` only appears while the current address differs from the
permanent one. The predictable interface name also encodes it:
`wlx105a95449e6d` → `10:5a:95:44:9e:6d`.

A randomised address is easy to spot: the second hex digit of the first
byte is `2`, `6`, `a` or `e` (the locally-administered bit), e.g.
`f6:3b:fd:2d:66:b2`. `/sys/class/net/<iface>/addr_assign_type` reads `3`
when userspace has overridden the address.

> If the efuse is blank or invalid, the driver falls back to a random
> address in Realtek's `00:e0:4c` OUI and logs `invalid mac addr` in
> `dmesg`. This is rare and still won't look locally administered.

## Why it changes

NetworkManager, by default, uses a random MAC while **scanning** and may
use a per-network one when **connected**, depending on the connection's
`wifi.cloned-mac-address` setting. A disconnected adapter will therefore
often show a random address — which is what MAC-registration portals
(office/campus networks) complain about.

## Using the real MAC with NetworkManager

Per connection:

```bash
nmcli con modify "<connection>" 802-11-wireless.cloned-mac-address permanent
```

For every Wi-Fi connection, and to stop scan randomisation on this
adapter, create `/etc/NetworkManager/conf.d/rtl8852au-mac.conf`:

```ini
[device-rtl8852au]
match-device=driver:rtl8852au
wifi.scan-rand-mac-address=no

[connection-rtl8852au]
match-device=driver:rtl8852au
wifi.cloned-mac-address=permanent
```

Then `sudo systemctl restart NetworkManager`.

Other managers have equivalent knobs: iwd's `AddressRandomization` in
`/etc/iwd/main.conf`, wpa_supplicant's `mac_addr` / `preassoc_mac_addr`.

## Overriding the MAC in the driver

To make the driver itself use a different address (instead of the
efuse one), pass the `rtw_initmac` module parameter:

```bash
echo 'options 8852au rtw_initmac=02:11:22:33:44:55' | sudo tee /etc/modprobe.d/8852au-mac.conf
```

This only sets the starting address; NetworkManager can still change it
as described above.
