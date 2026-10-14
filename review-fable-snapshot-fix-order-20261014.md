# Review: PS-Z001 hourly-snapshot losses, fix order and fast verification (Fable, 2026-10-14)

Read-only review. Sources: `ZaxModbus.ino` (branch v1.2.1-newbox, f80e513), `BoxCur.h`, `SecSnapDelta.h`,
ZaxCommon `Snapshot.h` / `FaultMonitor.h`, core `esp32 3.3.7` (`HardwareSerial.cpp`, `esp32-hal-uart.c`,
`tools/esp32s3-libs/3.3.7/sdkconfig`), overnight `report.md` + `counters.jsonl`. Nothing built, flashed or contacted.

## 1. The cause: the hypothesis holds, and the numbers explain the pattern
- Core 3.3.7 prebuilt sdkconfig: `# CONFIG_UART_ISR_IN_IRAM is not set`, `# CONFIG_SPI_FLASH_AUTO_SUSPEND is not set`.
  `uartBegin()` installs the driver with intr flags `0` (`esp32-hal-uart.c:793`). So while a flash op has the
  cache disabled, the UART ISR cannot run. The 128 B hardware FIFO alone takes the bytes (11 ms at 115200).
  Arduino IDE builds cannot change either option.
- Snapshot cost fits erase time: `snap_last_ms` 2712 for `snap_sec_recs` 18733, `lfs_used` 335,872 B. Roughly
  60-70 blocks of 4 KB in 2.7 s, about 40 ms per block. That is one sector-erase time, so the flash spends most
  of the stall in erase with the ISR blocked.
- Burst sizes (lines from the PS-Z001 records): a sec line is 38-40 B, so R+S+T = 114-120 B. **That fits the
  128 B FIFO even with the ISR blocked.** The minute second is R+S+T+U+V+W = about 225 B, **which does not fit.**
  This is why only the minute-second burst loses data (U/V check 2, then R/S missing for the next set). The
  1024 B ring is not involved. The IDF driver resets the FIFO on overflow (IDF source, not in this install),
  so whole lines go missing, not just their tails.
- Your simpler explanations, checked: `read_line()` (128 B, keeps a partial line across calls) is fine. `SetTrack`
  and `faultCheckCycle` only report lines that are really missing. `energyLogAppend` runs after the W line,
  so it is not in the burst. No other cause found.
- **Prediction for the swap with real load:** a loaded sec line is about 45-46 B, so R+S+T is about 135-138 B,
  more than 128. Then every sec burst inside a stall can overflow, not only the minute one. Expect about
  2-3 lost sec sets per hourly stall under load, even after fix 1.
- One more weakness: `HardwareSerial::begin` sets RX-FIFO-full to 120 for baud > 57600. That leaves 8 B (0.7 ms)
  of headroom when lines arrive back to back, which is too little for a page program (0.5-3 ms) or any short
  flash op (energy log, NVS).

## 2. What is wrong or unnecessary in the proposal
- **Fix 3 targets dead code.** `boxcur::Rx::feed` is not used by `ZaxModbus.ino`. The unit reads with `read_line()`
  and checks lines with `boxcur::parseLine` in `boxLine()`. A 50 ms silence rule in `read_line()` would be
  **harmful**: the bytes carry no receipt time, only the time the loop reads them. After every stall the backlog
  would look like "silence" and valid lines would be cut. It also gains almost nothing: a set with one lost line
  is lost anyway (3 lines per seq are required). **Drop it.** If wanted later, the cheap form is: start the line
  at the last `X:` (X in RSTUVW) found after position 0. That needs no timing.
- **Fix 0 as written (bytes per second for a night) is slow and indirect.** The core reports the event directly:
  `Serial1.onReceiveError(cb)` gets `UART_FIFO_OVF_ERROR` / `UART_BUFFER_FULL_ERROR`
  (`HardwareSerial.cpp:193,297-303`). It may be called after `begin()` and creates the event task itself.
  Counting these gives the deciding number in minutes.
- **The "bigger ring buffer" reason is right to drop.** The ring never overflows here.
- **Fix 1 is not enough on its own once there is a load** (see 1). It is enough at no load, and for the minute
  data. The minute record carries running totals, so even today a lost minute set loses resolution, not energy.
- Verification trap: a `TEST_MODE` build is not usable. It switches `BOX` to USB `Serial` (`ZaxModbus.ino:68-72`),
  so the BOX would not be read. The 120 s interval and `/api/test snapshot` exist only there.
  There is no production on-demand snapshot. The power-fail pin path triggers only on a real edge.

