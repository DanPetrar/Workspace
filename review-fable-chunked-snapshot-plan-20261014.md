# Review: fix E, snapshot in small pieces (Fable, 2026-10-14)

Read-only review. Sources: `SecSnapDelta.h`, ZaxCommon `SegRingBuf.h` / `Snapshot.h` / `BoardProfile.h`, `ZaxModbus.ino`
and `WebUI.h` at da3f55e, core 3.3.7 (`HardwareSerial.cpp`, `libraries/FS/src/vfs_api.cpp`, prebuilt `sdkconfig`),
`snaptest-20261014/t1.db,t2.db`, overnight `counters.jsonl`. Nothing built, flashed or contacted.

## Verdict
The plan is right in shape. Two points are wrong and would ship bugs: the ring margin in step 2 (120 is far too small),
and the keyframe rule while the window shifts. The quiet-window rule and the abort list can be simpler. Effort ~1 day holds.

## Facts that decide the design
- **When flash is touched.** `File` = stdio `FILE*` with `setvbuf(..., 4096)` (`vfs_api.cpp:22,250`). LittleFS:
  `CACHE_SIZE 512`, `WRITE_SIZE 128`, block 4 KB. So `f.write` only copies to RAM until 4 KB collect; then one
  `lfs_file_write` of 4 KB = about 1 block erase + 32 small programs. Measured: ~40 ms per 4 KB (2.7-3.2 s / ~80 blocks).
  **Between two calls nothing is pending on flash.** Flash is touched only inside write (on a 4 KB boundary), close,
  remove, rename.
- **Worst single blocking op = one 4 KB sector erase** (typ. ~45 ms, NOR datasheet maximum a few hundred ms).
  `SPI_FLASH_YIELD_DURING_ERASE=y` only helps multi-sector erases; LittleFS erases one block at a time.
  `close()` = flush of the last <4 KB + metadata commit (sometimes a metadata compaction = 1 more erase).
  `remove`/`rename` = one metadata commit each (remove does not erase the file blocks; that happens later, when they are reused).
- **`f.flush()` per chunk: do not.** `flush()` = `fflush` + `fsync` (`vfs_api.cpp:352-358`) = one LittleFS metadata commit
  per chunk: extra time and wear, no gain (see the first point). Instead, end each chunk right after a 4 KB boundary.
- **The ring is full and saw-tooths.** Overnight: `sec_cnt` 18,235 < `snap_sec_recs` 18,733. So the snapshot covers the
  whole ring. `rps` = 862 (64 KB / 76 B). A push that fills the newest segment drops the **862 oldest records at once**
  (every ~14.4 min). A ~25 s pieced write hits that in ~3 % of snapshots.
- **Push counter:** `SegRingBuf` has none. Its fields `fill`, `rps`, `usedSegs`, `segAlloc` are public, so no lib change
  is needed for the margin rule. `get(age)` already returns false for a dropped record.
- **PSRAM buffer option is not possible:** the file is ~300 KB, `psram_free` 244,752 B. Freeing it means 5 fewer sec
  segments (-4,310 records of depth). Drop that option.
- **WDT / keepalive:** task WDT 5 s, idle CPU0 only, the loop task is not subscribed (no `enableLoopWDT`).
  The Modbus slave runs in its own task on core 0. Pieces make all of this better than the 3 s stall today, not worse.
- **Gap baseline (for step 5):** outside the stalls, the largest MQTT sec arrival gap was 1,181 ms (T1) and 1,078 ms (T2).
  No gaps between 1.2 and 1.5 s. All 21 / 32 gaps >1.5 s are stalls (2.76-3.28 s).

## Per step
**1 State machine: keep, change the budget and the trigger.** Risk: medium.
- Chunk = encode records until **2 stdio 4 KB boundaries have passed** (~2 erases, ~100-120 ms), or 150 ms, whichever comes
  first. Check the time between records only. Overshoot is at most one op. Bytes-based chunks are deterministic, and the
  host test can check them. Expected: ~80 blocks / 2 = ~40 chunks = ~40-45 s per snapshot (one chunk per second).
- Trigger: **no byte timing.** Use the existing cue: run one chunk in the pass after `gSnapCue` is set, only if
  `Serial1.available() == 0`, and for cue 1 (T line) only if `gSecSinceMin` is not 59-61 (the minute burst follows that T).
  Cue 2 (W line) is always allowed. "50 ms since the last byte read" measures loop time, not arrival time: the same
  trap as fix 3 earlier. Do not use `onReceive(cb, true)` for timestamps: it sets RX-FIFO-full back to 120
  (`HardwareSerial.cpp:217-219`), which undoes fix B.
- Leftover risk: a loop pass held up 0.3-0.85 s (WiFi/MQTT) starts a chunk late in the second. T3 counts this (`uart_ovf`).
- Fit search in one go: keep. It is CPU only, so the UART ISR runs, and the 1024 B ring holds ~7 s. Log its ms (`fit_ms`)
  so the number is known.

