# 当前状态

更新时间：2026-07-26

## 总体进度

- 当前阶段：阶段2，混合检索与引用验证（阶段 2B 进行中）
- 状态：进行中
- 目标项目：https://github.com/wuyutanhongyuxin-cell/cailiao
- 目标项目最新 main：`6689a537bcda1426849cd0b9d055d2e5417d42bf`（Add writing workflow state machine）
- 执行策略：Claude 只在隔离 WSL 工作区改代码，Codex 负责验证、Git 和 GitHub 发布

## 已确认

- [x] Claude 运行在 KiroUbuntu 隔离 WSL 中
- [x] Windows 盘未挂载
- [x] WSL interop 已禁用
- [x] Claude 不保存 API Key；Key 由用户在本机启动器隐藏输入
- [x] GitHub 写操作由 Codex 承担
- [x] Codex 可通过 WSL TTY 优先派发短命令，并在 TTY 不消费输入时用 UIA/窗口截图确认 Claude Code 状态
- [x] 稳定派发方式：完整任务写入 `/home/kiro/kiro-work/work/CODEX_TO_CLAUDE_LATEST.md`，只向 Claude Code 输入框发送短命令读取该文件
- [x] Codex 可从 `/home/kiro/kiro-work/work/cailiao-task` 提取 Claude 修改并在 Windows 发布仓库独立验证
- [x] `cailiao` 已推进到：MVP + 阶段1完成 + 阶段2A完成 + 阶段2B 检索评测基座、匿名占位评测集、中文 BM25/FTS 调优 v1、评测可解释性、评测 CLI 门禁、BM25 参数扫描框架、统一质量门禁脚本与 GitHub Actions、主张到证据精确映射 v1、可审计检索/核验面板 v1、元数据过滤 UI/评测覆盖 v1、评测集结构校验工具 v1、确定性冲突证据候选 v1、向量检索/embedding 管线骨架 v1、可插拔重排管线骨架 v1、证据不足/拒绝理由 v1、前端不足审计面板 v1、阶段3写作状态机 v1

## 最近完成

