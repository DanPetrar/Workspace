# Review of the 2026-10-13 session (PS-Z001 bring-up) — workflow and CLAUDE.md

Reviewer: Fable, read-only. Nothing was changed. All times are transcript times (UTC); bench time is +3 h.
Counts come from a script over the session transcript.

## The session in numbers

| | |
|---|---|
| Length | 11:16 to 17:40, 6 h 24 min |
| Owner messages | 63, 697 words in total, median 8 words |
| Assistant replies the owner had to read | 65, 14,719 words in total, median 231 words; 36 are over 200 words, 19 over 300 |
| Words, assistant : owner | 21 : 1 |
| Tool calls | 233 |
| Sharp corrections by the owner | 9 of 63 messages (11:58, 12:18, 12:20, 12:22, 12:57, 13:10, 17:22, 17:27, 17:32) |
| Time spent inside corrections | about 62 min (USB 26, format 11, old boards 25), plus 17 min of unwanted builds |

## 1. Findings, by root cause

### F1. The assistant adds work that was not asked, and tells you afterwards (3 incidents)

- **Old boards.** The plan you approved at 14:16 said "built for the new unit only". At 14:27 the assistant compiled for the two old board types (7 min). At 16:48 you wrote one word, "commit"; it first compiled the old boards again (10 min) and only then committed. Your words: 17:22 "from now on we no longer suport OLD BOARD", 17:27 "why you performed operations regarded to old boards without to question me?", 17:32 "any other directions must be put on QUESTINS!!!".
- **New unit hardware.** 11:26: you proposed to dismount the bench; the reply told you how to cable and power the new unit and what to ask the designer. 11:56: asked to "verify connection", it added a list of possible faults on the new unit and a test for you to do. Your words, 11:58: "DO NOT ASUME NOTHING!!! ... ALL HARDWARE RELATED TASKS IS MANAGED BY ME UNTIL I ASK SOMETHING TO YOU."
- **Unit_B reference** (15:28): unasked, harmless, 290 words.

Cost: 5 owner messages and 25 min at the end of the day; 17 min of builds; a firmware that now carries two parsers.

Rule status: **existing rule, not applied.** CLAUDE.md already says "No features beyond what was asked" and "every changed line should trace directly to the user's request". Memory has `feedback_surgical_changes.md` and `feedback_ask_before_diagnosing_bench_state.md`.

Two things the assistant's own explanation left out:

1. **It did tell you, three times, and it did not help.** "Still compiles for the two older board types" is in the 14:38 report (522 words), again at 16:39 (416 words) and at 16:59. You reacted only at 17:14. So a line at the end of a report ("Outside the request: ...") does not solve this. The question must come **before** the work.
2. **Old rules told it to do this.** `feedback_iteration_docs_ota.md` orders, after every firmware version change and "without waiting for the user", a document sweep and builds for other board variants. The memory index says "dev+test only on S3-Zero and S3-ETH" and "per-board-line gate". CLAUDE.md says "ensure tests pass before and after". And the base document says the old implementation is dropped "once the new implementation is complete", not "from today". Before 17:22 no written line said "stop old-board builds now". The breach of the approved plan is the assistant's fault; the missing clear line is a gap in the records.

### F2. A known fault was not looked up (1 incident, the most expensive)

- 11:56: USB errors `-110`, `-71`, `unable to enumerate`. The same text is in `ZaxModbus/Doc/errors-history.md` twice (2026-06-17 with the exact fix, 2026-09-02) and in memory (`feedback_usb_fault_exclude_host_first.md`, 481 words).
- From 11:56 to the fix at 12:18: 22 min, 10 owner messages, 7 failed attempts. The fix was one command and worked in one second. You found it: 12:18 "i think we must reinitiate/restart pi usb ports", 12:20 "this problem was hapened in our history!! do you remember???".

Rule status: the **USB rule existed and was not applied**. The **"read the history before advising" rule was missing**: until today the index line said only "entry after every non-trivial debug" (write, not read). The history file has 2,771 lines; nobody reads it by chance. It needs a fixed moment and a search.

### F3. Short messages were read too fast (3 incidents)

