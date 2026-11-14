# Review: CLAUDE.md change proposal, coding guidelines, first bullet

Reviewer: Fable. Date: 2026-11-14. This is a report. Nothing was edited; `/home/pi/CLAUDE.md` is unchanged.

## Verdict

**Change the wording before applying.** The direction is right, but the proposed text does not match the mistake it is meant to stop, and its parenthesis is narrower than the owner's words.

## What was read

| Source | What it says |
|---|---|
| `/home/pi/CLAUDE.md` (137 lines) | Line 131 is the line under review. Line 5 gives the roles and points to `~/Workspace/nodes/INDEX.md`. |
| `Workspace/nodes/second-futro-2026-11-14-close.md`, "Mistake of the session" | "I called the off-host backup a gap without looking up what futro backs up." |
| Memory index, line "GitHub backup on futro" | Loaded in every session: futro holds the nightly GitHub mirror, cron 03:30. |
| `Workspace/nodes/futro/status.md` lines 17, 141-167 | The same fact, written since 2026-09-11. |
| `Workspace/nodes/INDEX.md`, futro row | "coordinator + dev toolchain". The word "backup" is not in the row. |
| Memory rule `feedback_check_the_gap_is_real` | "Never assert a gap without showing the gap is real." Written for spec files. |

## Findings

### 1. The text does not describe the mistake (main point)

The proposed line says: a fact *from memory* is an assumption until looked up.

The mistake was the opposite shape. Memory held the correct fact (futro has the backup). The wrong statement was "there is a gap", which is a statement that *nothing* does the job. It was made without any lookup. A reader who follows the proposed line literally can repeat the mistake: "no backup exists" does not feel like "a fact from memory", so the line does not fire.

The line needs to name the claim of absence: "no machine does X" needs a lookup too.

### 2. "backs up" is narrower than the owner's words

The owner wrote: "the futro machine that was a raspi backup". That is a machine that stands in for another machine. "What a machine runs or backs up" reads as data backup only. Both meanings are true for futro (toolchain copy of the bench, and the GitHub mirror), and the line should cover both.

### 3. "node-role" is a new term

CLAUDE.md says "Role split" and "Node list"; the index has a column "Role". The compound "node-role fact" appears nowhere else. "A machine's role" says the same in words the file already uses.

### 4. The line does not say where to look, and the index alone is not enough

For hardware and product facts the place to look is clear from the project. For machine roles CLAUDE.md line 5 names `nodes/INDEX.md`, but the futro row there does not mention the backup. The fact is in `nodes/futro/status.md` and in memory. A lookup in the index only would have confirmed the wrong statement. Naming `nodes/<name>/status.md` in the line costs four words.

Side finding, two lines, not part of this proposal: the futro row in `nodes/INDEX.md` does not list the GitHub mirror backup. The close note also records as not checked: "what futro's backup covers beyond the gh-backup mirrors".

### 5. Place and size

- The section is "Coding guidelines", and the mistake was not a coding one. The existing line already holds the hardware/product rule, so extending it there is acceptable and adds no line. The file stays at 137 lines (limit 150).
- Rule 9 asks that a new line "replace or shorten an old line". The proposal replaces, and makes the line longer by 10 words. Acceptable, but the parenthesis should earn its place (finding 2).
- Rule 7 is followed: exact text shown first, apply after `ok`.

### 6. What is correct in the proposal

- One line changed, no new rule, no new file.
- The second sentence ("If you disagree ...") is untouched.
- It extends an existing rule to a class of facts that changed often in the last weeks (raspi off, f22 bench, pc-gate, second S940 coming), so a remembered role is likely to be out of date.

## Suggested text (one variant, for the owner to accept or refuse)

```
- State assumptions in one line; a hardware, product or machine-role fact (what a machine runs, backs up or stands in for; also "no machine does X") is an assumption until looked up (`nodes/<name>/status.md`). If you disagree with a request, say so once, in one line, before doing it.
```

Changes against the proposal:
1. "node-role" -> "machine-role".
2. Parenthesis adds "stands in for" and the claim of absence.
3. "from memory" removed: the source of the statement does not matter, only whether it was looked up.
4. The place to look is named.

## Not checked

- `nodes/<name>/status.md` exists for futro, raspi and workstation; f22 has none (checked with `ls`). If the suggested text is taken, "(`nodes/<name>/`)" is the safer pointer.
- Whether the hardware/product part of the line loses anything by dropping "from memory". My reading: no, it becomes stricter.
- Nothing was run or tested; this is a text review.
