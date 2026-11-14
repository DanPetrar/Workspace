# Second Futro S940, part 2: missing Claude features and an isolated environment

Fable, 2026-11-14. Completion of `second-futro-usage-fable-20261114.md` (part 1, unchanged).
Analysis only; nothing was installed or changed. No command below was run or tested.

## Short answer

- **The isolated environment and the second S940 are the same thing.** Proxmox on that
  machine, with an internal network that reaches the internet but not the bench LAN, is
  the right place to try every Claude feature. This makes the Proxmox choice of part 1
  stronger: "isolated, throw-away, snapshot before each try" is what it does best.
- **Most missing features are not missing software; they are switched off, not installed,
  or need a browser.** f22 is a machine without a screen and its Claude Code is set up
  narrowly for the bench, on purpose. Keep it so. Add the features in the lab, not on f22.
- **Three things must be isolated, and only two can be:** the network (yes), the keys and
  accounts (yes), what goes to Anthropic (no: every Claude feature sends what it reads
  there; some features also store the result there). So the lab starts with content that
  does not matter.
- **In the isolation phase Claude Code runs inside the lab, not on f22.** f22 gets no key
  to the lab and the lab gets no key to anything. This changes one point of part 1
  (control from f22 over SSH): that comes at the end, as the owner's decision.

## Facts used

| Fact | Source |
|---|---|
| f22 Claude Code version 2.1.325 | `claude --version` |
| f22: no plugin installed; one own skill (`github-workflows`) and one synced from the account | `ls ~/.claude/plugins`, `~/.claude/skills` |
| f22: the claude.ai connectors are switched off by a setting; the one MCP server (jcodemunch) is disabled | `~/.claude/settings.json`, `~/.claude.json` |
| f22: Node is installed; no Chromium, Chrome, Playwright, Docker or Podman | `which` |
| f22 holds keys to much: SSH to futro, workstation, pc-gate; GitHub login; Influx token; the memory directory | `git status` list, CLAUDE.md |
| Bench LAN is 192.168.20.x | `nodes/INDEX.md` |

Not checked: the second machine; the router (VLAN support, DNS address); which Claude
plan the account has and which features that plan includes today. **The feature list
below is from my knowledge of the products, not from a check on this account.** Product
features change often; step 4 of the plan is where each one is confirmed.

## What "Claude features" are, and where each one runs

The point to understand first: the features differ in **where they run** and **what they
can reach**. This table is the map; the lab is for filling in the last column by experience.

| Feature | Runs where | Can reach | Leaves the machine |
|---|---|---|---|
| Claude Code itself (CLI) | the machine it is started on | all that this user can: files, keys, network | what it reads, to Anthropic |
| Skills | same; they are instruction text, sometimes with scripts | same as Claude Code | nothing more |
| Plugins (example: `frontend-design` from the official marketplace) | same; a plugin can bring skills, hooks and MCP servers = code | same as Claude Code | depends on the plugin |
| MCP servers (example: Playwright = a browser Claude drives) | a local process beside Claude Code | what that process can; a browser reaches every address the machine reaches | depends on the server |
| Artifacts, and the Design / Slides / document types | made from Claude Code, **published on claude.ai** | only the content given to it | the page is stored at Anthropic, private until shared |
| Claude Design (claude.ai, in the browser) | Anthropic's cloud; needs only a browser | what is uploaded or linked (files, a GitHub repo) | all of it is there |
| Claude in Chrome (browser extension) | a real Chrome on a machine with a screen | every site that Chrome is signed in to | page content, to Anthropic |
| Claude desktop app, its browser, computer use | a Windows or macOS desktop | that whole desktop | screenshots, to Anthropic |
| Cloud sessions and scheduled agents | Anthropic's cloud, on a copy of a GitHub repo | that repo; **never the LAN** | all of it is there |
| Connectors (mail, drive, calendar, ...) | Anthropic's cloud, as the linked account | that account's data | that data |

