# Claude task book
Task ID: cailiao-final-005-paragraph-repair-flow

- Baseline commit: `bddf0a67` (`Add minimal task UI`)
- Target repo: `https://github.com/wuyutanhongyuxin-cell/cailiao`
- Isolated workspace: `/home/kiro/kiro-work/work/cailiao-task`
- Phase: final delivery closeout / 5. paragraph-level targeted repair flow

## Allowed files

- `backend/server.py`
- `frontend/index.html`
- `frontend/app.js`
- `frontend/styles.css`
- `tests/test_material_task_repair.py`
- `tests/test_frontend_task_repair_ui.py`
- `tools/run_quality_gates.py`
- `README.md`
- `docs/ROADMAP.md`
- `CODEX_HANDOFF.json`

## Forbidden

- Do not add dependencies.
- Do not add real model provider, embedding, rerank, or NLI behavior.
- Do not call external network.
- Do not read `.env` or credentials.
- Do not rewrite the app or remove existing panels.
- Do not mark Stage 2B real external parent blockers complete.
- Do not commit or push. Leave that to Codex after review.

## Goal

Implement the next final-closeout slice from `docs/FINAL_DELIVERY_PLAN.md`: paragraph-level targeted repair loop.

The existing system already builds `targeted_repair_plan` / repair units during analysis. This slice should add a task-scoped repair API and minimal UI wiring so a user can:

```text
audit/generate task -> see repair units -> request a prompt-only paragraph repair -> accept/reject/rollback safely
```

Keep v1 deterministic and conservative. If no model call is configured or allowed, return a prompt-only/offline repair candidate. Do not invent facts.

## Backend requirements

Add:

```text
POST /api/tasks/{id}/repair/paragraph
```

Request body:

```json
{
  "paragraph_id": "p3",
  "mode": "prompt_only",
  "action": "propose|accept|reject|rollback|lock|unlock",
  "revised_text": "optional user accepted text",
  "accept_locked_context": true
}
```

Minimum behavior:

- `propose`: read the task draft, latest analysis, targeted repair units, selected evidence, approved facts, locked paragraphs, and existing repair_history.
- Identify the target paragraph by stable paragraph id from analysis/repair units. If the id is missing or not found, return 400 with JSON error.
- If the paragraph is locked and `accept_locked_context` is not true, refuse with JSON error and do not mutate the draft.
- Build a repair prompt that states:
  - rewrite only the target paragraph;
  - do not change other paragraphs;
  - use only approved facts/evidence;
  - solve the listed issue(s);
  - unsupported facts must become `需核实` or be removed;
  - output only the revised paragraph.
- In `prompt_only` / offline mode, do not call any provider. Return a conservative `revised_text` candidate that is either the original paragraph plus an explicit `需核实` marker where appropriate, or the original paragraph unchanged with a clear `mode="prompt_only"` and prompt for manual editing.
- Record a repair proposal in `repair_history_json` with deterministic id, paragraph_id, action, original_text, revised_text, prompt, mode, created_at, status.
- `accept`: replace only the target paragraph in `draft`, append a new `draft_versions_json` entry, update repair_history status, and rerun/save task analysis using existing deterministic analysis helper.
- `reject`: mark the repair record rejected; do not change draft.
- `rollback`: restore the previous draft version for that paragraph/task when available; append repair_history and rerun/save analysis.
- `lock` / `unlock`: update `locked_paragraphs_json` for the paragraph id without changing draft.

Response shape:

```json
{
  "task": {},
  "paragraph_id": "p3",
  "action": "propose",
  "original_text": "...",
  "revised_text": "...",
  "prompt": "...",
  "mode": "prompt_only|offline",
  "repair_record_id": "...",
  "analysis_after": {}
}
```

Keep existing task/generate/audit/export APIs backward-compatible.

## Frontend requirements

Add minimal controls to the task/review flow without redesign:

- Show task repair units after `auditTask()` or `generateTask()` if analysis contains targeted repair units.
- Stable ids:
  - `taskRepairUnits`
  - `taskRepairParagraphId`
  - `taskRepairProposeBtn`
  - `taskRepairAcceptBtn`
  - `taskRepairRejectBtn`
  - `taskRepairRollbackBtn`
  - `taskRepairLockBtn`
  - `taskRepairUnlockBtn`
  - `taskRepairPrompt`
  - `taskRepairCandidate`
- `propose` calls `POST /api/tasks/{id}/repair/paragraph` with `{action:"propose", paragraph_id, mode:"prompt_only"}`.
- `accept` calls the same endpoint with `{action:"accept", paragraph_id, revised_text}` and updates draft/status/analysis.
- `reject`, `rollback`, `lock`, `unlock` call the same endpoint with the matching action.
- Escape all server/user text with `escapeHtml`.
- UI text must clearly say this is prompt-only/manual repair assistance, not semantic truth judgement.
- Preserve existing task UI and old compose/evidence/library/review/export/settings behavior.

## Tests

Add backend tests in `tests/test_material_task_repair.py`:

- propose returns prompt, original_text, revised_text, repair_record_id, and does not change non-target paragraphs.
- accept changes only the target paragraph and increments draft_versions / records repair_history.
- reject does not change draft.
- locked paragraph refuses propose/accept unless allowed by request.
- rollback restores previous draft content.
- prompt contains only-approved-evidence / unsupported-facts wording and does not claim semantic entailment.

Add frontend static tests in `tests/test_frontend_task_repair_ui.py`:

- required ids exist.
- app.js references `/repair/paragraph`.
- functions exist for render repair units, propose, accept, reject, rollback, lock, unlock.
- dynamic render paths use `escapeHtml`.
- text says prompt-only/manual and does not claim semantic truth judgement.

Update `tools/run_quality_gates.py` py-compile list with both new tests.

## Docs / handoff

Update README/ROADMAP with paragraph repair v1 and boundary:

- prompt-only/offline v1;
- no real provider, no external network, no NLI;
- repairs only target paragraph;
- human acceptance required;
- Stage 2B real external parent blockers remain unchecked.

Update `CODEX_HANDOFF.json` with exact tests and honest residual risks.

## Required verification

Run:

```powershell
python -m unittest tests.test_material_task_repair -v
python -m unittest tests.test_frontend_task_repair_ui -v
python -m unittest discover -s tests -v
python tools/run_quality_gates.py --json
python -m json.tool CODEX_HANDOFF.json
git diff --check
```

If your environment only has `python3`, report that honestly and use a temporary `python` shim only for `tools/run_quality_gates.py` if needed. Do not commit the shim.

Report exact results in `/home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md`.
