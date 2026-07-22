#!/usr/bin/env bash
# health-futro.sh — start-of-session health check for the Futro coordinator (192.168.110.8).
# Run locally on the Futro:  bash infrastructure/health-futro.sh
# See INFRASTRUCTURE.md / nodes/futro/status.md for what should be in place here.
set -u

fails=0
ok()   { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fails=$((fails+1)); }

echo "== Futro health ($(hostname), $(date '+%Y-%m-%d %H:%M')) =="

# Coordinator tooling
export PATH="$HOME/.local/bin:$PATH"
if command -v claude >/dev/null 2>&1; then ok "claude CLI present ($(claude --version))"; else bad "claude CLI NOT found"; fi
if gh auth status >/dev/null 2>&1; then ok "gh authenticated"; else bad "gh NOT authenticated"; fi

# Reach the other nodes
if ssh -o BatchMode=yes -o ConnectTimeout=5 ws 'echo ok' >/dev/null 2>&1; then ok "ssh ws reachable"; else bad "ssh ws NOT reachable"; fi
if ssh -o BatchMode=yes -o ConnectTimeout=5 bench 'echo ok' >/dev/null 2>&1; then ok "ssh bench reachable"; else bad "ssh bench NOT reachable"; fi

# Role boundary — testing-station tooling must NOT be here
if command -v arduino-cli >/dev/null 2>&1 || command -v esptool.py >/dev/null 2>&1 || [ -f "$HOME/boards.json" ]; then
  bad "testing-station tooling present on futro (role boundary violated)"
else
  ok "role boundary held (no arduino-cli/esptool/boards.json)"
fi

# Disk free on /
read -r used_pct avail < <(df -h / | awk 'NR==2{gsub("%","",$5); print $5, $4}')
if   [ "${used_pct:-100}" -ge 90 ]; then bad "disk / ${used_pct}% used (${avail} free)"
elif [ "${used_pct:-100}" -ge 80 ]; then warn "disk / ${used_pct}% used (${avail} free)"
else ok "disk / ${used_pct}% used (${avail} free)"; fi

echo "== $( [ $fails -eq 0 ] && echo 'all checks passed' || echo "$fails check(s) FAILED" ) =="
exit "$fails"