Reading of the table for the owner's example: **"Claude design" is two things.** (a) The
web product on claude.ai: it needs no install, only a browser and the account; it is
outside our infrastructure whatever we do. (b) Design work from Claude Code: the
`frontend-design` plugin, the Design artifact type, and a browser that Claude can see
(part 1, proposal 1). (b) is what the lab adds; it is not on f22 today because f22 has no
browser, no plugin, and should stay that way.

## How to improve: suggestions

1. **Do not widen f22.** Its narrow setup protects the bench: fewer tools means fewer
   things a session can do by mistake next to running tests. New features go to the lab.
2. **One feature at a time, with a snapshot before it.** Two features added together
   cannot be understood separately. Rollback returns the lab to the state before.
3. **Order by reach, smallest first:** skills and plugins (text and local code), then the
   local browser (Playwright), then Artifacts and the Design type (content stored at
   Anthropic), then cloud sessions (need GitHub access), then Claude in Chrome (needs a
   desktop), connectors last or never.
4. **Read before installing.** A plugin or MCP server is code that runs with the rights of
   the user. In the lab those rights are worth nothing, which is the reason for the lab;
   still, reading its files first is how the interaction is understood.
5. **Keep a lab journal**, one row per feature tried: what it is, where it ran, what it
   reached, what it sent out, how it is removed, keep or drop. This journal is the
   "complete understanding"; when a row is clear, that feature may leave the lab.
6. **Leave the permission prompts on in the lab** (the default mode, no bypass). Each
   prompt shows one interaction; this is the cheapest way to see what a feature does.

## The isolated environment

### What is isolated from what

| Boundary | How | Check |
|---|---|---|
| Lab cannot reach the bench LAN (units, f22, futro, workstation, router pages) | internal Proxmox bridge with no network port; NAT to the internet; a firewall rule that drops 192.168.20.0/24 | from the lab: `ping 192.168.20.11` fails, `curl https://api.anthropic.com` answers |
| Lab cannot reach the Proxmox host | firewall: no access from the lab network to host ports 22 and 8006 | from the lab: both ports closed |
| Lab holds no keys | a new container has an empty home: no SSH keys, no GitHub login, no Influx token, no bench memory, no bench CLAUDE.md. Nothing is copied in from f22 | `ls -la ~/.ssh ~/.claude` in the new container |
| Bench sessions do not drive the lab | no SSH key from f22 or futro to the Proxmox host or the lab, in this phase | `ssh` from f22 asks for a password |
| The account is the same | cannot be separated without a second account: the lab logs in to the same Claude account as f22. So in the lab: connectors stay off (the same setting as on f22); GitHub access only to one test repo |
| Anthropic sees the lab content | cannot be isolated | use only test content in the lab at first |

The owner still sees the lab pages: from his PC, an SSH tunnel through the Proxmox host
(`ssh -L 8080:<lab address>:8080 root@<proxmox>`). The direction is LAN to lab only; the
lab cannot open a connection back.

### Why this is enough, and its limits

- A container on a closed network with no keys can damage only itself, and a snapshot
  undoes that. This holds for Claude Code, for a plugin, for a browser Claude drives.
- Limit 1: an unprivileged container shares the kernel with the Proxmox host. This is a
  good boundary for this purpose, not a perfect one. Anything with a desktop (Claude in
  Chrome) goes in a small VM, which is a stronger boundary and fits a desktop better.
- Limit 2: the firewall is one rule on one machine. It is checked after every Proxmox
  update and after every network change (the checks of the table above, 1 minute).
- Limit 3: the Proxmox host itself stands on the bench LAN. Claude Code is never
  started on the host, only inside the lab.

### RAM plan (16 GB)

Proxmox host 2 GB; lab container (Claude Code + Node + headless browser) 4 GB; later a
desktop VM 4 GB, started only when used; later the service copy of part 1 proposal 2,
2-3 GB. About 3 GB stay free.

## Steps

Each step has one check. Steps 1-3 are the owner's hands on the new machine (or mine
over SSH only if he decides so; then step 3's "no key from f22" is broken for that time
and the key is removed after). No step touches f22, futro, the workstation or a unit.

