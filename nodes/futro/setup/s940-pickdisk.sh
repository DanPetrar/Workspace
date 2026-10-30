#!/bin/sh
# s940-pickdisk.sh — choose the one internal disk for the S940 install, or block (fail closed).
# Runs in debian-installer (busybox ash) as partman/early_command. Plan: ../s940-stick-plan-v3.md step 4.
# Dry run (on any Linux): s940-pickdisk.sh --dry-run <sysfs root> <cdrom device>  -> prints ACCEPT/REFUSE.

DRY=0; SYS=/sys; CD=
if [ "$1" = "--dry-run" ]; then
    DRY=1; SYS=$2; CD=$3
else
    CD=$(grep ' /cdrom ' /proc/mounts | cut -d' ' -f1)
fi

fail() {
    msg="s940-pickdisk: STOP, no single internal disk found: $1"
    if [ $DRY = 1 ]; then echo "REFUSE: $1"; exit 1; fi
    logger -t s940 "$msg" 2>/dev/null
    # never return: partman must not start without a disk chosen by this script
    while :; do echo "$msg" > /dev/console 2>/dev/null; sleep 30; done
}

# disk holding the installer stick: sdb1 -> sdb, nvme0n1p1 -> nvme0n1
cdisk=${CD#/dev/}
case "$cdisk" in
    nvme*) cdisk=$(echo "$cdisk" | sed -r 's/p[0-9]+$//') ;;
    *)     cdisk=$(echo "$cdisk" | sed -r 's/[0-9]+$//') ;;
esac

n=0; pick=; seen=
for d in "$SYS"/block/sd* "$SYS"/block/nvme*n*; do
    [ -e "$d" ] || continue
    name=${d##*/}
    [ "$name" = "$cdisk" ] && continue
    case "$(readlink -f "$d")" in */usb[0-9]*) continue ;; esac
    n=$((n + 1)); pick=$name; seen="$seen $name"
done

[ $n = 1 ] || fail "$n internal disks:$seen"
gb=$(( $(cat "$SYS/block/$pick/size") / 1953125 ))   # 512-byte sectors -> GB (10^9)
[ $gb -ge 25 ] && [ $gb -le 300 ] || fail "$pick is $gb GB, outside 25-300 GB"

if [ $DRY = 1 ]; then echo "ACCEPT: /dev/$pick ($gb GB)"; exit 0; fi
debconf-set partman-auto/disk "/dev/$pick" || fail "debconf-set failed"
logger -t s940 "s940-pickdisk: install disk /dev/$pick ($gb GB)" 2>/dev/null
exit 0
