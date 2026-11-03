# Fable's review: Tailscale plan and owner steps for pc-gate (2026-11-03)

Owner's words: "ask fable to review ths plan and included documents."
Input read: `pc-gate-tailscale-plan-20261103.md`, `pc-gate-tailscale-owner-steps-20261103.md`, `pc-gate-remote-ssh-proposal-20261103.md`, `pc-gate-remote-ssh-fable-20261103.md`. I did not contact any machine or install anything. I did not look anything up on the web. Statements about how Tailscale behaves come from my own knowledge and are marked *(not verified)* where a wrong guess would matter.

## Verdict

The plan is sound and follows the earlier decisions: tagged devices, `--accept-dns=false`, no routes, updates by hand, a second LAN on a different provider instead of a hotspot. The owner-steps document is clear and has safe stop points. Testing on another provider's LAN is better than the hotspot the proposal suggested.

Three points can make Test 2 fail, or break the only path in later, and the plan does not cover them yet (points 1-3). Points 4-6 can make a step fail on the day and are cheap to fix. The rest are small.

## Must fix before the steps that depend on them

**1. pc-gate's address setup is not known, and Test 2 depends on it (before step 6).**
The facts give `192.168.20.90` but do not say whether that is DHCP (a reservation on our router) or a static address set on pc-gate. If it is static, pc-gate gets no working address or gateway on the other LAN. Step 7 then fails for a reason that has nothing to do with Tailscale, and the same thing would happen at the final site. Step 7's check "resolv.conf = the new LAN's DNS" also assumes DHCP. Add a read-only check to step 5 and record the result:
- `ip -4 addr`, `ip route`, and which tool manages the network (`/etc/network/interfaces*`, NetworkManager, or systemd-networkd).
- The same for DNS (static nameserver or from DHCP) and for NTP. If the time server is our workstation, pc-gate has no time source at the new site. That is a side issue for the gateway service, not for the tunnel.

**2. Updating Tailscale over the tunnel can cut the tunnel halfway through the update (Updates section).**
`apt-get install --only-upgrade tailscale` restarts `tailscaled`. That drops the SSH session that is running the upgrade. If dpkg gets SIGHUP mid-configure, the package can be left half-installed with the tunnel down, and nobody is on site. Run the upgrade detached from the session, for example `sudo systemd-run --unit=ts-upgrade sh -c 'apt-get update &amp;&amp; apt-get install -y --only-upgrade tailscale'`. Then reconnect and check `systemctl status ts-upgrade`, `tailscale version` and `tailscale status`. `apt-get update` is also missing before `--only-upgrade` in the current line. Test this once in Test 1, on our LAN, where a failure costs nothing.

**3. The SSH host key prompt will stop step 5 (`ssh pc-gate-ts hostname`).**
f22's `known_hosts` has pc-gate's key under `192.168.20.90`, not under the new `100.x` address. A command run without a terminal will fail at the "unknown host" prompt, or the key gets accepted without being checked. Put `HostKeyAlias 192.168.20.90` in the `Host pc-gate-ts` entry so the key already checked is reused. Keep `StrictHostKeyChecking` at its default.

## Fix to avoid a failure on the day

**4. `tailscale up` blocks until the login is done (step 3).**
The command prints the link and then waits *(not verified: whether it waits forever or times out)*. Run over SSH, it holds the session, and the plan does not say how both links get into one reply. Possible ways: run it detached, or with `--timeout`, then read the link with `tailscale status`, which shows "Log in at: …" *(not verified)*. Write the chosen way into step 3.

**5. `autogroup:admin` as tag owner (step 2).**
I am not sure that `autogroup:admin` includes the tailnet **Owner** role on a personal account *(not verified)*. If it does not, `--advertise-tags` is refused at step 3/4. The owner's login e-mail appears in the policy he pastes, so put it in `tagOwners` next to or instead of `autogroup:admin`. That removes the doubt. The 4.1 fallback still covers it, but it costs a round trip.

**6. sshd and firewall on pc-gate not checked (before step 3, read-only).**
Check that sshd listens on all addresses (`ss -tlnp | grep ':22'`, and `ListenAddress` in `sshd_config`). Check whether an nftables/iptables input policy would drop traffic on `tailscale0` (`sudo nft list ruleset`). Either one would make step 5 fail with Tailscale itself working.

## Smaller points

7. **DNS check (steps 5 and 7, Done when).** If `/etc/resolv.conf` is a link to systemd-resolved, Tailscale would change DNS through resolved, and the `diff` would show nothing. Add `readlink -f /etc/resolv.conf` and, if resolved is in use, `resolvectl dns`: `tailscale0` must have no DNS server. Do the same backup and check on f22, since it gets the same flag. In "Done when", "pc-gate's DNS is unchanged" should read "not changed by Tailscale", because on the new LAN DHCP changes it on purpose.
8. **A check was dropped without a note.** My earlier test list had "gateway service still works (name resolution, MQTT publish)". With no gateway service running, that check cannot run. The plan should record it as NOT TESTED, not leave it out.
9. **Reboot check (step 5).** Add `systemctl is-enabled tailscaled` (= enabled).
10. **`tailscale ping pc-gate` (steps 5, 7).** Use the `100.x` address, so the result does not depend on how names resolve with `--accept-dns=false`.
11. **Account security.** The Google account now opens the remote gateway, not GitHub as in the proposal. Its 2FA belongs in the recorded risk line next to "no second path".
12. **Optional, cheap.** A `"tests"` block in the policy, e.g. `{"src":"tag:bench","accept":["tag:gate:22"]}`, lets the admin page reject a policy that would cut f22 off when it is saved. That matters most in step 2b *(not verified for the `grants` form)*.
13. **Rollback.** On pc-gate, roll back only while it is on our LAN. Over the tunnel, the rollback cuts the path it runs on. `apt-get purge` instead of `remove` also deletes `/var/lib/tailscale`.
14. **Security updates on pc-gate.** `unattended-upgrades` is inactive, so pc-gate currently gets no Debian security updates at all. The proposal's line "unattended security upgrades stay on" was wrong. This does not affect the tunnel. It is one line for the owner to decide, not part of this plan.
15. **Single client.** Only f22 can reach pc-gate. If f22 is down, nobody can. Giving futro `tag:bench` as well costs one `tailscale up`. That is the owner's choice, and the proposal already offered it ("futro, if wanted").

## Owner-steps document

- **2b.6:** "paste the backup from step 4 back" is wrong. Step 4 makes no backup. It should be the file from 2b.4, `tailscale-policy-before-2b-20261103.json`.
- **Time for step 4:** the plan says ~3 min, the owner steps say ~5 min. Use one value.
- **4.1 fallback:** after approving without the tag, the device is a user device with key expiry on until the tag is set in 4.4. The document handles this already (4.4.3 repeats the expiry check). No change needed.
- Everything else (stop-and-describe rule, backup before every policy change, WAN/LAN port note, power-off wait and "still on" case) is good as written.

## No change needed

The tags with interactive login are right: no auth key secret goes through the chat. So are `--accept-dns=false` on both machines, no routes, no exit node and no Tailscale SSH. Restricting allow-all before pc-gate leaves (2b) is right, as is asking first about other users of the tailnet. So is recording "direct" or "via DERP" and writing down that the other path stays untested. The 10-min cable pull with a 1-min reconnect limit is right too. Test 2 is still a stand-in for the final site: first contact there is the real check, and the plan should say so in one line.