- 2026-07-25：Codex 核对 `cailiao` GitHub main 与阶段分支均为 `86ca6b03c8d12e6ef455c5b2ef68fc7a86196a38` 后，向隔离 Claude Code 派发阶段 2B 任务。
- 2026-07-25：Claude 在 `/home/kiro/kiro-work/work/cailiao-task` 实现匿名检索评测集、逐 case miss 诊断、测试与文档更新，并写入 `/home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md`。
- 2026-07-25：Codex 将改动复制到 `E:\tmp\cailiao-remote`，独立执行门禁：`python -m unittest discover -s tests -v`（52 tests OK）、`python -m py_compile backend/server.py tests/test_library.py`、`git diff --check`、凭据扫描。
- 2026-07-25：Codex 提交并推送 `cailiao` main：`1a9dfdf55d78474f0936da26034c4385b4188c50`。
- 2026-07-25：在 `without_human` 增加本机无人化控制台 P0：`control/server.py`、`control/projects.json`、`frontend/`，用于低 token 状态读取、WSL 任务文件写入、报告读取和白名单 Codex 门禁。
- 2026-07-25：增加 Windows 一键启动脚本 `scripts\Start Without Human Console.cmd`，可从桌面快捷方式启动/打开控制台。
- 2026-07-25：Codex 将隔离 Claude Code 同步到 `cailiao` 最新 main `1a9dfdf55d78474f0936da26034c4385b4188c50`，派发阶段 2B-BM25/FTS 调优 v1 任务，并确认命令进入正确的 Claude Code Windows Terminal 会话。
- 2026-07-25：Claude 在 `/home/kiro/kiro-work/work/cailiao-task` 实现确定性 `bm25_like` 通道、查询词元扩展、`top_reasons` 评测解释字段、测试与文档更新，并写入 `/home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md`。
- 2026-07-25：Codex 提取 diff 到 `E:\tmp\cailiao-remote`，独立执行门禁：`python -m py_compile backend/server.py tests/test_library.py`、`python -m unittest discover -s tests -v`（58 tests OK）、`git diff --check`、凭据形态扫描。
- 2026-07-25：Codex 修正 `CODEX_HANDOFF.json` 为 `verified_by_codex`，提交并推送 `cailiao` main：`c9a4cc74d453a135d3768660465a4f97c1e7246e`。
- 2026-07-25：Codex 将隔离 Claude Code 以本地 bundle 方式同步到 `cailiao` 已发布 main `c9a4cc74d453a135d3768660465a4f97c1e7246e`，避免 WSL 网络 fetch 超时影响下一轮派工。
- 2026-07-25：Claude 实现 `eval-retrieval` CLI、可复用 suite loader/runner、临时 SQLite 隔离、阈值门禁、`tools/evaluate_retrieval.py` 包装入口与 BM25 k1/b 参数化/扫参框架。
- 2026-07-25：Codex 提取第二轮 diff 到 `E:\tmp\cailiao-remote`，独立执行门禁：`python -m py_compile backend/server.py tests/test_library.py tools/evaluate_retrieval.py`、`python -m unittest discover -s tests -v`（71 tests OK）、`python backend/server.py eval-retrieval ...`（exit 0）、`python tools/evaluate_retrieval.py ...`（exit 0）、`git diff --check`、凭据形态扫描。
- 2026-07-25：Codex 修正 `CODEX_HANDOFF.json` 为 `verified_by_codex`，提交并推送 `cailiao` main：`652e890b2691991465cfebb10bf420429189983b`。
- 2026-07-25：Claude 实现 `tools/run_quality_gates.py` 统一门禁入口、`.github/workflows/quality-gates.yml`、`tests/test_quality_gates.py` 与文档更新。
- 2026-07-25：Codex 复核第三轮时发现并修复两处真实问题：`.env.example` 被误判为私有 env 文件、`sys.executable` 在当前 Windows Python 分发下导致子进程启动被拒绝；改为模板 env 正常扫描、门禁默认使用 `python` 命令并支持 `PYTHON` 覆盖。
- 2026-07-25：Codex 独立执行门禁：`python -m py_compile ...`、`python -m unittest discover -s tests -v`（82 tests OK）、`python backend/server.py eval-retrieval ...`（exit 0）、`python tools/run_quality_gates.py --json`（passed=true，5 gates passed）、`git diff --check`。
- 2026-07-25：Codex 提交并推送 `cailiao` main：`970d93873fb21c935dea05fa8c51153e04b185f6`；GitHub Actions `quality-gates` run `30162797057` 已完成并通过。
- 2026-07-25：Claude 实现阶段 2B 主张到证据精确映射 v1；Codex 复核发现 `covered_markers` 起初为单 chunk 标量，不满足多分段覆盖要求，向隔离 Claude Code 发出返工单。
- 2026-07-25：Claude 返工为 `{marker: [chunk_id, ...]}` 列表语义，并补充同一标记跨多分段、HTTP JSON 往返和保守核验测试；Codex 提取 diff 到 `E:\tmp\cailiao-remote` 独立审查。
- 2026-07-25：Codex 独立执行门禁：`python -m py_compile backend/server.py tests/test_library.py tools/evaluate_retrieval.py tools/run_quality_gates.py tests/test_quality_gates.py`、`python -m unittest discover -s tests -v`（88 tests OK）、`python tools/run_quality_gates.py --json`（passed=true，5 gates passed）、`git diff --check`、凭据形态扫描。
- 2026-07-25：Codex 修正 `CODEX_HANDOFF.json` 为 `verified_by_codex`，提交并推送 `cailiao` main：`240a14a2a7216ce88a1d3c6d9923e74fdfa26558`；GitHub Actions `quality-gates` run `30163809068` 已完成并通过。
- 2026-07-25：Codex 将隔离 Claude Code 同步到 `cailiao` 最新 main `240a14a2a7216ce88a1d3c6d9923e74fdfa26558`，派发阶段 2B 可审计检索/核验面板 v1 任务。
- 2026-07-25：Claude 补齐资料库“检索与核验”前端标签与面板，修复 `app.js` 引用缺失 DOM 导致资料库 UI 事件绑定中断的问题，并展示 `top_reasons`、通道 rank/score、BM25/向量状态和 `evidence_map`。
- 2026-07-25：Codex 提取 diff 到 `E:\tmp\cailiao-remote`，独立执行门禁：`python -m py_compile ... tests/test_frontend_ui.py ...`、`python -m unittest discover -s tests -v`（97 tests OK）、`python tools/run_quality_gates.py --json`（passed=true，5 gates passed）、`git diff --check`、凭据形态扫描。
- 2026-07-25：Codex 额外用 Chrome DevTools 在 `http://127.0.0.1:8766/` 做浏览器冒烟：页面加载、资料库标签、检索与核验标签、空检索/空核验 guard 均通过；仅发现非阻断 favicon 404 与既有表单 label/id 可访问性提示。
- 2026-07-25：Codex 修正 `CODEX_HANDOFF.json` 为 `verified_by_codex`，提交并推送 `cailiao` main：`fdb231888714df93b1d82288779b6be5823c2e2e`；GitHub Actions `quality-gates` run `30164635223` 已完成并通过。
- 2026-07-25：Codex 发现 Windows Terminal 句柄/活动标签可能错配，改用 WSL `ps` 定位 Claude Code 所在 `pts/0`，直接向 `/dev/pts/0` 写入短命令，成功派发下一轮任务，后续应优先采用该 TTY 派发方式。
- 2026-07-25：Claude 完成元数据过滤 v1 的后端/前端初稿后长时间停滞，未补测试/文档/报告；Codex 按无人化规则接管，补齐测试、文档与 `CODEX_HANDOFF.json`。
- 2026-07-25：`cailiao` 新增 `organization` 与 `format` 检索过滤，前端检索/核验面板新增机关、格式、发布日期区间和有效性范围控件，并显示“生效过滤”摘要；测试覆盖 `search_library`、HTTP `/api/library/search`、评测 case 级过滤和前端静态 UI。
- 2026-07-25：Codex 独立执行门禁：`python -m py_compile ...`、`python -m unittest discover -s tests -v`（101 tests OK）、`python tools/run_quality_gates.py --json`（passed=true，5 gates passed）、`git diff --check`、凭据形态扫描；Chrome DevTools 冒烟确认新增控件与过滤摘要可见。
- 2026-07-25：Codex 提交并推送 `cailiao` main：`6c2ec752c8465a0a839905c21ed6463a417989ac`；GitHub Actions `quality-gates` run `30165613093` 已完成并通过。
- 2026-07-25：Codex 派发阶段 2B 评测集结构校验工具 v1；TTY 写入未立即被 Claude 消费时，改用 UIA 精确区分 `material-writing-system`（Codex）与 `Execute Codex-to-Claude task instructions`（Claude）窗口，并用截图确认 Claude 已在执行。
- 2026-07-25：Claude 在隔离工作区实现 `server.validate_retrieval_suite`、`tools/validate_retrieval_suite.py`、`tests/test_suite_validator.py` 与文档更新，但写交付报告时遇到 Claude Code `API Error: Upstream ended before completing tool_use ... (fs_write)`；Codex 按无人化规则提取 diff 接管审核。
- 2026-07-25：Codex 发现并修复两处交付质量问题：CLI 无效套件测试写入 `tests/data` 导致受限目录失败，改为 `tempfile.TemporaryDirectory`；`CODEX_HANDOFF.json` 出现 mojibake，改为 ASCII 可审计 JSON 并写入真实验证结果。
- 2026-07-25：Codex 独立执行门禁：`python -m py_compile ... tools/validate_retrieval_suite.py tests/test_suite_validator.py`、`python -m unittest discover -s tests -v`（118 tests OK）、`python tools/validate_retrieval_suite.py --suite tests/data/retrieval_eval_suite.json --json`（passed=true，含占位与 <50 告警）、`python tools/run_quality_gates.py --json`（passed=true，5 gates passed）、`git diff --check`、凭据形态扫描。
- 2026-07-25：Codex 提交并推送 `cailiao` main：`320b5d4b1750dfb3255044bb5fff2c37f964e164`；GitHub Actions `quality-gates` run `30166642045` 已完成并通过。
- 2026-07-26：上一轮派发 `cailiao-stage2b-conflict-evidence-v1` 后，Codex 普通沙箱视角一度看不到 `KiroUbuntu`，但提权宿主视角确认 `KiroUbuntu` 仍在运行、Claude 进程仍绑定 `/dev/pts/0`；隔离仓库保留 Claude 的旧 diff/report。Codex 已从 `cailiao` main `320b5d4b1750dfb3255044bb5fff2c37f964e164` 独立实现、验证并发布确定性冲突证据候选 v1，未采用该旧 diff。
- 2026-07-26：`cailiao` 新增 `detect_conflict_evidence` 与 `verify_claim.conflict_evidence`，对同上下文不同数量标记、必备标记附近明确否定进行保守提示；命中时把原本 `supported` 的结论降级为 `needs_verification`，不声称语义蕴含或真实矛盾证明。
- 2026-07-26：Codex 修正统一门禁 `py-compile`，使用临时 `PYTHONPYCACHEPREFIX`，避免受旧 `__pycache__` 目录 ownership 影响。
- 2026-07-26：Codex 独立执行门禁：`python -m unittest discover -s tests -v`（121 tests OK）、`python tools/validate_retrieval_suite.py --suite tests/data/retrieval_eval_suite.json --json`（passed=true，含占位与 <50 告警）、`python tools/run_quality_gates.py --json`（passed=true，5 gates passed）、`git diff --check`、凭据形态扫描。
- 2026-07-26：Codex 提交并推送 `cailiao` main：`1e4a77edccbc9ff3fbd46fe01dc1aa4dfab1a757`。
- 2026-07-26：Codex 向 Claude `/dev/pts/0` 写入短状态，告知 conflict-evidence-v1 已由 Codex 发布，隔离工作区旧 diff 不要继续应用，等待下一轮明确任务。
- 2026-07-26：Codex 做握手验证：直接写 `/dev/pts/0` 未产生 ack；通过 UIA 聚焦 `1 awaiting input · claude agents` 窗口、粘贴短命令并回车后，Claude 写入 `/home/kiro/kiro-work/work/CLAUDE_ACK_FROM_CODEX.txt`，内容为 `ACK codex-claude-handshake-20260726`。结论：Claude Code 可交互，但本会话应优先使用“任务文件 + 已验证 Claude 窗口短命令 + ack/report 文件回执”的闭环，不只凭 TTY 写入返回码判断成功。
- 2026-07-26：新增 CLI 桥接脚本：`scripts/check-claude-channel.ps1`、`scripts/send-claude-handshake.ps1`、`scripts/send-claude-task.ps1`；保留 Codex CLI + Claude Code CLI 双会话模式，只脚本化通道检查、任务文件写入、UIA 短命令和 ack/report 产物验证。新增 `scripts/invoke-deepseek-task.ps1` 与 `docs/DEEPSEEK_DELEGATION.md`，用于 Codex 侧低风险任务委派；DeepSeek key 只从仓库外 `DEEPSEEK_API_KEY` 环境变量读取。
- 2026-07-26：Codex 先将 Claude 隔离仓库旧 conflict-evidence diff 以 stash 归档，再用本地补丁同步到已发布 `cailiao` main `1e4a77edccbc9ff3fbd46fe01dc1aa4dfab1a757`，并在 WSL 以 `python3 -m unittest discover -s tests -v` 验证 121 tests OK 后创建本地同步基线提交 `20bc2f5 Sync`（不推送）。
- 2026-07-26：Codex 派发 `cailiao-stage2b-vector-pipeline-skeleton-v1` 给 Claude Code；Claude 完成后端、测试、文档和交付报告，但未能在 Claude 工具环境运行测试。Codex 提取 diff 到 Windows 发布仓库并独立审核。
- 2026-07-26：`cailiao` 新增阶段 2B 向量检索/可替换 embedding 管线骨架 v1：默认关闭的 `VectorEmbedder`、`DeterministicHashEmbedder`、`InProcessVectorIndex`、`VectorPipeline`、`resolve_vector_pipeline`，`search_library(..., vector_config=...)` 与 HTTP `?vector=` opt-in；确定性本地测试通道只做词面特征哈希，不是真实语义 embedding，不联网、不读凭据、不持久化向量库。
- 2026-07-26：Codex 修正交付质量细节：`CODEX_HANDOFF.json` 标为 `verified_by_codex`，`docs/ROADMAP.md` 将“骨架 v1 已完成”和“真实 embedding provider/持久化向量库待完成”拆开，`tools/run_quality_gates.py` 的 py-compile 门禁纳入 `tests/test_vector_pipeline.py`。
- 2026-07-26：Codex 独立执行门禁：`python -m unittest discover -s tests -v`（133 tests OK）、`python tools/validate_retrieval_suite.py --suite tests/data/retrieval_eval_suite.json --json`（passed=true，含占位与 <50 告警）、`python tools/run_quality_gates.py --json`（passed=true，5 gates passed）、`git diff --check`。提交并推送 `cailiao` main：`fb7e36b307e7dd8bde2906f192e5bd38b7a2e1da`；GitHub Actions `quality-gates` run `30189895434` success。
- 2026-07-26：Claude 通道经验更新：当前 Claude Code 窗口标题可能变为 `codex_to_claude ack`，`scripts/send-claude-task.ps1` 已补充匹配 `codex_to_claude`。DeepSeek 低风险规划调用遇到 PowerShell 发送/TLS 连接关闭，`scripts/invoke-deepseek-task.ps1` 已在调用前固定 TLS 1.2；后续仍需一次成功 live call 才能把 DeepSeek 标为已验证。
- 2026-07-26：Codex 派发 `cailiao-stage2b-reranker-skeleton-v1` 给 Claude Code；Claude 完成默认关闭的 `Reranker`、`DeterministicLocalReranker`、`RerankPipeline`、`resolve_rerank_pipeline`、`search_library(..., rerank_config=...)` 与 HTTP `?rerank=`，并补充评测、文档和交付报告。该骨架只对已融合 Top K 做确定性重排，不新增召回、不联网、不读凭据。
- 2026-07-26：Codex 修正交付质量细节：`CODEX_HANDOFF.json` 标为 `verified_by_codex` 并写入真实验证结果，`tools/run_quality_gates.py` 的 py-compile 门禁纳入 `tests/test_reranker_pipeline.py`。
- 2026-07-26：Codex 独立执行门禁：`python -m unittest discover -s tests -v`（147 tests OK）、`python tools/validate_retrieval_suite.py --suite tests/data/retrieval_eval_suite.json --json`（passed=true，含占位与 <50 告警）、`python tools/run_quality_gates.py --json`（passed=true，5 gates passed）、`python -m json.tool CODEX_HANDOFF.json`、`git diff --check`、凭据形态扫描。提交并推送 `cailiao` main：`6543b7bc6e5ea37c0b7447ceab16bc0ba0695d29`；GitHub Actions `quality-gates` run `30194430236` success。
- 2026-07-26：Codex 派发 `cailiao-stage2b-claim-insufficiency-v1` 给 Claude Code。首次轮询被旧 `CLAUDE_TO_CODEX.md` 污染，Codex 归档旧报告后重新派发；截图确认命令进入 `codex_to_claude ack` 的 Claude Code 窗口，Claude 完成 `build_evidence_insufficiency`、`verify_claim.insufficiency`、测试与文档，但未在 Claude 环境运行测试。
- 2026-07-26：`cailiao` 新增确定性证据不足/拒绝理由 v1：`insufficiency` 每次随 `verify_claim` 返回，包含 `has_insufficiency`、`summary`、`blocking`、`missing_markers`、`conflict_count`、词面 `overlap`、机器可读 `details` 与 `method=deterministic_lexical_insufficiency_v1`；它只解释词面证据为何不足，不是语义蕴含、NLI、真伪判断或真实矛盾证明。
- 2026-07-26：Codex 修正交付质量细节：`CODEX_HANDOFF.json` 标为 `verified_by_codex` 并写入真实验证结果，`tools/run_quality_gates.py` 的 py-compile 门禁纳入 `tests/test_claim_insufficiency.py`，`docs/ROADMAP.md` 同步阶段 2B 状态。
- 2026-07-26：Codex 独立执行门禁：`python -m unittest discover -s tests -v`（155 tests OK）、`python -m unittest tests.test_claim_insufficiency -v`（8 tests OK）、`python tools/validate_retrieval_suite.py --suite tests/data/retrieval_eval_suite.json --json`（passed=true，含占位与 <50 告警）、`python tools/run_quality_gates.py --json`（passed=true，5 gates passed）、`python -m json.tool CODEX_HANDOFF.json`、`git diff --check`、凭据形态扫描。提交并推送 `cailiao` main：`d73345d5d98068c5e4c8cefab5cf99d017f4f79a`；GitHub Actions `quality-gates` run `30195181509` success。
- 2026-07-26：Codex 派发 `cailiao-stage2b-frontend-insufficiency-panel-v1` 给 Claude Code；Claude 在前端资料库“检索与核验”渲染中加入 `renderInsufficiency`，显示 `summary`、`blocking`、`missing_markers`、`conflict_count`、词面 `overlap`、`details` 与 `method`，并保持旧响应无 `insufficiency` 时 no-op。
- 2026-07-26：Codex 独立审核确认前端文案只称“确定性词面审计/非语义/NLI/真伪判断”，动态值使用既有 `escapeHtml`；执行门禁：`python -m unittest tests.test_frontend_ui -v`（13 tests OK）、`python -m unittest discover -s tests -v`（158 tests OK）、`python tools/validate_retrieval_suite.py --suite tests/data/retrieval_eval_suite.json --json`（passed=true，含占位与 <50 告警）、`python tools/run_quality_gates.py --json`（passed=true，5 gates passed）、`python -m json.tool CODEX_HANDOFF.json`、`git diff --check`、凭据形态扫描。提交并推送 `cailiao` main：`cdbf8be0b93475e5575c46ca92dd7fd280e5ff79`；GitHub Actions `quality-gates` run `30195664586` success。
- 2026-07-26：Codex 派发 `cailiao-stage3-writing-state-machine-v1` 给 Claude Code；Claude 新增 `build_writing_state(payload, analysis)`，把五态 `materials_insufficient/资料不足`、`ready_to_draft/可起草`、`needs_revision/待修`、`ready_for_review/待审`、`ready_to_export/可导出` 作为确定性附加层并入 `analyze_payload` 与 `/api/generate` 响应；`review_approved`/`approved` 不能覆盖 blocker/fail。
- 2026-07-26：Codex 修正交付质量细节：`CODEX_HANDOFF.json` 标为 `verified_by_codex`，`tools/run_quality_gates.py` 的 py-compile 门禁纳入 `tests/test_writing_state.py`；执行门禁：`python -m unittest tests.test_writing_state -v`（10 tests OK）、`python -m unittest discover -s tests -v`（168 tests OK）、`python tools/validate_retrieval_suite.py --suite tests/data/retrieval_eval_suite.json --json`（passed=true，含占位与 <50 告警）、`python tools/run_quality_gates.py --json`（passed=true，5 gates passed）、`python -m json.tool CODEX_HANDOFF.json`、`git diff --check`、凭据形态扫描。提交并推送 `cailiao` main：`6689a537bcda1426849cd0b9d055d2e5417d42bf`；GitHub Actions `quality-gates` run `30196250953` success。

