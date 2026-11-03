# Session close 2026-11-03: Tailscale f22 -> pc-gate, step 1 done

Base: `pc-gate-tailscale-plan-20261103.md` (Done when there). Owner steps: `pc-gate-tailscale-owner-steps-20261103.md`.

## State now
- Tailscale 1.104.5 installed on **f22** and **pc-gate** (GW3M710, `gw2mqtt@192.168.20.90`); `tailscaled` enabled + active; **neither logged in**; `/etc/resolv.conf` unchanged (copies `~/resolv.conf.pre-tailscale` on both). pc-gate has no `curl`: repo files copied from f22 (same sha256).
- Plan decisions: owner's existing tailnet (Google login, 3 Windows machines on his account); tagged devices `tag:gate` / `tag:bench`; `--accept-dns=false`, no routes; updates by hand, detached (`systemd-run --remain-after-exit`); steps 2 + 2b merged: Windows machines isolated both ways from f22 <-> pc-gate; policy `tests` block.
- Committed: Workspace `2194225` (5 documents). **Not committed:** the step 1 result line in the plan, this close note.

## Next
1. **Owner step 2.1-2.3:** reply `exit no` (or exit node / subnet router name) + `2 policy` + pasted policy text. I return the complete new policy (owner steps 2.3-2.4), owner saves, 2.5 Windows check -> `saved, windows ok`.
2. Me step 3 (join detached, two login links) -> owner step 4 -> me step 5 checks -> Test 2 (steps 6-8) on the other LAN.

## Open for the owner
- Fable review 14: Debian security updates on pc-gate (`unattended-upgrades` inactive). Review 15: futro as a second `tag:bench` client.
- Fable's WISHLIST proposal (`ZaxModbus-PS/Doc/WISHLIST-high-no-unit-fable-20261103.md`, pushed `3af0704`): owner picks an item number; ETH00 use needs his decisions (flash, `units.yaml`, pwrfail pin).

## Rule 9
- No memory rule disagreed with `CLAUDE.md` this session. No new CLAUDE.md lines proposed.