**2 Window pinning: keep the idea, fix two rules.** Risk: high if left as is.
- "keep <= cnt - 120" is wrong. A recycle removes 862, not 1. Rule: the window survives the next recycle only if
  `keep <= cnt - rps`. If the ring is full (`usedSegs == segAlloc`), `keep > cnt - rps` and `rps - fill < 120`:
  **postpone the start** until the recycle is past (at most 2 min, no depth lost). Backstop: `get(a + pushes)` false -> abort, retry next cue.
- **Keyframe cadence must use the PINNED age** (`a % 60`), and the read must use `a + pushes`. Read with the shifted age for
  both, and the keyframes move. The file then no longer matches what the fit search priced, and it can exceed `avail`.
- Push counter: one `uint32_t` in the sketch, next to `secBuf.push` (`ZaxModbus.ino:2299`; demo `:786` never snapshots).
  The owner decides between this and one field in `SegRingBuf::push` (shared lib, correct by construction).
  **Add a self-check either way:** at start, keep `ts0` = ts of age 0. Before each chunk and before the rename, require
  `get(pushes, r) && r.ts == ts0`. This catches a missed counter, and every `clear()` (`WebUI.h:2132,2219`,
  `ZaxModbus.ino:1697,2013`), without touching those 4 sites.
- Min snapshot: **do not split it.** ~25 KB (~7 blocks, ~300 ms), and the min ring only changes at W. Write it in one go
  in the window after a W (cue 2). Keep ZaxCommon `_snapWrite` unchanged.
- `close()` in its own window. **`remove(dst)` + `rename` always in the same pass.** Split them, and a brownout in
  between (it happened, overnight `reset_reason: brownout`) leaves only `.tmp`.

**3 Abort in the sync paths: keep, simplify.** Risk: low.
- Put the abort at the top of `zaxSnapshotSave` (one place covers `:909,1477,1977,2196,2223,2235`, `WebUI.h:2173,2206`).
  The hourly trigger must call the pieced path, not this one. Abort = `close` (flushes <4 KB, ~50 ms) + `remove(tmp)`.
- Correction: OTA (`WebUI.h:2447`) and `/api/restart` (`WebUI.h:2101`) do not snapshot today. With pieces, nothing
  changes there: the old `.bin` stays valid. Side finding (not for this fix): those restarts lose up to 1 h of sec data,
  as today.
- `resize()` (`:2045`) drops only the oldest records -> the `get` backstop aborts. No extra code.

**4 Host test: keep, add the cases below.** Stub `LittleFS.h` needs: an open file kept across calls, a counter for
4 KB boundaries, `flush`/`rename` as today.
- H1 pieced, no pushes == one-shot file, byte-identical (unitB_realload.csv + a synthetic ring of 18,964 records = 22 segs full).
- H2 1 push per chunk, 45 chunks: file == one-shot of a copy of the ring taken at start, byte-identical; size <= `avail`.
- H3 a start with `rps - fill` < 120 on a full ring: start postponed; then the file == the one-shot after the recycle.
- H4 a forced recycle in the middle (counter check off): abort, `.bin` unchanged, no `.tmp`.
- H5 `clear()` between chunks, and between close and rename: abort, `.bin` unchanged (the rename must not run).
- H6 abort via `zaxSnapshotSave` in each phase (write / closed / before rename): the sync file == the plain one-shot.
- H7 `secSnapLoad` of the H2 file: `keep` records, newest ts == `ts0`.

**5 Bench T3: keep, sharpen the criteria.** `SNAP_TEST=1` (start at set 58), 30 min, the trigger must not start a second
snapshot while one runs. Add `snap_chunks`, `snap_chunk_max_ms`, `snap_skip_busy` (chunks skipped because of
`available()>0`), `fit_ms` to sysinfo.
Pass: `uart_ovf` +0, `uart_buf_full` +0; lost sec / min sets +0, `rejected_lines` +0; max sec MQTT arrival gap <1.3 s
(baseline 1.18 s; the plan's 1.5 s is loose); `snap_chunk_max_ms` <300; snapshots completed >= 25 of ~30;
`snap_last_ms` (wall time) <60 s. After one `/api/restart`: restored count == the last `snap_sec_recs`, and the newest
restored ts == the record from the snapshot start, checked in `t3.db`. The abort under a real power-fail stays host-tested
only, unless the owner wants one pull of the power during a running snapshot.
T3 at no load does not show the >128 B sec burst. Only `snap_chunk_max_ms` and the timing of the chunks show that it
would hold. The real proof is the swap with the real load.

## Order and effort
1 host harness + resumable encoder (H1-H2) -> 2 pin/postpone/self-check (H3-H5) -> 3 abort in `zaxSnapshotSave` (H6)
-> min in the W window -> 5 bench. Code ~3-4 h, host tests ~2-3 h, T3 ~1 h with analysis: ~1 day, as estimated.
Rejected: append-only/segment files (format change FMT 4, 2-3 days; it would also make the power-fail dump smaller,
so it is a WISHLIST candidate), PSRAM buffer (no room), `flush()` per chunk (wear, no gain).