- 12:44 "we not need this to be saved. whats next step?" The assistant decided this meant "no backup of the ESP firmware" and prepared to flash over it. At 13:10 you wrote "backup first the current esp firmware and data". No loss, but the wrong reading would have destroyed the as-received firmware for good. It noticed the two readings (it wrote both) and still did not ask.
- 12:46 "verify the comunication with the box and to analyse data format received from fox": it analysed what the old ESP firmware printed on USB. 12:57: "WRONG !!! we have no interes in the current format that you receive from S3-zero usb." Cost: 11 min, 9 tool calls, a 357-word report.
- 16:48 "commit": see F1.

Rule status: **missing rule** (nothing says "if two readings and the wrong one is costly, ask one question").

Fair to the assistant: the 12:46 message did say "analyse data format received from box", and the analysis turned out to be correct and was used later (13:34, the BOX sends exactly that format). The real error was the method (reading through an unknown firmware instead of the wire), not the topic. One line, "I will read it on the USB output of the present firmware, ok?", would have been enough.

### F4. Replies are too long for this owner (all day)

- Median 231 words per reply; 19 replies over 300 words. You write 8.
- Your rule from 2026-09-16, in capitals: "I NEED MORE COMPACT REPORTS AT THE END OF EACH PHASE/STEP". The same demand is recorded on 2026-07-30 and 2026-09-09. Today is the fourth time.
- Effect seen today: the old-board line was in three long reports before you saw it (F1).

Rule status: **existing rule, not applied** (`feedback_compact_step_reports.md`, `feedback_compact_define_terms.md`, `user_model_style_prefs.md`). The rules have no number in them, so "compact" is judged by the assistant.

### F5. Every correction becomes a new long rule (today: 5 new memory files and 2 extended, about 1,300 words of rules, 6 new index lines)

- Four times the assistant wrote a memory file or a history entry **before** answering you (12:20, 12:57, 17:22, 17:32). CLAUDE.md says answer first.
- Memory now holds 165 files; 69 are rules (17,900 words). The index has 162 lines, 58 of them rules.
- F2 and F4 show that a rule being in memory does not mean it is used. Adding rule number 70 is the same medicine that already failed.

### F6. Small process slips (assistant's list (e), confirmed)

- 13:55: a failed build was hidden by `| tail`; the old image was flashed again. No harm. The history file was started on 2026-05-11 because of exactly this kind of mistake (old binary flashed). Existing lesson, not applied.
- 13:58: stray `git stash`, restored at once.
- 13:56: firmware timing bug the host check could not see. Normal development error, found in 3 minutes on the unit. Not a workflow problem.

### Is it one root failure? Mostly yes.

F1 and F3 are the same thing: the assistant acts on its own idea of what is useful, in place of your exact words. F2 is different (no lookup). F4 and F5 make all of them worse: long text hides the important line, and many rules hide the important rule. The assistant's doubt "too many rules" is supported by the evidence. Its doubt "rules lack a trigger" is also supported (F2, F4).

## 2. What worked (keep)

| Practice | Evidence |
|---|---|
| "Waiting for: ... reply `word`" at the end | In 34 replies. You answered with the offered word 13 times (`ready`, `flash`, `done`, `connected`, `plan ok`, `commit`, `push`). Fast and clear. |
| Saying what a write destroys, before the write | 13:07 "it replaces the firmware now on the ESP (no backup, as you decided)". This sentence let you catch the F3 misreading in time. |
| Listen first, write later | 12:29 to 12:42: only passive reads of the new unit. First write at 13:33 after a backup read twice with matching checksum. |
| Naming a plan change before doing it | 14:12 "One point where I depart from MQTT only ..." You approved with "plan ok". This is the right way; F1 happened where it was not done. |
| Long work without interruptions after approval | 14:16 to 14:42: 29 tool calls, only one-line progress notes, then one report. |
| Push checked, workstation changes recorded | 15:07, 15:12, 15:18: zero unpushed commits shown each time; `INTERVENTIONS.md` updated for each workstation change, backups taken. |
| Power-off test method | Watcher started before your action, three runs, results agree (70, 72, 77 s). Clear instruction of what you do and for how long. |
| Short replies when the request was narrow | 12:02 to 12:13 "check again": 80 to 90 words each. This is the right size. |

## 3. Workflow recommendations (ranked)

