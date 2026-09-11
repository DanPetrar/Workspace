#!/bin/bash
# Mirror every DanPetrar GitHub repo into ~/gh-backup. Run nightly from cron.
# ponytail: plain mirrors, --prune propagates remote deletions; add weekly git bundles if that matters.
DEST=~/gh-backup; mkdir -p "$DEST"; cd "$DEST" || exit 1
repos=$(gh repo list DanPetrar --limit 500 --json name --jq '.[].name') || exit 1
fail=0
for r in $repos; do
  if [ -d "$r.git" ]; then git -C "$r.git" remote update --prune || { echo "FAIL $r"; fail=1; }
  else git clone --mirror "git@github.com:DanPetrar/$r.git" || { echo "FAIL $r"; fail=1; }; fi
done
echo "$(date -Is) done: $(echo $repos | wc -w) repos, fail=$fail"
exit $fail
