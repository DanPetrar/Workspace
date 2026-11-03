# Fable's opinion: Tailscale for remote SSH from f22 to pc-gate (2026-11-03)

Owner's words: "i consider tilescale. ask fable his opinion on this topic."
Input read: `nodes/f22/pc-gate-remote-ssh-proposal-20261103.md`. Nothing was contacted or installed.

## Verdict

Tailscale is the right choice for this job. pc-gate will sit behind a router we do not control, it only needs SSH, and nobody will be on site. Tailscale needs only outbound traffic from pc-gate and nothing on either router, so it is the cheapest working option. I agree with recommendation A and with keeping OpenSSH as the login.

I would change or add six points. Two of them can stop the setup from working, and the proposal does not cover them yet (points 2 and 3).

## Points

**1. Join pc-gate as a tagged device, not as the owner's user device.**
Join it with a pre-auth key and a tag, for example `tag:gate`. Tagged devices have key expiry off by default, so the 180-day expiry cannot happen even if someone forgets the admin-page switch. A tagged device also does not depend on the owner's login session. The ACL can then name tags instead of devices:

```json
{
  "tagOwners": { "tag:gate": ["autogroup:admin"], "tag:bench": ["autogroup:admin"] },
  "acls": [ { "action": "accept", "src": ["tag:bench"], "dst": ["tag:gate:22"] } ]
}
```

Here f22 (and futro, if wanted) gets `tag:bench`. The default policy allows everything, so this policy has to be written on purpose. The admin page checks its syntax on save.

**2. On pc-gate, keep Tailscale away from DNS: `--accept-dns=false`.**
By default Tailscale (MagicDNS) takes over `/etc/resolv.conf`. pc-gate runs the gateway service, and any name it resolves at the new site would then go through Tailscale's resolver. That is a second, unplanned change to a production device. Without MagicDNS, f22 reaches pc-gate by its `100.x` address in `~/.ssh/config`. That address is stable for as long as the device stays in the tailnet. Use the same flag on f22, unless the owner wants the MagicDNS names there.

**3. The "updates come with unattended-upgrades" line needs a check.**
By default, Debian's `unattended-upgrades` installs only Debian security updates. A third-party repo such as Tailscale's is skipped unless it is added to `Origins-Pattern`. Whether unattended-upgrades is active on pc-gate at all is not in the facts either. The owner should choose one of two:
- (a) Tailscale is updated by hand, over the tunnel, after the same version has run on f22 first. No surprise updates, but someone has to remember.
- (b) Automatic updates (`tailscale set --auto-update`, or the apt origin added). Current security fixes, but a bad release could cut the only path.

I lean to (a) for a single remote unit with only one path in.

**4. Routes: none.**
Do not advertise routes or an exit node on pc-gate. Leave `--accept-routes` off on f22 (it is off by default on Linux). Then the gateway's network and ours stay apart, whatever the ACL says.

**5. A second path that needs no port forward at our site.**
The proposal's fallback (D) depends on a port forward on our router. Two other fallbacks avoid that:
- A small rented VPS (a few EUR/month) as the meeting point: pc-gate runs `autossh -R` to the VPS, and f22 reaches pc-gate through the VPS. This is independent of Tailscale's software and account.
- A second overlay from another vendor (ZeroTier). It costs nothing, but it is one more agent on the gateway.

Without any second path, the residual risks are: tailscaled broken after an update, the Tailscale or GitHub account locked, or the site blocking the traffic. Accepting those is a valid choice. It should be written down as a decision.

**6. Account security.**
The GitHub login `DanPetrar` becomes the key to the remote gateway. Its 2FA (GitHub Mobile) is now part of the security of this setup. Optional: "Tailnet Lock" stops even the coordination server from adding devices. It adds key handling, and I would not turn it on for one gateway.

## Site network (ask before it leaves)

Tailscale tries direct UDP first. If UDP is blocked, it falls back to its relays (DERP) over HTTPS on port 443, which almost always passes. It can fail on sites with an intercepting HTTPS proxy or a forced HTTP proxy. One question to the site is enough: "Is outbound HTTPS from this device free, or does it go through a proxy?" Tailscale can use a proxy if one is configured.

## Additions to the test list

- Step 2: `tailscale ping &lt;f22&gt;` shows whether the link is direct or `via DERP`. Record which. A hotspot is usually direct, so the relay path may stay untested. That is acceptable if it is written down.
- After the install: the gateway service still works as before (same name resolution, same MQTT publish). This checks point 2.
- After a reboot: `tailscale status` shows the device online, and no login URL appears in `journalctl -u tailscaled`.

## No change needed

Options B, C and E are described fairly. Not enabling Tailscale SSH is right. The work estimate of about 30 minutes is plausible for the install, but not for the ACL, the tags and the tests; say about 1 h in total. The two owner questions in the proposal are the right ones. I would add a third: "Tailscale updates: by hand (a) or automatic (b)?" (point 3).
