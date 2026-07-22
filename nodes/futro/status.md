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

- Full coordinator role (everything `raspi`'s Claude Code session used to do, except
  physically-tied testing-station work)
- No RS-485/USB/serial/GPIO hardware attached — reaches `raspi` via `ssh bench` for
  any testing-station command
- Hosts the coordination Claude Code session going forward

## Open items

- None from bring-up. `raspi`'s pre-existing `mosquitto.service` failure (since
  2026-06-26) is unrelated to this node — see `nodes/raspi/status.md`.
