# Plan: Tailscale for remote SSH f22 -> pc-gate (2026-11-03)

Base: `pc-gate-remote-ssh-proposal-20261103.md` + `pc-gate-remote-ssh-fable-20261103.md`. Review applied (owner `apply`): `pc-gate-tailscale-plan-review-fable-20261103.md` points 1-13 + owner-steps corrections; points 14, 15 wait for the owner.
Owner decisions: Tailscale (owner's existing account, Google login); updates by hand (Fable 3a); Test 1 on the local LAN, then Test 2 with pc-gate on a separate LAN with another internet provider. Second path (Fable point 5): none unless the owner says so.
**Recorded risk:** one path in, one client (f22). Lost if tailscaled breaks, the Tailscale account or the **Google account** is locked (its 2FA now protects the remote gateway), or the site blocks the traffic. Test 2 stands in for the final site; first contact there is the real check.

Owner steps in detail: `pc-gate-tailscale-owner-steps-20261103.md` (same step numbers).

## Facts (read 2026-11-03)

- f22 (192.168.20.222) and pc-gate = GW3M710 (`gw2mqtt@192.168.20.90`): Debian 13, passwordless sudo, no Tailscale yet.
- **pc-gate network (review 1):** ifupdown, `enp0s31f6 inet dhcp` (no fixed address set on pc-gate), default route 192.168.20.1 from DHCP. NetworkManager, systemd-networkd, systemd-resolved inactive. `/etc/resolv.conf` is a plain file written by DHCP (`nameserver 192.168.20.1`). Time: systemd-timesyncd, no `NTP=` set = Debian default pool (works at any site). -> it takes the address, DNS and time from the new LAN by itself.
- **pc-gate sshd (review 6):** listens `0.0.0.0:22` and `[::]:22`, no `ListenAddress`. **Firewall:** nftables `inet filter`, input policy drop, `tcp dport 22 accept` on every interface (also `tailscale0`), `established,related accept`, output accept. -> no change needed for SSH over Tailscale.
- f22: `/etc/resolv.conf` plain file, NetworkManager and systemd-resolved inactive.
- pc-gate: `unattended-upgrades` inactive (no Debian security updates at all: review 14, owner's decision), no extra apt repos, no gateway service running.
- Not verified: `autogroup:admin` covers the Owner role (review 5: the owner's e-mail is added as tag owner too); the `tests` block form for a `grants` policy (review 12).

**Done when:** from f22, `ssh pc-gate-ts hostname` = `GW3M710` with pc-gate on the other provider's LAN; the link survives a reboot and a 10-min cable pull; DNS on both machines not changed by Tailscale (on the new LAN, DHCP changes pc-gate's DNS on purpose).

---

## Test 1: local LAN

### Step 1 (me): install on f22 and pc-gate, ~5 min
Per machine: `cp /etc/resolv.conf ~/resolv.conf.pre-tailscale`, then
```
curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt-get update && sudo apt-get install -y tailscale
```
New files only, nothing is replaced. Check: `tailscale version` on both (same version); `systemctl is-enabled tailscaled` = enabled.

### Step 2 (owner + me): access policy with isolation, ~15 min (steps 2 and 2b merged, owner 2026-11-03)
Owner `yes` 2026-11-03: the Windows machines and the f22 <-> pc-gate link are isolated both ways. Owner answers the exit-node / subnet-router question (owner steps 2.3), backs up the policy and pastes it to me. I return the complete new text, in the policy's own form (`acls` or `grants`), replacing any allow-all:
- `tagOwners`: `tag:gate`, `tag:bench` -> `["autogroup:admin", "<owner's login e-mail from the pasted policy>"]` (review 5);
- access rules, exactly:
  - `autogroup:member` -> `autogroup:self:*` (the 3 Windows machines reach each other; all use the owner's account);
  - `tag:bench` -> `tag:gate:22` (f22 -> pc-gate SSH): `acls` `{"action":"accept","src":["tag:bench"],"dst":["tag:gate:22"]}`, or `grants` `{"src":["tag:bench"],"dst":["tag:gate"],"ip":["tcp:22"]}`;
  - nothing else (no rule from the tags to user devices, none from user devices to the tags); plus an exit-node / subnet-router rule only if the owner's answer or the pasted policy shows one is used;
- `tests` block (review 12): `{"src":"tag:bench","accept":["tag:gate:22"]}` and `{"src":"<owner e-mail>","deny":["tag:gate:22","tag:bench:22"]}`, so a later save that cuts f22 off or lets a Windows machine in is refused. If the page refuses the block itself, it is removed and noted here;
- every other part of the pasted policy kept as it was, and one line listing what was replaced.
Owner replaces the text, saves (2.4), and checks one Windows machine (2.5).

### Step 3 (me): join both, ~2 min
The join waits for the login, so it runs detached from the SSH session (review 4); the link is read from its log:
- pc-gate: `sudo systemd-run --remain-after-exit --unit=ts-up tailscale up --accept-dns=false --advertise-tags=tag:gate --hostname=pc-gate`
- f22: `sudo systemd-run --remain-after-exit --unit=ts-up tailscale up --accept-dns=false --advertise-tags=tag:bench --hostname=f22`
- link: `journalctl -u ts-up --no-pager | grep -o 'https://login.tailscale.com/a/[^ ]*'` on each; both go into one reply.
No `--advertise-routes`, no exit node, no Tailscale SSH; `--accept-routes` stays off (Linux default).

### Step 4 (owner): approve, ~5 min
Owner steps 4.1-4.5. Reply `approved`.

### Step 5 (me): checks, ~10 min
- `tailscale status` on both: both online; `systemctl status ts-up` = active (exited), status 0; then `sudo systemctl stop ts-up`.
- `tailscale ip -4` on pc-gate -> `100.x.y.z`. f22 `~/.ssh/config`:
  ```
  Host pc-gate-ts
      HostName 100.x.y.z
      User gw2mqtt
      HostKeyAlias 192.168.20.90
  ```
  (review 3: reuses the key already checked in `known_hosts`; `StrictHostKeyChecking` stays default.)
- `ssh pc-gate-ts hostname` = `GW3M710`, without a host key prompt.
- DNS, both machines (review 7): `readlink -f /etc/resolv.conf` = `/etc/resolv.conf`; `diff ~/resolv.conf.pre-tailscale /etc/resolv.conf` = no difference; no `100.100.100.100`.
- `tailscale ping <pc-gate 100.x>` from f22 (review 10): expected "direct" (same LAN).
- Reboot pc-gate (`sudo reboot`, by me): `systemctl is-enabled tailscaled` = enabled; online in `tailscale status` within 2 min; no login link in `journalctl -u tailscaled -b`.
- Isolation (step 2 policy): `tailscale ping --icmp <a Windows 100.x>` from f22 and from pc-gate = no reply (policy blocks it). A Windows machine reaching f22/pc-gate is not checked by me (no access to them); the policy `tests` cover it.
- **Update test over the tunnel (review 2), on our LAN where a failure costs nothing:** run the update procedure below on pc-gate through `pc-gate-ts` (with no newer version it reinstalls nothing, so the check is: the unit runs detached, the session may drop, ssh works again within 1 min, `systemctl status ts-upgrade` = active (exited), status 0).
- **Gateway service check (review 8): NOT TESTED** (no gateway service runs on pc-gate now). Result line per check in this file.

---

## Test 2: pc-gate on the other LAN / provider

### Step 6 (me + owner): move
1. Me: `sudo poweroff` on pc-gate over SSH; I reply `pc-gate is off`.
2. Owner steps 6. Reply `moved HH:MM`.

### Step 7 (me): checks, ~5 min
- `ssh pc-gate-ts hostname` = `GW3M710`, within 3 min of power-on.
- `tailscale ping <pc-gate 100.x>`: record "direct" or "via DERP (<city>)". The other path stays untested; written down.
- pc-gate: an address from the new LAN (`ip -4 -br addr`); `/etc/resolv.conf` = the new LAN's DNS from DHCP, no `100.100.100.100`; `timedatectl` = synchronized.
- Reboot by me: back within 3 min.

### Step 8 (owner + me): network cut, ~12 min
Owner steps 8: cable out 10 min, back in. Me: ssh works within 1 min of `back`; `tailscale status` online.

---

## Rollback (any step)
- **pc-gate: only while it is on our LAN** (over the tunnel, the rollback cuts the path it runs on; review 13). f22: any time.
- Machine: `sudo tailscale down; sudo apt-get purge tailscale; sudo rm /etc/apt/sources.list.d/tailscale.list /usr/share/keyrings/tailscale-archive-keyring.gpg` (`purge` also deletes `/var/lib/tailscale`).
- Admin page: owner steps "If something goes wrong" (remove device; restore the policy from the backup file or Configuration logs).

## Updates (decision 3a)
By hand: update f22 first, run it for a day, then pc-gate over the tunnel, detached from the session (review 2):
```
sudo systemd-run --remain-after-exit --unit=ts-upgrade sh -c 'apt-get update && apt-get install -y --only-upgrade tailscale'
```
The SSH session may drop when tailscaled restarts. Reconnect, then check `systemctl status ts-upgrade` (= active (exited), status 0; `--remain-after-exit` keeps the unit so the result can be read), `journalctl -u ts-upgrade`, `tailscale version`, `tailscale status`. Then `sudo systemctl stop ts-upgrade` (and `reset-failed ts-upgrade` if it failed), so the name is free for the next run.

## Owner facts for step 2 (2026-11-03)
- The tailnet has 3 Windows machines, all logged in with the owner's Google account -> `autogroup:self` keeps them reaching each other.
- No Windows machine connects to pc-gate; only f22 does -> the policy gets no rule from user devices to `tag:gate`.
- Exit node / subnet router on a Windows machine: not stated yet; asked in step 2 (the pasted policy is read for it too).

## Open for the owner
- Review 14: Debian security updates on pc-gate (`unattended-upgrades` inactive).
- Review 15: futro as a second client (`tag:bench`).

## Results
- **Step 1 PASS (2026-11-03):** Tailscale 1.104.5 on f22 and pc-gate; `tailscaled` enabled + active on both; `/etc/resolv.conf` unchanged on both (copies in `~/resolv.conf.pre-tailscale`). pc-gate has no `curl` (first try stopped, keyring file left empty): the two repo files were copied from f22 instead (sha256 keyring `3e03dacf…`, list `5a1b21b3…`, same on both). Not logged in yet.
