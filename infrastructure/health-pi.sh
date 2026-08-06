#!/usr/bin/env bash
# health-pi.sh — start-of-session health check for the Pi (192.168.20.225).
# Run locally on the Pi:  bash infrastructure/health-pi.sh
# See INFRASTRUCTURE.md section 1 for what should be running here.
set -u

fails=0
ok()   { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fails=$((fails+1)); }

echo "== Pi health ($(hostname), $(date '+%Y-%m-%d %H:%M')) =="

# Expected services
if systemctl is-active --quiet zax_directory; then ok "zax_directory active"; else bad "zax_directory NOT active"; fi
# mosquitto here is local dev/test-only (no production consumer, see INFRASTRUCTURE.md) — WARN not FAIL if stopped.
if systemctl is-active --quiet mosquitto; then ok "mosquitto active (local dev/test-only)"; else warn "mosquitto NOT active (local dev/test-only, non-critical)"; fi

# Broker port (informational — non-critical broker)
if ss -tln 2>/dev/null | grep -q ':1883 '; then ok "broker listening :1883"; else warn "broker :1883 not listening (local dev/test-only, non-critical)"; fi

# Disk free on /
read -r used_pct avail < <(df -h / | awk 'NR==2{gsub("%","",$5); print $5, $4}')
if   [ "${used_pct:-100}" -ge 90 ]; then bad "disk / ${used_pct}% used (${avail} free)"
elif [ "${used_pct:-100}" -ge 80 ]; then warn "disk / ${used_pct}% used (${avail} free)"
else ok "disk / ${used_pct}% used (${avail} free)"; fi

echo "== $( [ $fails -eq 0 ] && echo 'all checks passed' || echo "$fails check(s) FAILED" ) =="
exit "$fails"
