# f22: eno1 lost 192.168.20.222 after the WiFi card (2026-11-26)

## Fault
- 19:43 network-manager installed, wlp2s0 (f8:cf:52:cb:c7:b7) joined ZAXSense, DHCP .133. The SSID is on the same LAN as eno1, 192.168.20.0/24.
- 19:43:55 dhcpcd on eno1: `f8:cf:52:cb:c7:b7 claims 192.168.20.222`, `10 second defence failed`. It gave up .222 and took .134 (600 s lease).
- Cause: ARP flux. With `arp_ignore=0` and `arp_announce=0` the kernel answers ARP for .222 through wlp2s0 too, and dhcpcd counts that reply as an address conflict.
- The lease file kept .134, so the reboot at 19:48 got .134 again.

## Fix (owner `fix`, 2026-11-26 ~20:00)
- `/etc/sysctl.d/90-arp-multihome.conf`: `net.ipv4.conf.all.arp_ignore = 1`, `net.ipv4.conf.all.arp_announce = 2`. New file, no backup needed.
- `dhcpcd -k eno1`, removed `/var/lib/dhcpcd/eno1.lease`, `dhcpcd -r 192.168.20.222 eno1`: leased .222 for infinity.

## State after
- eno1 192.168.20.222 (metric 1002), wlp2s0 192.168.20.133 (metric 600). The default route still prefers WiFi.
- 2026-11-27: WiFi metric changed to 2000, never default; see `2026-11-27-wifi-route-tmux.md`.
- NM config `/etc/NetworkManager/conf.d/f22.conf`: eno1 unmanaged, dns=none.

## Search words
defence failed, claims 192.168.20.222, ARP flux, two interfaces same subnet
