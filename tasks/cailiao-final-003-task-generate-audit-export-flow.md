# Claude task book
Task ID: cailiao-final-003-task-generate-audit-export-flow

- Baseline commit: `3205509876dad8cb19104a498a68b0a683848e1d` (`Add task evidence API`)
- Target repo: `https://github.com/wuyutanhongyuxin-cell/cailiao`
- Isolated workspace: `/home/kiro/kiro-work/work/cailiao-task`
- Phase: final delivery closeout / 3. task-scoped generate, audit, and export metadata

## Allowed files

- `backend/server.py`
- `tests/test_material_task_flow.py`
- `tools/run_quality_gates.py`
- `README.md`
- `docs/ROADMAP.md`
- `CODEX_HANDOFF.json`

## Forbidden

- Do not add dependencies.
- Do not call network except existing `call_llm` only when user config/API key exists. Tests must not require network or key.
- Do not read `.env` or credentials.
- Do not implement embedding/rerank/NLI providers.
- Do not mark Stage 2B real external parent blockers complete.
- Do not do frontend work.
- Do not change existing `/api/generate` behavior.

## Goal

Add task-scoped endpoints that turn a MaterialTask into a usable backend workflow:

```text
task + approved evidence -> analyze gate -> generate or prompt_only -> save draft/version -> audit/export preflight -> export DOCX
```

This slice is backend/API only. Use existing helpers wherever possible.

## Required helpers

Implement:

```text
generate_material_task(task_id, config=None) -> dict | None
audit_material_task(task_id) -> dict | None
build_material_task_export_preflight(task_id, style_profile=None) -> dict | None
export_material_task_docx(task_id, style_profile=None) -> bytes | None
```

Behavior:

- `generate_material_task`
  - Load task, call `analyze_payload(task_payload(task))`, then `build_prompt`.
  - If analysis status is blocked, do not call LLM. Return mode `blocked`, prompt, empty draft, analysis, writing_state.
  - Else call existing `call_llm(prompt, config)` only like existing `/api/generate`; no new provider logic.
  - If generated draft exists, save it to task `draft`.
  - Append a deterministic draft version using existing `build_draft_version` output if available.
  - Save `latest_analysis`.
  - Return `{task, analysis, mode, prompt, draft, writing_state}`.

- `audit_material_task`
  - Re-run task analysis.
  - Build a compact audit report with status, writing_state, evidence_status, blocker/failure counts, repair unit count, can_export.
  - Save into `manual_approvals` or `repair_history` only if useful and deterministic; do not invent approval.

- `build_material_task_export_preflight`
  - Use existing `build_export_preflight_report(task.title, task.draft, style_profile)`.
  - Include task evidence_status and writing_state/can_export from latest analysis or fresh analysis.
  - Save into `export_artifacts` as metadata item with `kind=docx_preflight`, `created_at`, `passed`/`can_export`.

- `export_material_task_docx`
  - Use existing `export_docx(task.title, task.draft, style_profile)`.
  - Return bytes.
  - Must not export if task missing. Prefer 404 at HTTP layer.

## HTTP API

Add:

```text
POST /api/tasks/{id}/generate
POST /api/tasks/{id}/audit
POST /api/tasks/{id}/export/preflight
POST /api/tasks/{id}/export/docx
```

Responses:

- Missing task -> 404 JSON, except DOCX route also 404 JSON.
- Bad JSON shape -> 422 JSON.
- DOCX success -> same content-type as `/api/export/docx`, filename `material-task-{id}.docx`.

## Tests

Add `tests/test_material_task_flow.py`:

- Blocked task generate does not call LLM and saves latest_analysis.
- Ready/prompt_only path can run without API key and persists draft/version when `call_llm` returns a draft via monkeypatch.
- Audit returns evidence_status, writing_state, counts.
- Export preflight saves export artifact metadata and includes can_export.
- DOCX export returns valid zip bytes for a task draft.
- HTTP generate/audit/preflight/docx routes work.
- Missing task returns 404.
- Bad body returns 422, not 500.

Update `tools/run_quality_gates.py` py-compile list.

## Docs / handoff

Update README/ROADMAP with backend task flow v1. Boundary: no frontend, no new model provider, no automatic approval.

Update `CODEX_HANDOFF.json` with true status and tests.

## Required verification

Run:

```powershell
python -m unittest tests.test_material_task_flow -v
python -m unittest discover -s tests -v
python tools/run_quality_gates.py --json
python -m json.tool CODEX_HANDOFF.json
git diff --check
```

Report exact results in `/home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md`.
