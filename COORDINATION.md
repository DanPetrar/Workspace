# Workspace — Coordination Guide

_Read this at the start of every Claude Code session on any node._

---

## Node roles

Roles and reachability are **not hardcoded here** — see [`nodes/INDEX.md`](nodes/INDEX.md),
the single source of truth. Today that resolves to:

- **Coordinator** (writes task specs, reviews results, maintains fleet-wide docs) —
  `raspi`
- **Executor(s)** (implement tasks, build, test, commit results) — `workstation` (and
  `futro`, once active)

**The user works across multiple machines.** Each node's Claude Code is a separate
instance with no shared memory — task specs must be self-contained so an executor node
can run them without prior context.

### Control model

The coordinator node has **direct SSH control** of the others (e.g. `ssh ws` →
`dan-linux@192.168.110.11`, key-based, passwordless sudo) — this is the **default**
path; the coordinator runs commands remotely rather than writing a task spec.

**The GitHub task-spec hand-off below is the fallback** — used for work that must run
in a Claude session *on* that node (interactive tools, or when direct SSH is
unavailable).

> Where things run and the full data-flow map are in
> [`infrastructure-interaction.md`](infrastructure-interaction.md) — the source of
> truth. Run each node's `infrastructure/health-<node>.sh` at session start.

---

## How tasks work (fallback path)

1. Coordinator writes a task spec in this repo or a project repo, commits, pushes.
2. User pulls on the executor node, opens Claude Code, says "implement tasks/TASK-XXX.md".
3. Executor Claude reads the spec, implements, commits results, pushes.
4. Coordinator reviews the diff next session, updates the task index, writes the next task.

**Task specs are self-contained.** Goal, full context (API formats, payloads, config),
exact files to create/edit, and acceptance criteria. Don't assume prior knowledge of
any project.

## Task index

Tracked in `tasks/INDEX.md` (create when the first task is written — none carried over
from the old repo; its historical tasks are already complete, see
`nodes/workstation/setup/`).

---

## Reporting results

After completing a task:
1. Update `tasks/INDEX.md` — mark done, one-line result note.
2. Update the relevant `nodes/<node>/inventory.md` if tools changed.
3. Commit referencing the task ID.
4. Push — the coordinator reviews next session.
