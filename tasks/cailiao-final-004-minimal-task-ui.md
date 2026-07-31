# Claude task book
Task ID: cailiao-final-004-minimal-task-ui

- Baseline commit: `10073b030c1601640d66ef6e8c8d22fa70e59043` (`Add task workflow API`)
- Target repo: `https://github.com/wuyutanhongyuxin-cell/cailiao`
- Isolated workspace: `/home/kiro/kiro-work/work/cailiao-task`
- Phase: final delivery closeout / 4. minimal frontend MaterialTask workspace

## Allowed files

- `frontend/index.html`
- `frontend/app.js`
- `frontend/styles.css`
- `tests/test_frontend_task_ui.py`
- `tools/run_quality_gates.py`
- `README.md`
- `docs/ROADMAP.md`
- `CODEX_HANDOFF.json`

## Forbidden

- Do not add dependencies.
- Do not rewrite the app or remove existing panels.
- Do not change backend routes.
- Do not call network except same-origin backend APIs from browser UI.
- Do not read `.env` or credentials.
- Do not add model provider, embedding, rerank, or NLI behavior.
- Do not mark Stage 2B real external parent blockers complete.

## Goal

Add a minimal "任务" frontend panel that uses the existing backend task APIs:

```text
create/list/load task -> attach current form/evidence -> task evidence search/attach/approve -> generate/audit/preflight/export
```

Keep it compact and operational. No marketing copy, no frontend redesign.

## Required UI

Add nav button:

```html
<button class="nav" data-panel="tasks">任务</button>
```

Add `section#tasks.panel` containing stable ids:

```text
taskCreateBtn
taskRefreshBtn
taskList
taskCurrentId
taskLoadCurrentBtn
taskSaveCurrentBtn
taskEvidenceQuery
taskEvidenceSearchBtn
taskEvidenceResults
taskAttachManualBtn
taskApproveSelectedBtn
taskGenerateBtn
taskAuditBtn
taskPreflightBtn
taskExportDocxBtn
taskStatus
taskLog
```

Behavior:

- Create task from current compose fields/facts/draft/local evidence using `POST /api/tasks`.
- Refresh/list tasks via `GET /api/tasks`.
- Load selected/current task into compose fields/facts/draft and `state.evidence`.
- Save current compose state back to task via `PUT /api/tasks/{id}`.
- Search task evidence via `POST /api/tasks/{id}/evidence/search`.
- Attach one result to task via `POST /api/tasks/{id}/evidence/attach`.
- Approve selected/attached evidence via `POST /api/tasks/{id}/evidence/approve`.
- Generate via `POST /api/tasks/{id}/generate`, update draft/prompt/status.
- Audit via `POST /api/tasks/{id}/audit`, render compact audit counts.
- Preflight via `POST /api/tasks/{id}/export/preflight`, render summary.
- Export via `POST /api/tasks/{id}/export/docx`, download docx.

## Required implementation constraints

- Add GET helper separate from existing POST `api`.
- Escape all server/user text with `escapeHtml`.
- Never assume a task exists; show concise status when no task selected.
- Preserve existing local compose workflow and existing evidence/library/review/export/settings behavior.
- Text must not claim semantic entailment/truth judgement. Say task evidence approval is manual/deterministic.

## Tests

Add `tests/test_frontend_task_ui.py`:

- `index.html` has task nav and all required ids.
- `app.js` contains functions for task create/list/load/save/search/attach/approve/generate/audit/preflight/export.
- `app.js` references all required backend routes.
- `app.js` uses `escapeHtml` in task render paths.
- Existing `tests/test_frontend_ui.py` still passes.

Update `tools/run_quality_gates.py` py-compile list.

## Docs / handoff

Update README/ROADMAP with minimal task UI v1 and boundary.
Update `CODEX_HANDOFF.json` with exact tests.

## Required verification

Run:

```powershell
python -m unittest tests.test_frontend_task_ui -v
python -m unittest tests.test_frontend_ui -v
python -m unittest discover -s tests -v
python tools/run_quality_gates.py --json
python -m json.tool CODEX_HANDOFF.json
git diff --check
```

Report exact results in `/home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md`.