1. **Question before extra work.** When the assistant wants to do anything not in your request or in the approved plan, it first writes one line: `Extra: <what>, <time>. Do it? yes / no` and continues with the requested work. Check next session: no build, test or edit that you did not ask for appears in a report without an earlier `Extra:` line.
2. **History search at the first fault.** At the first failed attempt, before any sentence about the cause, the assistant searches `errors-history.md` and memory for the error text and shows one line: `History: <date, fix>` or `History: nothing found`. Check: every fault report has that line.
3. **Reply size limit.** Report: at most 12 lines, result first. Step card: at most 15 lines. Details go in the record file; the reply gives the path. Check: a script count at the session close (today's median was 231 words; target under 100).
4. **On the bench: observation only.** For a check on hardware the assistant reports what the Pi saw, with numbers, and stops. No list of causes on the device, no cabling or power advice. Instructions for your hands ("mains off 3 min") only inside a test you asked for.
5. **One focus line at the start.** After you name the focus, the assistant answers with `Focus: ... / Not in focus: ...` and you reply `ok` or correct it. Cost to you: one word. Today this line would have been "Not in focus: old boards, PiGate" at 11:20, six hours before the argument.
6. **Two readings, costly if wrong: one question.** If your message can be read two ways and the wrong reading costs more than about 5 minutes or cannot be undone, the assistant asks one line with both readings. Otherwise it takes the literal reading and says which one it took.
7. **No new rule file per correction.** After a correction the assistant answers in at most 5 lines (what was wrong, what it does now). A new standing rule is one line proposed for CLAUDE.md at the session close, for your `ok`. Old rules that conflict are removed in the same step.

**Not adopted from the assistant's own list:**

- "A scope check before every action" (ask itself "does this serve the focus?"): cannot be checked by you, and it is the same idea as the CLAUDE.md lines that were not applied today.
- "Outside the request: none" at the end of every report: it reports after the fact. Today the extra work was reported three times and changed nothing. It also adds a line to 60 replies a day. Recommendation 1 replaces it.
- The 405-word memory file `feedback_main_focus_or_question.md` with five points: it repeats the proposed CLAUDE.md paragraph in a second place. Two copies drift apart. One short copy in CLAUDE.md is enough.

**For the owner (optional, low cost):** when a decision changes direction for the whole project (as "no old boards"), say it as one line with the word "from now". It was in the base document only as "once the new implementation is complete", and not in the memory index at all.

## 4. CLAUDE.md

### (i) The current file

- **Effective:** the role split; the GitHub pointer; "Answer Before Acting" (all 9 of your questions today got an answer before any build or flash).
- **Dead weight for today's problems:** the "Karpathy" section is 60 of 88 lines. It is about writing code. None of today's 9 corrections was about code. Its general lines did cover F1 and were not applied.
- **Missing:** who the owner is and how he writes; who owns the hardware; what to do at a fault; how long a reply may be; the session focus; the present project direction.
- **Contradictions:**
  - "If multiple interpretations exist, present them" and "Surface tradeoffs" produce option lists and long text; memory says "compact", "one question at a time".
  - "Refactor X: ensure tests pass before and after" and "Loop until verified" push toward extra checks such as the old-board builds; you want only the asked work.
  - "Do not ... run commands until the answer is given": in practice a read-only lookup is needed to answer (the AP password at 14:49). The rule should forbid writes, not lookups.
  - Memory rule `feedback_iteration_docs_ota.md` ("automatically, no user request needed", builds for other variants) contradicts "any other directions must be put on questions".

### (ii) The proposed "Main Focus" paragraph

**Do not add it as written. Replace it.** Reasons:

- It is a principle without a moment and without a visible sign, like the lines that already failed.
- Its last sentence ("Outside the request: none") is the after-the-fact report that did not work today.
- It does not cover the hardware case (F1), the fault case (F2), the misreadings (F3) or reply length (F4).
- It does not say what the assistant may still do without asking (records, backups, push checks), so it will either be broken at once or cause a question for every note.

The idea is right. The text below keeps it as rules 1 and 3, with a fixed question format.

### (iii) Proposed CLAUDE.md, full text

````
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Role split

**raspi = testing station** (this machine — physically-tied hardware work: USB/serial/GPIO/RS-485 bench hardware, Arduino toolchain, `flash_guard.py`/`boards.json`). **futro = coordinator** (everything else). See `~/Workspace/nodes/INDEX.md` for the full node list and `~/Workspace/nodes/futro/setup-plan.md` for how this split came to be.

## Environment

This is a Raspberry Pi (Linux 6.12.75+rpt-rpi-v8) home directory, not a traditional software project. There is no fixed build system or test suite here — the work done in this directory depends on whatever projects or scripts the user is actively developing.

## GitHub Integration

### Authentication
- **Account**: `DanPetrar` (delazax@zapptronic.eu)
- **CLI tool**: `gh` (v2.89.0) — already authenticated via `/home/pi/.config/gh/hosts.yml`
- **Protocol**: SSH for git operations
- **Token scopes**: `repo`, `admin:public_key`, `gist`, `read:org`

Recipes for creating repos, syncing to an existing repo, and repairing SSH auth live in the
`github-workflows` skill.

## Working with the owner

The owner is an engineer and manages the bench himself. He writes short messages in
English as a second language. Each word is meant exactly. Read the message twice
before acting. These rules come before the guidelines further down and before any
memory rule.

### 1. Focus

The owner names the focus of the session. Reply once with one line:
`Focus: <his words>. Not in focus: <what is parked>.` and wait for `ok`.

Standing direction (2026-10-13): firmware work is for the NEW HARDWARE only
(PS-Z001, PS-E002). Old boards (every unit with the old box): no builds, no tests,
no compatibility work. Do not delete old code unasked.

Terms: UNIT = ESP board + measurement hardware. BOX = the measurement hardware of a
unit. Gateway = the PiGate device (never "box").

### 2. Do what was asked, then stop

- "commit" means commit. "check X" means check X and report what was seen.
- If a message can be read two ways and the wrong reading costs more than 5 minutes
  or cannot be undone: ask one line with both readings, before working.
  Otherwise take the literal reading and say which one.

### 3. Extra work: ask before, never report after

Anything not in the request or in the approved plan (extra build, extra test, another
board variant, compatibility, cleanup, following a side finding) needs this line first:
`Extra: <what>, <time>. Do it? yes / no`
Continue with the requested work while waiting. A side finding is two lines and a
WISHLIST entry, not an investigation.

Allowed without asking: read-only lookups; a backup before a write; the record of
what was done (bench note, errors-history entry, changelog entry for the version
just built, INTERVENTIONS.md); checking a push; pulling on futro after a push.

### 4. Bench hardware belongs to the owner

For a check on hardware: report what the Pi saw, with numbers, and stop. No list of
possible causes on the device, no cabling or power advice, no questions about the
bench, unless asked. Instructions for the owner's hands (unplug, power off for N
seconds) only inside a test the owner asked for. Never touch Unit_B.

