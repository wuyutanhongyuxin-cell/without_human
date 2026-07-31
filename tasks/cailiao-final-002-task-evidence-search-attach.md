# Claude task book
Task ID: cailiao-final-002-task-evidence-search-attach

- Baseline commit: `7f595f6f0bf320e804f99fe7ea4ce12a3b73fd90` (`Add material task API`)
- Target repo: `https://github.com/wuyutanhongyuxin-cell/cailiao`
- Isolated workspace: `/home/kiro/kiro-work/work/cailiao-task`
- Phase: final delivery closeout / 2. connect MaterialTask to evidence library

## Allowed files

- `backend/server.py`
- `tests/test_material_task_evidence.py`
- `tools/run_quality_gates.py`
- `README.md`
- `docs/ROADMAP.md`
- `CODEX_HANDOFF.json`

## Forbidden

- Do not add dependencies.
- Do not call network.
- Do not read `.env` or credentials.
- Do not implement embedding/rerank/NLI providers.
- Do not mark Stage 2B real external parent blockers complete.
- Do not do a frontend rewrite. Backend/API slice only.
- Do not change unrelated evaluation/governance scaffolding.

## Goal

Add task-scoped evidence operations so a user can:

1. Search library evidence for one task.
2. Attach selected library chunks/items to the task.
3. Approve attached evidence into `approved_facts`.
4. Re-run task analysis with the approved/attached evidence already in task state.

This is the bridge from "资料库能力" to "材料任务闭环".

## Required helpers

Implement stdlib-only helpers, reusing existing `search_library`, `verify_claim`, `get_material_task`, `update_material_task`, and `analyze_material_task` where possible:

```text
search_task_evidence(task_id, query=None, filters=None, limit=10) -> dict | None
attach_task_evidence(task_id, evidence_items) -> dict | None
approve_task_evidence(task_id, evidence_ids=None, approved_facts=None) -> dict | None
build_task_evidence_status(task) -> dict
```

Behavior:

- `search_task_evidence`
  - If `query` is missing, derive a conservative query from task title + facts + fields values.
  - Call existing `search_library`.
  - Return `{task_id, query, items, evidence_status}`.
  - Do not mutate task.

- `attach_task_evidence`
  - Accept one item or list.
  - Normalize each item into stable dicts containing at least: `id`, `title`, `source`, `chunk_id` or `document_id` when available, `body` or `text`, `url`, `approved=false`, `attached_at`.
  - Deduplicate by `id` first, then `chunk_id`, then `(title, body/text)`.
  - Store into `selected_evidence`.
  - Return updated task and evidence status.

- `approve_task_evidence`
  - Can approve by `evidence_ids` from already attached items.
  - Can also accept explicit `approved_facts` list.
  - Mark matching `selected_evidence[].approved=true`.
  - Promote approved attached evidence text into `approved_facts` when not already present.
  - Never invent facts beyond attached/explicit input.
  - Return updated task and evidence status.

- `build_task_evidence_status`
  - Return counts: selected, approved_evidence, approved_facts.
  - Return `ready_for_analysis=true` when selected evidence or approved facts exist.
  - Return `method=material_task_evidence_status_v1`.

## HTTP API

Add:

```text
POST /api/tasks/{id}/evidence/search
POST /api/tasks/{id}/evidence/attach
POST /api/tasks/{id}/evidence/approve
GET  /api/tasks/{id}/evidence/status
```

Expected request bodies:

```json
{"query":"...", "filters":{}, "limit":10}
{"items":[{"id":"...", "title":"...", "body":"..."}]}
{"evidence_ids":["..."], "approved_facts":[{"id":"...", "text":"..."}]}
```

404 JSON for missing task. Validation errors should return 422 JSON, not 500.

## Tests

Add `tests/test_material_task_evidence.py` with direct helper and HTTP tests:

- Search derives a query from task fields/facts and returns library results.
- Search does not mutate `selected_evidence`.
- Attach deduplicates evidence and persists it.
- Approve by evidence id marks selected evidence and creates approved facts.
- Explicit approved facts are accepted and deduplicated.
- `analyze_material_task` sees attached approved evidence.
- HTTP routes work end to end.
- Missing task returns 404.
- Bad body shape returns 422, not 500.

Update `tools/run_quality_gates.py` py-compile list for the new test file.

## Docs / handoff

Update:

- `README.md`: note task-scoped evidence attach/approve API v1.
- `docs/ROADMAP.md`: mark final closeout progress for evidence bridge v1. Evidence recommendation is deterministic/library-search only; no semantic provider.
- `CODEX_HANDOFF.json`: true task result, changed files, tests run, and next recommended task.

## Required verification

Run:

```powershell
python -m unittest tests.test_material_task_evidence -v
python -m unittest discover -s tests -v
python tools/run_quality_gates.py --json
python -m json.tool CODEX_HANDOFF.json
git diff --check
```

Report exact results in `/home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md`.
