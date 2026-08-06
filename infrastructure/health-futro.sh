#!/usr/bin/env bash
# health-futro.sh — start-of-session health check for the Futro coordinator (192.168.20.226).
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

# Toolchain parity — futro is supposed to have full dev-toolchain parity with raspi
# (setup-plan.md amendment 2026-07-22; supersedes the old negative role-boundary check).
if command -v arduino-cli >/dev/null 2>&1 && arduino-cli core list 2>/dev/null | grep -q '^esp32:esp32'; then
  ok "arduino-cli + esp32:esp32 core present ($(arduino-cli version 2>/dev/null | head -1))"
else
  bad "arduino-cli / esp32:esp32 core missing (toolchain parity not met)"
fi
if [ -L "$HOME/boards.json" ]; then
  ok "boards.json is a symlink (sshfs-backed, single-authority on raspi)"
elif [ -f "$HOME/boards.json" ]; then
  bad "boards.json is a local file, not a symlink into the sshfs mount"
else
  bad "boards.json missing"
fi

# Disk free on /
read -r used_pct avail < <(df -h / | awk 'NR==2{gsub("%","",$5); print $5, $4}')
if   [ "${used_pct:-100}" -ge 90 ]; then bad "disk / ${used_pct}% used (${avail} free)"
elif [ "${used_pct:-100}" -ge 80 ]; then warn "disk / ${used_pct}% used (${avail} free)"
else ok "disk / ${used_pct}% used (${avail} free)"; fi

echo "== $( [ $fails -eq 0 ] && echo 'all checks passed' || echo "$fails check(s) FAILED" ) =="
exit "$fails"
