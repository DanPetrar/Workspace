# pigate — Status

**Planned, 2026-09-11.** The node is a bench Raspberry Pi running the PiGate gateway
(polls ZaxModbus units over RS-485 / Modbus, publishes their records to MQTT). The project,
its plan and its code live in the private repo `DanPetrar/PiGate` (`PLAN.md`) — this file
tracks only the node's infrastructure state.

## Boundaries (from the PiGate plan)

- **RS-485:** its own line(s) and units only. Never the gate segments — raspi
  `/dev/ttyUSB0` (CH340 → Unit_A) and futro `/dev/ttyUSB0` (Prolific → Unit-ETH00).
- **MQTT:** publishes to the **futro test broker** (`192.168.20.226`, `:1883` / `:8883`,
  see `nodes/futro/status.md`), on `zax_<ID>_gw/…` test topics. Never the workstation
  production broker.
- **Access:** key-based SSH from raspi and futro, password login off.

## Preparation (plan step P0)

| Step | State |
|---|---|
| Project repo created, plan pushed | ✅ 2026-09-11 |
| Test broker on futro | ✅ 2026-09-11 |
| Waveshare back on the LAN, settings re-checked | ✅ 2026-09-11 — `192.168.20.110` |
| Bench units, lines, Modbus addresses | open — user decision |
| This node entry | ✅ 2026-09-11 |

## Next

Bring-up when the Pi arrives (week of 2026-09-14): OS flashed, DHCP reservation, SSH,
provisioning script run from futro. Update `hardware.md` with live values and set
`nodes/INDEX.md` status to `active` in the same change.
