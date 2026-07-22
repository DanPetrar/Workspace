# futro — Status

Bring-up completed 2026-07-22, run from `raspi`'s Claude Code session per
`setup-plan.md` section 4. Verified live at close of bring-up.

## Services / setup

| Item | State |
|---|---|
| Claude Code CLI | ✅ installed, v2.1.217, `~/.local/bin/claude` |
| `gh` auth | ✅ logged in as `DanPetrar`, protocol `ssh`, scopes `repo, admin:public_key, gist, read:org` |
| git identity | ✅ `DanPetrar` / `delazax@zapptronic.eu`, `init.defaultBranch main` |
| SSH → `ws` (workstation) | ✅ key-based, no prompt |
| SSH → `bench` (raspi) | ✅ key-based, no prompt |
| Project repos (9) | ✅ all cloned, all `git fetch` clean |
| `CLAUDE.md` | ✅ Futro-specific version in place, role split documented on both machines |

## Role in the current fleet

- Full coordinator role (everything `raspi`'s Claude Code session used to do)
- **Full dev-toolchain parity with raspi, added the same day** (user direction,
  Fable-reviewed — see `setup-plan.md` amendment): arduino-cli/ESP-IDF/`flash_guard.py`
  installed, verified via a real compile of ZaxModbus and a live read of the shared
  `boards.json`. See `inventory.md` for detail.
- Co-located with the permanent bench — no RS-485/USB/serial/GPIO hardware plugged
  into futro's own ports yet, but the toolchain is ready for when a board is moved
  over. Reaches `raspi` via `ssh bench` for the permanent bench (Units A-D, RS-485)
  while it stays wired there.
- Hosts the coordination Claude Code session going forward

## Open items

- None from bring-up or the toolchain-parity add. `raspi`'s pre-existing
  `mosquitto.service` failure (since 2026-06-26) is unrelated to this node — see
  `nodes/raspi/status.md`.
