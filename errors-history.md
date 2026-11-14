# Workspace — Errors History

_Append one entry per non-trivial debugging session._

<!-- Format:
## YYYY-MM-DD — Short title
**Symptom:** ...
**Root cause:** ...
**Fix:** ...
-->

## 2026-11-14 — `python3 -m venv` fails on f22 (ensurepip not available)
**Symptom:** `The virtual environment was not created successfully because ensurepip is not available` (Debian 13, python 3.13, no `python3-venv`).
**Root cause:** package `python3-venv` not installed on f22; installing it is an `apt` change on the workstation (owner approval).
**Fix:** system pip exists, so `python3 -m pip install --target ~/.venvs/<name> <pkg>` and `sys.path.insert(0, ...)` in the script (run with `python3 -I`). Used for fpdf2 + markdown (md to PDF, `~/.venvs/mdpdf-lib`). fpdf2 `write_html` rejects tags nested in table cells: strip `code/strong/em/a/br` inside `td/th` first.
