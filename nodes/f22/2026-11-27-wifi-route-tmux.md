# f22: WiFi took the LAN route; owner SSH and a Claude session dropped (2026-11-27)

## Fault
- 13:13-13:16 and 13:39-13:41: #79 bench scripts (`~/ZaxModbus-PS-79/Doc/Async-MQTT/bench-PS-E002/11-v3`, `13-c11`) moved wlp2s0 to unit APs (`nmcli con up zax-ap-*`, 192.168.99.x) and back to ZAXSense.
- eno1: no link event. Owner SSH from 192.168.20.13 reset at 13:42:04; the Claude Code session in that window died with it (its API calls worked to 13:41:17).
- Cause: ZAXSense put wlp2s0 on the same 192.168.20.0/24 as eno1 with metric 600 (eno1 1002), so LAN and default traffic left by WiFi; each AP hop removed that path under live sessions.

## Fix (owner `ok`, 2026-11-27)
- `nmcli con mod ZAXSense ipv4.never-default yes ipv4.route-metric 2000` (old: no / -1 = auto 600). Applied with `nmcli con up ZAXSense`.
- `apt install tmux` (3.5a). `~/.bashrc` alias `cc='tmux new -A -s claude claude --dangerously-skip-permissions'` (backup `~/.bashrc.pre-tmux-20261127`).

## State after
- Default route and 192.168.20.0/24 on eno1 (metric 1002); wlp2s0 ZAXSense .133 metric 2000, never default. WiFi carries the LAN only if the eno1 route is gone; while eno1 is up, no internet over WiFi.
- Unit AP profiles (`zax-ap-*`) already have `ipv4.never-default yes`; scripts unchanged.
- Start Claude on f22 with `cc`; after an SSH drop, log in and `cc` re-attaches. Owner tested from another PC 2026-11-27: PASS.
- Record: `ZaxModbus-PS/Doc/errors-history.md` 2026-11-27 (c113e24, f810e9d).

## Search words
SSH reset, session died, route metric, never-default, ZAXSense, zax-ap, tmux, cc alias