| # | Step | Check |
|---|---|---|
| 1 | Install Proxmox VE 9, ext4 + LVM-thin, address on the bench LAN (reserved in the router as for f22). Set the no-subscription source, update. | web page on port 8006 opens |
| 2 | Add the internal bridge (`vmbr1`, no port, example 10.10.10.1/24) with NAT to the internet. The Proxmox network manual has this case under "Masquerading (NAT)". | a test container on `vmbr1` reaches the internet |
| 3 | Firewall: from 10.10.10.0/24 drop everything to 192.168.20.0/24 and to the host itself. DNS for the lab = a public DNS server, so that no exception to the router is needed. | the two checks of the first table row; ports 22 and 8006 of the host closed from the lab |
| 4 | Create container `lab1` (Debian 13, unprivileged, 4 GB, on `vmbr1`). Install Claude Code, log in. Settings: connectors off, default permission mode. Snapshot `clean`. | `claude` starts; home has no keys; snapshot listed |
| 5 | Feature 1: Node + Playwright + headless Chromium, and a small test page. Claude builds the page, takes a screenshot, corrects it. The owner watches it through the tunnel. Journal row. Snapshot. | a screenshot file exists and Claude describes it correctly |
| 6 | Feature 2: the `frontend-design` plugin (read its files first). Same test page, with and without it. Journal row. Snapshot. | two versions of the page to compare |
| 7 | Feature 3: Artifacts and the Design type from Claude Code, with test content only. Look on claude.ai at what appeared and who can see it. Delete one. Journal row. | the page is private; delete works |
| 8 | Feature 4: Claude Design on claude.ai from the owner's browser, with a test page; then pass its result to Claude Code in `lab1`. This shows how the web product and the lab meet. Journal row. | the design arrives in `lab1` as files |
| 9 | Only if wanted: a test GitHub repo (new, empty, nothing of Zax in it), access for that repo only; then one cloud session and one scheduled agent on it. Journal row. | the GitHub access list shows one repo |
| 10 | Only if wanted: desktop VM with Chrome, a Chrome profile signed in to nothing except Claude; Claude in Chrome on the lab test page. Journal row. | Chrome has no other sign-in |
| 11 | Review the journal. For each feature: keep in the lab, bring to real work, or drop. | the owner's decision per row |

Time: steps 1-4 about half a day, most of it the install and the firewall checks. Steps
5-8 about an hour each. Steps 9-10 are optional and can wait weeks.

## Leaving the isolation

This is the owner's decision, one opening at a time, each with its own reason written in
the journal. A possible order, from least to most reach:

1. Real (not test) web projects enter the lab through git, one repo, one key for that repo.
2. The service copy of part 1 proposal 2 is added **inside** the lab network. Data is
   pushed into it from outside (an export from the workstation, copied in by the owner or
   by a bench session); the lab never pulls from the workstation.
3. One firewall exception, read-only and to one port, if a lab page must show live data
   (example: lab to the workstation's InfluxDB with a read-only token). Each exception is
   one line in the firewall and one line in the journal.
4. A key from f22 to the Proxmox host, so that bench sessions can create and roll back
   lab containers (the control described in part 1).

What I would keep closed permanently: the lab never holds a key to f22, futro, the
workstation, pc-gate or the main GitHub login; the lab never reaches a unit; no bench
session rule (CLAUDE.md, memory) is copied into the lab, and no lab plugin is copied to
f22 without its journal row saying "bring to real work".

## What part 2 changes in part 1

- Proposal 1 (web lab) stays the best usage and becomes the first content of the
  isolated lab (steps 5-8).
- Proposal 2 (service copy) stays, but inside the lab network, filled by push (see above).
- Proposal 3 (gateway twin) needs the bench LAN and Tailscale. It does not fit an isolated
  lab. It waits until after the isolation phase, or is dropped.
- "Control from f22 over SSH" moves from the start to the end (opening 4).
- The last paragraph of part 1 (plain Debian if only proposal 1 remains) no longer
  holds: with the isolation wish, Proxmox is the better choice even for one role,
  because of the closed network and the snapshots.
