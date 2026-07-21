# workstation — Status

Succeeds the old `Workstation` repo's `STATUS.md` (which was, in practice, almost
entirely about this node). Service states re-verified live 2026-07-21 via `ssh ws`
(`systemctl is-active`), not copied from the old file's 2026-06-22 date.

## Services (all confirmed active, live)

| Service | Role |
|---|---|
| `influxd` | InfluxDB v2.7.11 — org `zax`, buckets `zaxenergy` + `zaxmodbus` |
| `grafana-server` | Grafana — http://192.168.110.11:3000 |
| `mosquitto` | MQTT broker, `:1883`, anonymous — the fleet-wide permanent broker |
| `zaxmodbus-parser` | 12-board ZaxModbus fleet, MQTT → InfluxDB `zaxmodbus` |
| `zax-parser` | Unit_A/C ZaxEnergySurvey-era data → InfluxDB `zaxenergy` |
| `cal_collector` | EnergyCalibrator bench data → SQLite |
| `cal_reports` | Session UI + PDF reports — http://192.168.110.11:8080 |
| `cal-parser` | EnergyCalibrator → InfluxDB |

## Quick reference

| Item | Value |
|---|---|
| SSH | `ssh ws` (`dan-linux`, key-based, passwordless sudo) |
| Grafana | http://192.168.110.11:3000 — admin `zaxenergy2026` |
| InfluxDB | http://192.168.110.11:8086 — org `zax`, buckets `zaxenergy`, `zaxmodbus` |
| MQTT broker | `192.168.110.11:1883` (anonymous) |
| Session UI | http://192.168.110.11:8080 |
| ZaxModbus parser | `/opt/zaxmodbus-parser/zaxmodbus_parser.py` |
| Grafana password reset | stop `grafana-server` → `grafana cli --homepath /usr/share/grafana admin reset-admin-password zaxenergy2026` → start it again |
| InfluxDB CLI org | always `--org zax` |

## Recent history (carried over, unverified beyond what's stated)

- 2026-06-22: Fleet expansion to 12 ZaxModbus boards (Board_11/12 added), parser +
  Grafana dashboards + Pi poller all updated to match.
- 2026-06-03: Pi→Workstation migration completed — all permanent services moved here.