## 3. Fixes, simplest to most time-consuming (effort = code + host check; each OTA about 5 min)
| # | Fix | Fixes | Risk | Effort |
|---|-----|-------|------|--------|
| A | UART error counter: `Serial1.onReceiveError` -> 2 counters in `/api/sysinfo` (`uart_ovf`, `uart_buf_full`) | measurement (your fix 0) | none | 15 min |
| B | `Serial1.setRxFIFOFull(32)` after `begin()` | short flash ops: headroom goes from 8 B to 96 B (0.7 -> 8 ms) | very low (a few more IRQs per line) | 5 min |
| C | Your fix 1: when the hourly snapshot is due, start it right after the W line closes a minute set; fallback = start anyway if 120 s overdue (BOX silent) | minute-set loss (no load and load) | low | 20-30 min |
| D | Your fix 2 (simple form): at R, if the seq step from the last set is 1-10, ts = last_ts + step, never below last_ts + 1; else ts = now | ±1-2 s shifts after a burst; a lost set leaves its true gap | medium. Decision needed on the BOX drift (+30 ppm, about 1 s per 9 h): how and when to re-anchor to NTP | 2-3 h with host test |
| E | Your fix 4: snapshot across loop passes, a few blocks right after each T line (quiet part of the second); power-fail and reboot paths stay synchronous and abort a running one | the stall itself, sec loss under load, the bursts (so most of D's cause) | medium-high: ring ages shift while writing (index from a pinned head), tmp-file lifetime, abort path, min snapshot too | 1-1.5 days; host harness `tools/host_test_sec_delta` exists (byte-identical file check) |

Recommended: **A+B+C as 1.2.3 now** (about 1 h of code), verified in about 1.5 h as below. Then D. Then E,
**before or at the swap with a real load** (the prediction in 1 says C alone will not hold under load).
Alternative to E, if time is short: inside the encoder, `flush()` every 4 KB and wait for "burst ended plus
quiet" before each block. Half a day, but the stall gets longer (6-8 s), so it needs
`setRxBufferSize(4096)` and D. E is the clean fix.

## 4. Fast verification: about 1.5 h on the bench instead of a night
Key facts: the snapshot is full size at once after a flash, because `secSnapLoad` pushes the restored records
into `secBuf` and they count, and OTA keeps LittleFS. Check `snap_sec_recs` about 18,700 and `snap_last_ms`
about 2,700 after the first one. The overnight phase was fixed only by chance of boot time, so the test must
**force** the phase, not wait for it.

Test build = 1.2.3 + one test-only `#define` (not TEST_MODE) that replaces the hourly trigger with "every minute,
after the set at a chosen position". Two images (or one `#define` value each):
- **T1, baseline (worst case, confirms the cause):** trigger after the sec set at count 58 since the last W, so the
  2.7 s stall covers the minute burst every minute. 30 min = 30 stalls, about 3 nights' worth.
  Pass (cause confirmed): `uart_ovf` rises at the stalls AND `lost_min_sets` rises by about 15-25
  (overnight 7 of 11). If lines are lost while `uart_ovf` stays 0, the hypothesis is wrong: stop and look again.
  Also measure the timestamp shifts per stall (overnight 5 of 11), as the baseline for D.
- **T2, fix C:** trigger right after the W line. 30 min = 30 stalls.
  Pass: `lost_min_sets` +0, `lost_sec_sets` +0, `rejected_lines` +0, `uart_ovf` +0 over 30 stalls (no load).
  One loss = fail.
- **B** is covered by the same runs. `uart_ovf` must stay 0 outside the stalls too, including `energyLogAppend`.
- **D:** host test first (minutes), fed with the burst sequences from `overnight.db`. Pass: consecutive seq gives
  consecutive ts, a seq gap gives the same ts gap, no lasting offset. On the bench, use T1-style bursts for 30 min.
  Pass: |MQTT ts − arrival| within ±1 s after every burst (now 5/11 shifted).
- **E:** host harness byte-identical to the one-shot writer, then 1 h with "every 61 s". Pass: max MQTT arrival
  gap < 1.5 s (now 2.4-3.6 s), `uart_ovf` 0, losses 0. Plus one power-fail-during-write, then reboot: restored
  count = written count.
- Flash wear of these tests: about 60 snapshots × about 70 blocks = about 4,000 erases spread over the partition.
  Negligible.
- Not testable without load: the >128 B sec burst. Only a real load on the BOX shows it (owner's decision).
  Until then it is a prediction.