## 待完成

- [x] 实现本机傻瓜式无人化控制台 P0（规划见 `docs/OPERATOR_CONSOLE_PLAN.md`），用文件信箱和白名单命令替代 GUI 长文本粘贴
- [ ] 控制台 P1：一键准备/刷新 WSL 隔离副本，并减少对 GUI 窗口定位的依赖
- [ ] 建立 50-100 条真实匿名检索查询集，替换 `tests/data/retrieval_eval_suite.json` 的占位合成集
- [x] 将 `eval-retrieval` CLI 固化到 Codex/CI 门禁脚本
- [ ] 更大真实查询集上的 BM25/FTS 扫参与阈值校准
- [x] 向量检索与可替换 embedding 管线骨架 v1：默认关闭、确定性本地测试通道、无网络/凭据/持久化向量库
- [x] 可插拔重排管线骨架 v1：默认关闭、确定性本地测试重排器、只重排已融合 Top K、无网络/凭据/新召回
- [x] 证据不足/拒绝理由 v1：`verify_claim.insufficiency` 输出稳定、机器可读的词面审计原因，覆盖无证据、漏标记、冲突候选、弱词面重合与 clean supported
- [x] 前端不足审计面板 v1：资料库“检索与核验”展示 `insufficiency` 审计块，兼容旧响应且明确非语义/NLI
- [ ] 真实 embedding provider、持久化向量库与生产级 reranker provider
- [x] 主张到证据精确映射 v1：逐标记归因到覆盖分段列表、漏标记、逐分段命中详情和覆盖率
- [x] 可审计检索/核验面板 v1：前端展示 RRF 分、通道 rank/score、命中理由、BM25/向量状态、主张核验证据映射与空输入保护
- [x] 元数据过滤 UI/评测覆盖 v1：机关、格式、日期区间、有效性范围、地区、来源类型、权威、文档/分段状态的搜索/HTTP/评测覆盖
- [x] 评测集结构校验工具 v1：校验 id 唯一、query 非空、过滤键、相关性目标、min_authority/format，并以错误/告警区分结构违规与占位/数量不足风险
- [x] 确定性冲突证据候选 v1：同上下文不同数量、明确否定候选，命中降级为待核实
- [ ] 引用语义蕴含、完整语义级冲突证据检测与模型/规则结合的拒答深化
- [x] 阶段3写作状态机 v1：`writing_state` 五态、`can_generate`/`can_export`、blocker/fail/warning 分组与确定性 `required_actions`
- [ ] 将 WSL TTY 派发、报告轮询、diff 提取、门禁与返工循环固化为脚本，减少 GUI/窗口定位依赖
- [ ] 修正 Claude 启动脚本 UTF-8 BOM 问题

