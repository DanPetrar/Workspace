# Remote SSH from f22 to pc-gate after it leaves: proposals (2026-11-03)

Owner: "prepare a remote conexion posibility (ssh) fron f22 to pc-gate when it leave our location. something like tilescale or similar we can consider. please analyse this and make some proposals."

## Facts (read 2026-11-03)

- pc-gate = GW3M710, `gw2mqtt@192.168.20.90`, Debian 13 x86_64, 4 cores, 7.8 GB RAM. OpenSSH active, key only (`PasswordAuthentication no`, `PermitRootLogin no`). No tailscale, wg or autossh installed.
- f22: Debian 13, no tailscale, wg or autossh installed. f22's `known_hosts` already holds pc-gate's ed25519 key.
- Not known (they decide the choice): the network at the new site (router owner, outbound UDP allowed or not, CGNAT); whether our site has a public IP or can forward a port on our router; whether pc-gate must reach anything else here (MQTT/Influx on the workstation), or SSH only.

## The problem

pc-gate will sit behind a router we probably do not manage. So it must dial **out**. Nothing can dial in to it.

## Options

| | Option | Needs at the new site | Needs at our site | Third party | Work |
|---|---|---|---|---|---|
| A | **Tailscale** (WireGuard mesh, free personal plan, up to 100 devices) | outbound internet only. Uses UDP if it can, else a relay over HTTPS 443 | nothing (no port forward) | Tailscale coordination server (it sees keys and metadata, not the traffic) | ~30 min for both machines + a test |
| B | Headscale (self-hosted Tailscale control server) on the workstation + Tailscale clients | outbound only | a public HTTPS endpoint here (port forward + DNS/DDNS) | none | ~half a day, plus upkeep |
| C | Plain WireGuard: pc-gate dials our router, keepalive 25 s | outbound UDP | public IP or DDNS + one UDP port forward to f22 | none | ~1 h, router change by the owner |
| D | Reverse SSH tunnel (`autossh -R`) from pc-gate to a host here | outbound TCP | public IP/DDNS + one TCP port forward | none | ~1 h, fragile on long drops (autossh restarts it) |
| E | ZeroTier / NetBird (similar to A) | outbound only | nothing | their server | like A |

## Recommendation: A (Tailscale), OpenSSH kept as the login

- Install `tailscale` on pc-gate and f22 from Tailscale's Debian repo. Log in with one account (the GitHub login `DanPetrar` works).
- Keep the normal OpenSSH key login over the tailnet address (`100.x`). Do not turn on "Tailscale SSH": the existing key rules stay in force.
- Turn **key expiry off** for pc-gate in the admin page. Otherwise it drops off after 180 days and nobody is there to log it back in.
- ACL: only f22 (and futro, if wanted) may reach pc-gate port 22. pc-gate may not reach into our LAN.
- MagicDNS name, e.g. `pc-gate`, plus an `~/.ssh/config` entry on f22 so that `ssh pc-gate` works from anywhere.
- Unattended security upgrades stay on. Tailscale updates come with them through the apt repo.

Why A: it works behind any NAT, needs no port on our router and nothing from the new site's router, and takes the least work. Its cost is a dependency on an outside service and an account.
If the owner wants no third party: C (if our site can forward a port), else B.

## Optional second path (only if the owner wants it)

If `tailscaled` fails after an upgrade, the unit is out of reach until someone is on site. A second, independent path is D (reverse SSH to a host here). It needs the port forward of C/D. Without it: accept the risk, or ask someone at the new site for a power cycle.

## Test before it leaves (proposal)

1. Install and join both machines; `ssh pc-gate hostname` over `100.x` = GW3M710.
2. Move pc-gate onto a phone hotspot (a different network, behind NAT), and repeat step 1 from f22. Check `tailscale status` and see whether the link is direct or relayed.
3. Reboot pc-gate while on the hotspot. It must come back without anyone logging in.
4. Pull the network for 10 min, then restore it. SSH must work again within 1 min.

## Owner questions (one at a time, in the reply)

1. Is a third-party service (Tailscale) acceptable? If not: can our router forward one port (options B/C/D)?
2. Is it SSH only, or must pc-gate at the new site also reach the workstation (MQTT 1883, Influx)? With Tailscale, that means installing it on the workstation too, or a subnet route through f22.
