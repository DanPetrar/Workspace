# Session close 2026-11-03 (afternoon): Tailscale f22 -> pc-gate working

Results per step: `pc-gate-tailscale-plan-20261103.md`.

- pc-gate on the owner's separate LAN (192.168.111.127, no RS-485 adapter); `ssh pc-gate-ts` PASS, direct path; reboot PASS; isolation from Windows PASS.
- NOT TESTED: 2.5 Windows check (owner, later), step 8 (owner `skip 8`), session drop during an update, DERP path.
- Not committed: plan result lines, this note.
- Open for the owner: review 14 (pc-gate security updates), review 15 (futro as `tag:bench`), WISHLIST item pick.
- Rule 9: owner correction 11-03: no long shell commands with large text for approval; records via short Edit/Write calls.