## 已知约束

- WSL 无法直接使用 Windows localhost 代理；必要时由 Codex 在 Windows 侧准备干净副本或让 WSL 直接 clone public GitHub。
- Claude 的 Key 不落盘，因此进程或 WSL 重启后需要用户重新隐藏输入一次。
- Claude 不应自行执行 Git push；所有真实测试、提交和发布由 Codex 完成。
- 交互窗口派发必须先验证窗口标题与前台句柄；不要向目录名为 `material-writing-system` 的 Codex 标签发送任务。
- 普通沙箱用户 `sjtu-tony\codexsandboxoffline` 可能看不到按宿主用户注册的 WSL 发行版；需要读取/派发 `KiroUbuntu` 时，应使用已授权的宿主/提权命令上下文。提权视角已确认 `KiroUbuntu` running、Claude PID 9 在 `/dev/pts/0`。

## DeepSeek live delegation fix
- 2026-07-26: Codex fixed scripts/invoke-deepseek-task.ps1 for stable low-risk DeepSeek helper usage. Changes: UTF-8 no-BOM byte body for Invoke-RestMethod, -Transport Auto|InvokeRestMethod|Curl, curl fallback with no-BOM temp JSON outside repo, 1MB request body guard, parsed sanitized API error bodies, and empty-content failure. Live smoke passed with deepseek-v4-flash and -MaxTokens 100 for both Auto and Curl transports. No API key was printed, no request body was committed, and scratch files were removed.

