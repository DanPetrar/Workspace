# I-001 — InfluxDB configuration for ZaxEnergy

_Recorded: 2026-05-27_

---

## Server

| Item | Value |
|------|-------|
| Version | v2.7.11 |
| Health endpoint | http://localhost:8086/health → status: pass |
| Service | systemd `influxdb.service`, enabled, active |

---

## Organisation

| Item | Value |
|------|-------|
| Org name | `zax` |
| Org ID | `502e8023871a356d` |

> Note: the org was named `zax` during initial setup (not `zaxenergy`). The `zaxenergy` bucket lives under this org. No rename was done — downstream tasks (I-002, I-003) should use `--org zax`.

---

## Bucket

| Item | Value |
|------|-------|
| Bucket name | `zaxenergy` |
| Bucket ID | `975739caf95db441` |
| Retention | infinite (no expiry) |

---

## API token — ZaxEnergy parser + Grafana

| Item | Value |
|------|-------|
| Token ID | `10c635798e674000` |
| Description | ZaxEnergy parser + Grafana |
| Permissions | read + write on bucket `975739caf95db441` only |
| Token | `REPLACE_WITH_TOKEN_FROM_I-001` |

---

## Verification

Write test, read-back, and delete all passed on 2026-05-27.

---

## Quick reference for other tasks

```bash
INFLUX_ORG=zax
INFLUX_BUCKET=zaxenergy
INFLUX_TOKEN=REPLACE_WITH_TOKEN_FROM_I-001
INFLUX_URL=http://localhost:8086
```
