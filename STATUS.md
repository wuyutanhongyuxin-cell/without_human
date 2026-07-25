# 当前状态

更新时间：2026-07-25

## 总体进度

- 当前阶段：阶段2，混合检索与引用验证（阶段 2B 进行中）
- 状态：进行中
- 目标项目：https://github.com/wuyutanhongyuxin-cell/cailiao
- 目标项目最新 main：`240a14a2a7216ce88a1d3c6d9923e74fdfa26558`（Add claim evidence mapping）
- 执行策略：Claude 只在隔离 WSL 工作区改代码，Codex 负责验证、Git 和 GitHub 发布

## 已确认

- [x] Claude 运行在 KiroUbuntu 隔离 WSL 中
- [x] Windows 盘未挂载
- [x] WSL interop 已禁用
- [x] Claude 不保存 API Key；Key 由用户在本机启动器隐藏输入
- [x] GitHub 写操作由 Codex 承担
- [x] Codex 可准确定位并向标题为 `Claude Code` 的 Windows Terminal 会话派发任务
- [x] 稳定派发方式：完整任务写入 `/home/kiro/kiro-work/work/CODEX_TO_CLAUDE_LATEST.md`，只向 Claude Code 输入框发送短命令读取该文件
- [x] Codex 可从 `/home/kiro/kiro-work/work/cailiao-task` 提取 Claude 修改并在 Windows 发布仓库独立验证
- [x] `cailiao` 已推进到：MVP + 阶段1完成 + 阶段2A完成 + 阶段2B 检索评测基座、匿名占位评测集、中文 BM25/FTS 调优 v1、评测可解释性、评测 CLI 门禁、BM25 参数扫描框架、统一质量门禁脚本与 GitHub Actions、主张到证据精确映射 v1

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

## 待完成

- [x] 实现本机傻瓜式无人化控制台 P0（规划见 `docs/OPERATOR_CONSOLE_PLAN.md`），用文件信箱和白名单命令替代 GUI 长文本粘贴
- [ ] 控制台 P1：一键准备/刷新 WSL 隔离副本，并减少对 GUI 窗口定位的依赖
- [ ] 建立 50-100 条真实匿名检索查询集，替换 `tests/data/retrieval_eval_suite.json` 的占位合成集
- [x] 将 `eval-retrieval` CLI 固化到 Codex/CI 门禁脚本
- [ ] 更大真实查询集上的 BM25/FTS 扫参与阈值校准
- [ ] 向量检索、embedding 管线与可插拔重排
- [x] 主张到证据精确映射 v1：逐标记归因到覆盖分段列表、漏标记、逐分段命中详情和覆盖率
- [ ] 引用语义蕴含、冲突证据检测与证据不足拒答深化
- [ ] 验证失败返工自动循环并固化为脚本，减少 GUI/窗口定位依赖
- [ ] 修正 Claude 启动脚本 UTF-8 BOM 问题

## 已知约束

- WSL 无法直接使用 Windows localhost 代理；必要时由 Codex 在 Windows 侧准备干净副本或让 WSL 直接 clone public GitHub。
- Claude 的 Key 不落盘，因此进程或 WSL 重启后需要用户重新隐藏输入一次。
- Claude 不应自行执行 Git push；所有真实测试、提交和发布由 Codex 完成。
- 交互窗口派发必须先验证窗口标题与前台句柄；不要向目录名为 `material-writing-system` 的 Codex 标签发送任务。
