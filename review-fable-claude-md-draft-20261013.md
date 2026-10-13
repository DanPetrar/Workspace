# Review of the draft CLAUDE.md (2026-10-13)

Reviewer: Fable, read-only. Nothing was changed. Draft reviewed:
`.../scratchpad/CLAUDE.md.proposed` (119 lines). Most of it is my own text from the first review,
so I read it here as a critic. Several of the weak points below are mine, not the assistant's.

## 1. Critique of the draft

### The assistant's four adjustments

| Adjustment | Verdict | Why |
|---|---|---|
| EmonESP line in rule 1 | Change | "the Zax rules do not apply to it" can be read as "rules 1 to 9 do not apply in EmonESP". They must apply everywhere. Say only: do not mix code, documents and hardware notes. |
| Rule 3: document and changelog update is automatic | Change | Matches your answer "auto", but it has no limit. The old memory rule behind it lists 10 documents and builds for other board variants. As written it reopens the door. Limit: text only, only what that version changed, no builds, no new documents, touched files listed in the report. |
| Rule 4: instructions for your hands, one line each | Keep | Matches your answer exactly. |
| Karpathy in 7 lines | Keep, two small changes | See below. |

**The 7-line Karpathy form.** What was lost, and whether you would miss it:

- "Push back when warranted" is gone. I would keep it in one line. It worked today: at 14:12 the assistant said it disagreed with "MQTT only" before building, and you approved.
- "If multiple interpretations exist, present them" is gone. Not missed: rule 2 does this better.
- "then check it" has no limit. This is the habit that produced the old-board builds. Add: "on the target in focus only".
- "If unsure, ask" competes with rule 2 (when to ask) and rule 6 (one question). Removed; rule 2 decides.

### Weak points in the rest (my text)

