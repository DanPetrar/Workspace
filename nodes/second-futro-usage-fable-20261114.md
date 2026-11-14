# Second Futro S940: best usage and usages to avoid

Fable, 2026-11-14. Analysis only; nothing was installed or changed.

## Short answer

- **Proxmox: yes, a good idea, on one condition:** the machine gets more than one role.
  For a single role, plain Debian 13 (as on f22) is simpler and has one layer less to maintain.
- **Best usage: a web application lab** (proposal 1), with a **test copy of the workstation
  services** next to it (proposal 2). Both run as containers on the same Proxmox.
- **Web UI design: Proxmox itself does not help.** What helps is what runs in it: the
  application plus a headless browser, so Claude Code can see the page it builds.
- **Control from Claude Code on f22: yes**, over SSH, the same way f22 already controls
  futro and the workstation. The raspi could do it too, but it is powered off and has no
  Claude sessions, so in practice it is f22 (or futro).
- **Avoid:** a second backup machine (futro already is one) and a bench inside a VM.

## Facts used

| Fact | Source |
|---|---|
| Second S940: 16 GB RAM, 256 GB SSD | owner's words |
| S940 CPU: Pentium Silver J5005, 4 cores, VT-x present | `lscpu` on f22 (same model) |
| f22: 7.5 GB RAM, bench machine, runs the tests and the builds | `free`, `nodes/INDEX.md` |
| workstation: i3, 8 GB RAM, InfluxDB + Grafana + Mosquitto + parsers, Android emulator | memory `project_workstation` |
| futro (S740): coordinator, toolchain copy, nightly GitHub mirror | `nodes/INDEX.md`, memory |
| raspi: reserve, powered off since 2026-10-31 | `nodes/INDEX.md` |
| Web pages exist today: test journal ws:8091, unit catalog :8092, `~/a4web` | CLAUDE.md, memory, `ls` |

Not checked: the second machine itself (I have no access to it), VT-d (needed only for
PCI passthrough, which no proposal uses), the pc-gate operating system.

The 16 GB is the strong point of this machine: it is twice the RAM of f22 and of the
workstation. The CPU is the weak point: 4 slow cores. So it fits many small, mostly idle
services well, and heavy compute badly.

## Proxmox on this machine

For:
- Several separated roles on one machine. Each container has its own IP, its own packages,
  its own start and stop.
- Snapshot before a change, rollback in seconds after a bad one. This is the main gain for
  experiments: Claude Code can try a thing in a container and the result can be thrown away.
- A new clean Debian container in about a minute, without a USB stick or an install.
- Containers (LXC) cost almost no CPU and RAM overhead. 16 GB is enough for 6-10 of them.
- Proxmox VE 9 is built on Debian 13, the same base as f22: same commands, same habits.

Against:
- One more layer to update and to understand (bridge network, storage, its own web page on 8006).
- Full virtual machines (Windows, Android emulator) will be slow on the J5005. Use containers;
  keep VMs for the rare case.
- One SSD, no redundancy: nothing that must not be lost may live only there.
- The free version shows a "no subscription" notice and needs the no-subscription package
  source set once. No cost.

Install choice I would take: ext4 with LVM-thin (the installer default), not ZFS. ZFS takes
RAM for its cache and gives little on a single disk; LVM-thin already gives snapshots.

How Claude Code controls it: an SSH key from f22 to the Proxmox host. Then `pct` (containers),
`qm` (VMs) and `pvesh` (everything else) do all that the web page does: create, start, stop,
snapshot, rollback, run a command inside a container. Inside a container Claude Code works
over SSH as on any Debian machine. No agent or extra software is needed on the Proxmox side.

## Proposal 1 (best): web application lab

What: one or two containers for web application work. In them: the application under
development, and a headless Chromium driven by Playwright.