## cailiao Stage 3 structured writing plan v1
- 2026-07-26: Codex attempted the normal two-CLI loop for `cailiao-stage3-structured-writing-plan-v1`: task file was written to `/home/kiro/kiro-work/work/CODEX_TO_CLAUDE_LATEST.md`, UIA send was attempted, then the verified Claude TTY `/dev/pts/0` was used. The WSL repo stayed clean and `CLAUDE_TO_CODEX.md` still reported the previous task, so Claude Code did not consume this task in the polling window.
- 2026-07-26: To avoid stalling, Codex implemented the small Stage 3 slice directly in `E:\tmp\cailiao-remote`: `build_structured_writing_plan(payload, analysis)` plus request-local evidence adaptation, tests, quality-gate coverage, README/ROADMAP, and `CODEX_HANDOFF.json`.
- 2026-07-26: Local gates passed before push: `python -m unittest tests.test_structured_writing_plan -v` (7 tests OK), `python -m unittest discover -s tests -v` (175 tests OK), retrieval suite validator passed with expected placeholder/<50 warnings, `python tools/run_quality_gates.py --json` passed 5/5, `python -m json.tool CODEX_HANDOFF.json` passed, and `git diff --check` passed.
- 2026-07-26: Pushed `cailiao` main `4ae1ba1 Add structured writing plan`; GitHub Actions `quality-gates` run `30199395069` completed with conclusion `success`. DeepSeek was kept available as the low-token helper, but no live DeepSeek call was needed for this deterministic implementation/review slice.
- 2026-07-26: Post-push WSL resync blocker resolved. Root cause: PowerShell/cmd text pipelines corrupted the git bundle bytes (CRLF/text conversion), and `/mnt/e` was unavailable; WSL network fetch also timed out. Fix: added `scripts/sync-wsl-from-windows-bundle.ps1`, which creates a bundle from the verified Windows release repo and transfers it through a .NET binary stdin stream to WSL. The script stashes dirty WSL work by default, verifies the bundle, fetches it, and resets the isolated repo to the bundle head. Verified result: `/home/kiro/kiro-work/work/cailiao-task` is clean at `4ae1ba1bb15cc82a0fcd16ca152103715889b410` (`4ae1ba1 Add structured writing plan`); previous dirty WSL work was preserved as `stash@{0}: codex-pre-sync-structured-writing-plan-20260726`.