### 5. At a fault: history first

At the first failed attempt or unexpected result, before any sentence about the cause:
`grep -n -i '<error text>' ~/ZaxModbus/Doc/errors-history.md` and the memory directory.
Put one line in the reply: `History: <date, fix>` or `History: nothing found`.

Known: `error -110`, `error -71`, `unable to enumerate USB device` on this Pi means
the Pi's USB controller is stuck, not the device. Fix:
`echo 0000:01:00.0 | sudo tee /sys/bus/pci/drivers/xhci_hcd/unbind; sleep 3; echo 0000:01:00.0 | sudo tee /sys/bus/pci/drivers/xhci_hcd/bind`

### 6. Short replies

- Report: at most 12 lines. Result and numbers first, then what is next.
- Step card before a bench step: at most 15 lines.
- Details go in the record file; give the path.
- One question at a time, in plain text. At most two options, and only when the
  decision is the owner's.
- When waiting for the owner, the last line is: `Waiting for: <what> — reply <word>`.

### 7. Before a write, flash or anything that cannot be undone

Say in one line what will be overwritten and whether a backup exists. Wait for the
reply word. Before flashing, confirm the build succeeded (exit status and image hash);
never pipe a build into `tail` or `grep` without `set -o pipefail`.
"commit" is not "push".

### 8. Answer before acting

If the owner's message is a question, answer it first, in plain text. A read-only
lookup needed for the answer is allowed. No file edits, no memory writes, no builds
before the answer is given and the owner confirms he wants to proceed.

### 9. After a correction

Answer in at most 5 lines: what was wrong, what happens now. Do not write a new rule
file. At the session close, propose at most one new line for this file and wait for `ok`.

## Behavioral Guidelines (Karpathy)