Why it helps the user interface work:
- Today Claude Code writes HTML and CSS without seeing the result; `curl` shows text, not
  layout. With a headless browser it takes a screenshot, reads the image, and corrects the
  page. It can do this at phone, tablet and desktop width, and it can click through the
  page and report what broke.
- The owner opens the same page from his own browser at the container's address, while it
  is being built. Both look at the same thing.
- A snapshot before each design variant: two variants can be kept side by side as two
  containers and compared, then one is deleted.

Why on this machine and not on f22:
- A browser takes 1-2 GB RAM and loads the CPU in bursts. f22 has 7.5 GB and runs the
  bench tests, where timing matters (soaks, pollers, serial). Web work on a separate
  machine cannot disturb a running test.
- Node packages and browser builds are many and change often. They stay out of the bench
  machine and out of its toolchain.

Limits: the J5005 renders pages more slowly than a desktop PC; for screenshots and click
tests this is seconds, not a problem. It is not a machine for heavy front-end builds of
large projects.

## Proposal 2: test copy of the workstation services

What: a container with the same InfluxDB, Grafana and Mosquitto versions as the workstation,
with a copy of the dashboards and a small part of the data.

Why:
- The workstation is production for all projects, and changes there need care (the
  intervention policy). An upgrade, a new dashboard, a parser change or an Influx delete
  can first be tried on the copy. A mistake costs a rollback, not data.
- Grafana dashboards are user interface too: this joins proposal 1. New dashboards are
  designed on the copy, with screenshots, then moved to the workstation.
- A test broker on its own address removes the need for extra brokers on bench machines
  for tests (as mq1884 on the raspi was).

Limits: it is a copy for tests, not a second production. The production services stay on
the workstation; moving them to a single-SSD machine gains nothing.

## Proposal 3 (conditional): software twin of the gateway

What: a container or VM that runs the pc-gate software, on the bench LAN.

Why: pc-gate is the Gate focus and sits on a separate LAN, reached over Tailscale. A twin
next to the bench lets gateway software changes be tried before they go to the real
machine, without the remote link.

Condition and limits: I did not check what pc-gate runs. If it is Windows, the twin is a
full VM and will be slow on this CPU; then this proposal is weak. A twin has no RS-485
side unless an adapter is passed to it over USB, which mixes it with the bench. So: only
for the software parts that need no bus. This is the weakest of the three; take it only
if such tests are really missing today.

## Worst usage 1 (avoid): another backup or reserve machine

- futro already is the backup of the bench role (toolchain copy, GitHub mirror), and the
  raspi is the reserve for a rollback. A third reserve adds nothing.
- A reserve machine is off or idle. That wastes exactly what this machine has more of
  than the others: 16 GB RAM.
- A machine with one SSD is also a poor place for the only backup of anything.

## Worst usage 2 (avoid): the bench, or a second bench, inside Proxmox

- Flashing and serial work pass through USB. USB passed into a VM or container adds a
  layer that fails in its own ways (the device re-enumerates at each ESP reset and the
  passthrough can lose it). The bench history already has enough USB faults without it.
- Test timing (pollers, soaks, power-cut tests) would depend on a shared, slow CPU.
- A second place that flashes units splits the `flash_guard.py` / `boards.json` authority,
  which was made single on f22 on purpose.
- f22 does this job well today. Nothing is gained and the proven setup is put at risk.

The same reasoning excludes heavy VMs as the main role (Android emulator, Windows desktop,
build farm): the CPU is too slow, the result would be worse than what the workstation does now.

## Recommendation

Install Proxmox VE 9 (ext4 + LVM-thin). First container: the web lab of proposal 1. Second,
when needed: the service copy of proposal 2. Decide on proposal 3 after the pc-gate
software is looked at. Keep f22, futro, the workstation and the raspi in their present roles.

If, after thinking, only proposal 1 remains wanted: plain Debian 13 from the existing f22
install procedure does it with less to maintain, and Proxmox can still come later.