| Rule | Problem | Fix |
|---|---|---|
| 1 | "wait for `ok`" stops the work when you only say "lets continue". | No waiting. The `Focus:` line is the first line of the reply; you correct it if wrong. |
| 1 | You said "all our documents reflect the development directions". The draft does not tell the assistant to read them. | One line: read the last close note and the base document of the topic first. |
| 1 | "Old boards: no builds, no tests" could also be read as "do not use old units on the PiGate bench". | Say "no firmware builds, no firmware tests". |
| 1 | Your "from now on ..." decisions have no fixed place. Today's was not written anywhere before 17:22. | A dated "Standing directions" list; a new one is added after your `ok`. |
| 2 | Would not have stopped the 12:46 mistake (see part 2). | First line of a larger task says what will be done and with what. No waiting. |
| 3 | "Extra" is not defined, so the assistant either asks for trivial things or decides alone what is trivial. | Define it: builds, flashes, edits a file, contacts a unit or another machine, or takes more than 2 minutes. Everything else needs no question. |
| 3 | No rule for an unanswered `Extra:` line. | "No answer means no." |
| 5 | Says what to look up, not what to do with the recorded fix. | Propose the fix in one line; apply after your reply word. |
| 6 | No limit for a plan (today's plans were 446 and 454 words). | Step card or plan: 15 lines. Table rows count as lines. |
| 7 | "Before a write" is too wide: every file edit is a write. The assistant would ask all day, or ignore the rule. | List the cases: flash or erase; overwrite or delete of something not made in this session; workstation or `/etc`; push. |
| 7 | Nothing about your wish "show me ... before apply". | Changes to CLAUDE.md, memory rules, settings: exact new text first, apply after `ok`. |
| 7 | Three-repo commit and push has no fixed report. | One line per repo: repo, branch, hash, unpushed count. |
| 8 | "and the owner confirms he wants to proceed" stalls after a simple question ("the pass for ap?"). | "After the answer, continue only with what was already approved." |
| 9 | "at most one new line" is too tight for a day like today; and the file can only grow. | At most 3, each should replace or shorten an old line; file stays under 150 lines. |
| 9 | "Do not write a new rule file" collides with your "remember this info". | A fact you tell it to remember goes to memory, after the answer. |
| intro | "before any memory rule" but no action when they disagree. | Follow this file and name the memory rule at the session close. |

## 2. Test against today's corrections

| Time | Your correction | Rule | Would it have worked? |
|---|---|---|---|
| 11:58 | "DO NOT ASUME NOTHING ... HARDWARE ... MANAGED BY ME" | 4 | Yes. "No list of causes, no cabling or power advice" names exactly what was done at 11:26 and 11:56. |
| 12:14, 12:18 | USB: "problem is on pi or on your ckecking metodology"; you found the fix | 5 | Yes. The "Known" line has the exact error text and the command. This is the strongest rule in the file. |
| 12:20, 12:22 | "you have checked error-log/history??" | 5 | Yes for known text. For a new kind of fault: medium. It works only if the assistant sees the event as a fault. The visible `History:` line lets you notice when it is missing. |
| 12:57 | "WRONG !!! we have no interes in the current format ..." | 2 | **Weak.** The assistant did not see two readings; it believed it was doing the task. The added line ("first line says what will be done and with what") shows you the method early, but it does not wait, so it helps only if you read it and stop the work. This is the correction with the least cover. |
| 13:10 | "backup first the current esp firmware and data" | 2 and 7 | Yes. The assistant saw both readings at 12:44; rule 2 now forces the question. Rule 7's line ("what is replaced, backup exists or not") is what caught it today. |
| 13:55 | (no correction) previous image flashed after a hidden build failure | 7 | Yes. `set -e -o pipefail` in one chain is concrete. |
| 17:14 to 17:32 | old boards; "MAIN FOCUS ... any other directions must be put on QUESTINS" | 1 and 3 | Yes. The standing direction is now written, a build is by definition an `Extra:`, and the automatic document update excludes builds. |
| all day | (no correction today; three earlier ones) long replies | 6 | Yes, it is a number. It can be counted at the close. |
| 4 times | (not corrected) rule files written before answering | 8 and 9 | Yes. "No memory writes before the answer" and "no new rule file". |

Not covered by any rule: nothing else from today. Honest limit: every rule here still depends on the
assistant applying it. The fixed lines (`Focus:`, `Extra:`, `History:`, `Waiting for:`, 12 lines) are
there so that you can see in two seconds when a rule was skipped.

## 3. The opposite risk: asking too much

| Where the draft can stall | Smallest fix (in the final text) |
|---|---|
| Rule 1 waits for `ok` on the Focus line | No waiting. |
| Rule 3 `Extra:` for trivial things | Definition with a 2-minute and "changes nothing" limit; work continues while waiting; no answer means no. |
| Rule 7 "before a write" | Four named cases only. Your reply word to the step card is the go; no second question. |
| Rule 8 "owner confirms he wants to proceed" | Continue with what was already approved. |
| Rule 2 two readings | Unchanged: a question only if the wrong reading costs more than 5 minutes or cannot be undone. Otherwise literal reading, stated. |

Expected number of questions on a day like today: about 3 (the "saved" message, two `Extra:` lines for
the old-board builds). Today you wrote 9 corrections instead.

## 4. Final proposed CLAUDE.md

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
before acting. Rules 1-9 apply in every project. They come before the coding
guidelines below and before any memory rule. If a memory rule disagrees, follow this
file and name that memory rule at the session close.

### 1. Focus

At the session start, and when the owner changes direction, read the last close note
and the base document of that topic. Then put this line first in the reply:
`Focus: <his words>. Not in focus: <what is parked>.`
Do not wait for an answer; he corrects it if it is wrong.

Standing directions (a "from now on ..." from the owner is added here, dated, after his `ok`):
- 2026-10-13: ZaxModbus firmware is for the NEW HARDWARE only (PS-Z001, PS-E002).
  For old boards (every unit with the old box): no firmware builds, no firmware
  tests, no compatibility work. Do not delete old code unasked.
- EmonESP_MultiIO is a separate project. Never mix its code, documents or hardware
  notes with the Zax projects.
- Terms: UNIT = ESP board + measurement hardware. BOX = the measurement hardware of
  a unit. Gateway = the PiGate device (never "box").

### 2. Do what was asked, then stop

- "commit" means commit. "check X" means check X and report what was seen.
- For a task that is more than one check, the first line says what will be done and
  with what (file, port, tool). Then do it.
- If a message can be read two ways and the wrong reading costs more than 5 minutes
  or cannot be undone: ask one line with both readings, before working.
  Otherwise take the literal reading and say which one.

### 3. Extra work: ask before, never report after

Extra = anything outside the request or the approved plan that builds, flashes, edits
a file, contacts a unit or another machine, or takes more than 2 minutes. Examples:
another board variant, another project, compatibility, a regression check, cleanup,
following a side finding. It needs this line first:
`Extra: <what>, <time>. Do it? yes / no`
Continue with the requested work while waiting. No answer means no. A side finding is
two lines and a WISHLIST entry, not an investigation.

Allowed without asking:
- read-only lookups; a backup before a write; checking a push; pulling on futro after a push;
- the record of what was done: bench note, errors-history entry, INTERVENTIONS.md,
  the session close note and its memory line;
- after each firmware version: the changelog entry and the status lines of the
  documents that version changed. Text only, new hardware only, no builds, no new
  documents. List the touched files in the report.

### 4. Bench hardware belongs to the owner

For a check on hardware: report what the Pi saw, with numbers, and stop. No list of
possible causes on the device, no cabling or power advice, no questions about the
bench, unless asked. If the bench changes while he works on it, report it as an
observation, not as a fault. Inside a test the owner asked for, instructions for his
hands are allowed in short form, one line each (what, for how long, what to restore);
details only if he asks. Never touch Unit_B.

### 5. At a fault: history first

At the first failed attempt or unexpected result, before any sentence about the cause:
`grep -n -i '<error text>' <project>/Doc/errors-history.md` and the memory directory.
Put one line in the reply: `History: <date, fix>` or `History: nothing found`.
If a fix is recorded, propose it in one line and apply it after his reply word.

Known: `error -110`, `error -71`, `unable to enumerate USB device` on this Pi means
the Pi's USB controller is stuck, not the device. Fix:
`echo 0000:01:00.0 | sudo tee /sys/bus/pci/drivers/xhci_hcd/unbind; sleep 3; echo 0000:01:00.0 | sudo tee /sys/bus/pci/drivers/xhci_hcd/bind`

### 6. Short replies

- Report or answer: at most 12 lines (table rows count). Result and numbers first,
  then what is next.
- Step card before a bench step, or a plan: at most 15 lines.
- Details go in the record file; give the path.
- One question at a time, in plain text. At most two options, and only when the
  decision is the owner's.
- When waiting for the owner, the last line is: `Waiting for: <what> — reply <word>`.

### 7. Before a flash, an overwrite, a push, or a change to rules

- Applies to: flashing or erasing a unit; overwriting or deleting anything not made in
  this session; a change on the workstation or in `/etc`; a push. The step card says in
  one line what is replaced and whether a backup exists. His reply word is the go.
- Changes to this file, to memory rules or to settings: show the exact new text first;
  apply after `ok`.
- Build then flash: one command chain with `set -e -o pipefail`; never pipe a build
  into `tail` or `grep` without it. Report the image hash and its build time.
- "commit" is not "push". After a commit or push, one line per repo: repo, branch,
  hash, unpushed count.

### 8. Answer before acting

If the owner's message is a question, answer it first, in plain text. A read-only
lookup needed for the answer is allowed. No file edits, no memory writes, no builds
before the answer. After the answer, continue only with what was already approved.

### 9. After a correction

Answer in at most 5 lines: what was wrong, what happens now. Do not write a new rule
file. A fact he tells you to remember goes to memory, after the answer. At the session
close, propose at most 3 new lines for this file, as exact text; each should replace
or shorten an old line. This file stays under 150 lines.

## Coding guidelines (Karpathy, short form)

- State assumptions in one line. If you disagree with a request, say so once, in one line, before doing it.
- If a simpler approach exists, say so before building.
- Minimum code that solves the problem: no features, abstractions or options that were not asked for.
- Touch only what the request needs. Match the existing style. Do not improve or delete neighbouring code; mention it instead.
- Remove only the leftovers your own change created.
- Decide how the change will be checked before writing it, then check it, on the target in focus only.
- For a multi-step task, give a short plan with one check per step.
````

### Differences from the assistant's draft

| Where | Change | Reason |
|---|---|---|
| Intro | "Rules 1-9 apply in every project"; what to do when a memory rule disagrees | Closes the EmonESP reading; gives the conflict a place to be reported. |
| 1 | No waiting for `ok`; Focus line also when the direction changes | Removes a stall on "lets continue"; today the focus changed at 11:19, inside the session. |
| 1 | Read the close note and base document first | Your words: "all our documents reflect the development directions". |
| 1 | "Standing directions" as a dated list | A fixed place for "from now on ..." decisions. |
| 1 | "no **firmware** builds, no **firmware** tests" | Old units may still serve on a bench; only firmware work for them stops. |
| 1 | EmonESP line reworded | The draft could switch rules 1 to 9 off in EmonESP. |
| 2 | New line: say what will be done and with what | Partial cover for the 12:46 mistake. |
| 3 | "Extra" defined (2 minutes, changes nothing); "no answer means no"; "another project" added | Prevents both over-asking and deciding alone. |
| 3 | Automatic document update limited: text only, that version only, no builds, files listed | Keeps your "auto" without reopening unasked work. |
| 3 | Session close note and its memory line allowed | It is routine and was not named. |
| 4 | "report it as an observation, not as a fault" | Replaces a memory rule that says to ask you what you did (see part 5). |
| 5 | Project path generic; propose the fix, apply after reply word | PiGate has its own history; the controller reset drops every USB device, so you decide. |
| 6 | Plan limit 15 lines; table rows count; "or answer" | Today's plans were about 450 words. |
| 7 | Named cases in place of "a write"; rules text shown before apply; build chain; per-repo line | "Write" was too wide; covers "show me before apply" and the three-repo case. |
| 8 | Ending changed to "continue only with what was already approved" | Removes a stall after simple questions. |
| 9 | "at most 3", replace an old line, 150-line cap; remembered facts allowed | Today had four distinct corrections; the file must not grow without end. |
| Coding | Disagree once, in one line; check "on the target in focus only"; "If unsure, ask" removed | Keeps the useful push-back; closes the extra-check habit; rule 2 decides when to ask. |

Length: 138 lines against the draft's 119 (the current file has 88). The 19 extra lines are: the
definition of "Extra" and the limits on the automatic document update (rule 3), the named cases in
rule 7, and the standing-directions list (rule 1). Each answers a point in part 1; none is general advice.

## 5. Memory: what must change on day one

Minimal list. The assistant shows you the exact new text first (rule 7), then applies.

| File (index line) | Problem | Action |
|---|---|---|
| `feedback_keep_karpathy_guidelines.md` ("keep-always") | Says never shorten the section. You chose "shorten". | Rewrite: shortened 2026-10-13 by the owner; do not expand again. |
| `feedback_iteration_docs_ota.md` ("Auto doc+OTA review ... unprompted") | Lists 10 documents and builds for S3-Zero and LilyGO, without asking. | Rewrite to the rule 3 limits. Remove the build item and the old document list. |
| `feedback_main_focus_or_question.md` | Five points, among them "Outside the request: none" and "before every action ask". Not in the new file. | Reduce to one pointer line: "see CLAUDE.md rules 1 and 3". |
| `feedback_explain_step_and_bench_first.md` ("before EVERY step ... wait ready") | 8-item card with wiring and power; written for PiGate. Conflicts with rules 4 and 6. | Index line: "step card: CLAUDE.md rule 6, at most 15 lines". Keep the PiGate items for PiGate only. |
| `feedback_ask_before_diagnosing_bench_state.md` | Says: ask the owner what he did. Rule 4 says: no questions about the bench. | Rewrite: report the change as an observation; do not diagnose. |
| `feedback_compact_step_reports.md`, `feedback_compact_define_terms.md` | "The step card stays detailed"; "options labelled (a)/(b)". | One-line fix each: limits are in CLAUDE.md rule 6. |
| `feedback_newbox_hardware_owner_managed.md` | No exception for hand instructions inside a requested test. | Add pointer to rule 4. |
| `feedback_errors_history.md` | Header still says "for EmonESP_MultiIO projects". | Fix the header; point to rule 5. |
| `project_lilygo_out_of_scope.md` ("dev+test only on S3-Zero and S3-ETH") | Names the old boards as the targets. | Index line: "superseded 2026-10-13: new hardware only". |
| `project_v120_shift_trigger.md` ("stay on 1.1.x until NEW hardware arrives") | The hardware arrived; firmware is 1.2.2. | Index line: "done 2026-10-13". |
| `project_zaxmodbus_validation_procedure.md` ("per-board-line gate") | Pushes toward tests on old board lines. | Index line: "old boards only; no gate line for new hardware yet". |

Everything else in the index can wait for the larger clean-up proposed in the first review.

## Limits

- I did not read the memory files again; the table uses what I read for the first review.
- I assumed "old boards unsupported" stops firmware work only, not the use of old units as data
  sources on a bench. If you mean more, the first standing direction needs one more word from you.
- Whether these rules hold can only be seen in the next sessions.
