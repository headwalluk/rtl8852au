# Supported Hardware

## Chipsets

- **RTL8852AU**
- **RTL8832AU**

## Known Supported Devices

| Device | USB IDs |
| --- | --- |
| ASUS USB-AX56 | `0b05:1997`, `0b05:1a62` |
| BUFFALO WI-U3-1200AX2 / WI-U3-1200AX2N | `0411:0312` |
| D-Link DWA-X1850 | `2001:3321`, `2001:0141` |
| EDUP EP-AX1696GS | `0bda:8832` |
| ELECOM WDC-X1201DU3 | `056e:4020` |
| Fenvi FU-AX1800P | `0bda:885c` |
| ipTIME AX2000U | `0bda:8832` |
| Realtek demo boards | `0bda:8832`, `0bda:885a`, `0bda:885c` |
| TP-Link Archer TX20UH | `2357:0141` |
| TP-Link AX1800 | `2357:013f`, `2357:0140` |
| TP-Link (vendor 0x35bc) | `35bc:0100` |

Use `lsusb` to find the USB ID of your adapter. If yours isn't on this list but uses one of the supported chipsets, the driver may still bind to it — please open an issue to report it.

## USB Modeswitch (D-Link DWA-X1850)

Some DWA-X1850 units enumerate as a USB disk (`0bda:1a2b`) with Windows drivers on board. To force them into Wi-Fi mode, add this rule to either `/usr/lib/udev/rules.d/40-usb_modeswitch.rules` or `/lib/udev/rules.d/40-usb_modeswitch.rules`:

```
# D-Link DWA-X1850 WiFi Dongle
ATTR{idVendor}=="0bda", ATTR{idProduct}=="1a2b", RUN+="usb_modeswitch '/%k'"
```

Reload udev rules (`sudo udevadm control --reload && sudo udevadm trigger`) or replug the device.
