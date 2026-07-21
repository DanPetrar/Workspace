# workstation — Inventory

Verified live 2026-07-21 via `ssh ws`. Update whenever a tool is installed/removed/
reconfigured.

| Tool | Version | Notes vs. old inventory.md (2026-05-27) |
|---|---|---|
| Git | 2.53.0 | unchanged |
| curl | 8.18.0 | unchanged |
| Python 3 | 3.14.4 | unchanged |
| Node.js | 20.20.2 | unchanged |
| Java | OpenJDK 17.0.19 | was 17.0.18 — patch bump |
| Flutter SDK | 3.44.0, `/opt/flutter` | not independently reconfirmed this pass |
| Android SDK | `~/Android/Sdk`, API 36 | not independently reconfirmed this pass |

## Disk (live)

| Mount | Size | Used | Notes vs. old inventory.md |
|---|---|---|---|
| `/` (`nvme0n1p2`) | 233 GB | 49 GB used, 173 GB free | was 27 GB used — grown ~22 GB since 2026-05-27 |
| `/workspace` (`sda`) | 220 GB | 1.3 GB used, 207 GB free | was ~39 MB used — grown, still mostly empty |

## Data stack

InfluxDB, Grafana, Mosquitto, and the parser services are covered in
`nodes/workstation/status.md` (they're services, tracked there) rather than duplicated
here as "installed tools."
