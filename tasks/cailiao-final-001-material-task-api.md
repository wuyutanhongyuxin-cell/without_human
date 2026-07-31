# Claude 阶段任务书

Task ID: cailiao-final-001-material-task-api

- 基线提交：`596da19bd051ebd3c72cc351403372ef28727dc6` (`Add final delivery plan`)
- 目标仓库：`https://github.com/wuyutanhongyuxin-cell/cailiao`
- 隔离工作区：`/home/kiro/kiro-work/work/cailiao-task`
- 阶段：最终交付收尾 / 1. 建立 MaterialTask 主轴

## 允许修改

- `backend/server.py`
- `tests/test_material_tasks.py`
- `tools/run_quality_gates.py`（仅当需要把新测试纳入 py-compile 门禁）
- `README.md`
- `docs/ROADMAP.md`
- `CODEX_HANDOFF.json`

## 禁止修改

- 不改 `docs/FINAL_DELIVERY_PLAN.md` 的完工定义，除非只追加本 slice 进度说明。
- 不接真实 embedding/rerank/NLI provider。
- 不联网、不读 `.env`、不读取或打印任何凭据。
- 不改 GitHub Actions，不新增第三方依赖。
- 不做前端大改，本任务只做 MaterialTask 后端/API 最小闭环。
- 不把 Stage 2B 五个真实外部父项改成已完成。

## 必须实现

实现 stdlib-only 的 `MaterialTask` v1，作为后续资料、证据、草稿、审稿、修复、导出的统一主轴。

### 数据持久化

在现有 SQLite 初始化逻辑中新增任务表，建议字段：

```text
id TEXT PRIMARY KEY
title TEXT
genre TEXT
fields_json TEXT
facts TEXT
selected_evidence_json TEXT
approved_facts_json TEXT
draft TEXT
draft_versions_json TEXT
locked_paragraphs_json TEXT
latest_analysis_json TEXT
repair_history_json TEXT
export_artifacts_json TEXT
manual_approvals_json TEXT
created_at TEXT
updated_at TEXT
```

要求：

- 不破坏现有 evidence/library 表。
- JSON 字段用 `json.dumps(..., ensure_ascii=False, sort_keys=True)` 或等价确定性写法。
- 读出任务时还原为 JSON 对象/列表。
- 缺省值稳定：`fields={}`、`selected_evidence=[]`、`approved_facts=[]`、`draft=""`。

### 后端 helper

新增纯函数/小接口：

```text
create_material_task(payload) -> dict
list_material_tasks(limit=50) -> list[dict]
get_material_task(task_id) -> dict | None
update_material_task(task_id, payload) -> dict
task_payload(task) -> dict
analyze_material_task(task_id) -> dict
```

`task_payload(task)` 必须转成现有 `analyze_payload` / `build_prompt` 可接受结构：

```text
genre
title
fields
facts
draft
evidence
approved_facts
locked_paragraphs
```

`analyze_material_task(task_id)`：

- 调用现有 `analyze_payload(task_payload(task))`。
- 把结果保存到 `latest_analysis_json`。
- 返回 `{task, analysis}`。

### HTTP API

新增：

```text
POST /api/tasks
GET /api/tasks
GET /api/tasks/{id}
PUT /api/tasks/{id}
POST /api/tasks/{id}/analyze
```

行为：

- `POST /api/tasks` 创建任务，允许只传 `title`/`genre`，缺省 genre 为 `work_plan`。
- `GET /api/tasks` 返回最近任务，按 `updated_at` 倒序。
- `GET /api/tasks/{id}` 不存在返回 404 JSON。
- `PUT /api/tasks/{id}` 只更新允许字段，不允许改 `id`/`created_at`。
- `POST /api/tasks/{id}/analyze` 保存并返回最新 analysis。

必须保留现有 `/api/analyze`、`/api/generate`、`/api/export/docx` 行为兼容。

## 明确不实现

- 不实现证据推荐/attach/approve，这留给下一轮。
- 不实现段落修复接口。
- 不实现任务列表前端 UI。
- 不实现导出门禁。
- 不迁移浏览器 localStorage 旧草稿。

## 验收测试

新增 `tests/test_material_tasks.py`，至少覆盖：

```text
创建任务后可读取，默认值正确。
更新任务后 updated_at 改变，created_at 不变。
list_material_tasks 按 updated_at 倒序。
task_payload 可被 analyze_payload 使用。
analyze_material_task 会保存 latest_analysis_json。
HTTP POST/GET/PUT/POST analyze 全部可用。
不存在的 task_id 返回 404。
非法 JSON 字段不导致 500；应保守归一为空对象/列表或返回 400。
```

运行建议：

```powershell
python -m unittest tests.test_material_tasks -v
python -m unittest discover -s tests -v
python tools/run_quality_gates.py --json
git diff --check
python -m json.tool CODEX_HANDOFF.json
```

## 文档更新

更新：

- `README.md`：当前能力表增加 `MaterialTask`/材料任务主轴 v1。
- `docs/ROADMAP.md`：在最终收尾/近期实施处说明 MaterialTask v1 已落地，证据推荐/批准仍待下一轮。
- `CODEX_HANDOFF.json`：写本任务真实交付、未实现项、建议测试。不要写测试通过，除非你确实运行了。

## 安全限制

- 不读取 `.env`。
- 不打印 API key/token。
- 不新增网络调用。
- 不改供应商配置。
- 不把人工/真实数据写入仓库。

## 交付信息

完成后写入 `/home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md`，必须包含：

```text
Task ID: cailiao-final-001-material-task-api
Status:
Changed files:
Implemented:
Not implemented:
Tests run:
Risks:
```