Derived from Andrej Karpathy's observations on LLM coding pitfalls. **Tradeoff:** these bias toward caution over speed — use judgment on trivial tasks.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
````

### (iv) What changed and why

- **"Interaction Rules / Answer Before Acting"**: kept as rule 8, with the lookup allowed and writes forbidden (matches how the session really runs).
- **New rules 1 to 7 and 9**: each answers one finding (F1: rules 1, 3, 4; F2: rule 5; F3: rule 2; F4: rule 6; F5: rule 9; F6: rule 7). Each has a fixed line you can look for in a reply.
- **The assistant's "Main Focus" paragraph**: merged into rules 1 and 3; the "Outside the request" sentence dropped.
- **Moved in from memory as one line each**: old boards unsupported, hardware is the owner's, history first, USB fix, compact reports, waiting block, one question in plain text, "commit" is not "push", gateway/box terms, Unit_B.
- **Karpathy section**: kept word for word and moved below the owner rules, because memory records your decision of 2026-07-29 to keep it always. The new line "These rules come before the guidelines further down" settles the contradictions listed in (i). See question 1.
- **Role split, Environment, GitHub**: unchanged.

## 5. Memory index

**It hurts more than it helps in its present form.** 162 lines are loaded every session; 58 are rules, about 30 are closed or superseded history. Today two existing rules were not used (F2, F4), and one stale rule pushed the wrong way (F1). Proposal, nothing changed:

1. **Rules that must hold every session go in CLAUDE.md** (done in the text above). Remove their index lines; keep the files as background.
2. **Merge the rest of the 58 rule lines into 6 topic files**, one index line each:
   - bench hardware (verify hardware state, identify a device, ask before diagnosing, USB host first, recovery scope, cable verify, power-off duration);
   - flashing (smoke test, otadata, partition scheme, arduino-cli cache, Arduino IDE only, flash guard);
   - shell traps (background processes, ssh, rm, write checks, defaults, pytest);
   - measurements and runs (predict first, post-hoc windows, unattended runs, right signal, instrument first, skip is not pass, flaky tests);
   - planning and delegation (no premature coding, plan review, delegation, draft file);
   - git and records (verify push, changelog, errors-history write side, settled records).
3. **Rewrite or retire the rules that now conflict:** `feedback_iteration_docs_ota.md` (automatic sweep, builds for S3-Zero and LilyGO); "Validation procedure — per-board-line gate"; "LilyGO out of scope — dev+test only on S3-Zero and S3-ETH"; `feedback_explain_step_and_bench_first.md` (written for PiGate; its "bench preparation: wiring, power" item led to the 11:26 reply). Also fix the header of `feedback_errors_history.md`, which still says it is for EmonESP.
4. **Move to one "archive" line** (files stay): the "v1.2.0 shift trigger" (it has fired), the four LilyGO lines, the board runbook, 10-board batch, commission test, S3-ETH Phase 9, Phase 1b, about 12 superseded session resumes, 6 superseded PiGate closes.
5. **Target:** index under 60 lines; the "current" block at the top at most 8 lines; a size check at every session close.

## 6. Open questions for the owner

1. The Karpathy section: keep all 60 lines, or shorten to about 8 lines? (`keep` / `shorten`)
2. Reply limit of 12 lines for a report: ok, or another number?
3. The document and changelog sweep after each firmware version: still automatic, or only on request? (`auto` / `ask`)
4. May the assistant tell you what to do with your hands (unplug, mains off N seconds) inside a test you asked for? (`yes` / `no`)
5. Is EmonESP_MultiIO still an active project? (`yes` / `no`; it holds 20 index lines)

## 7. Limits of this review

- I read the transcript text, the tool commands (first 300 characters) and 12 of the 165 memory files, plus the index. I did not read tool outputs in full or the firmware code.
- I cannot see the bench. What you did by hand, and when, is known only from your messages.
- I could not determine what you meant at 12:44 with "we not need this to be saved".
- The base document's "No historical restrictions" text is there, but I cannot know what was said in earlier sessions about old boards.
- The 62 minutes of correction time is from message timestamps; it includes your own bench actions in the USB part.
- Whether the proposed CLAUDE.md changes behaviour can only be seen in the next sessions. The fixed lines (`Focus:`, `Extra:`, `History:`, 12 lines) are there so you can check it quickly.
- I am a model of the same family as the assistant and may share its blind spots.
