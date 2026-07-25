# 当前状态

更新时间：2026-07-25

## 总体进度

- 当前阶段：阶段2，混合检索与引用验证（阶段 2B 进行中）
- 状态：进行中
- 目标项目：https://github.com/wuyutanhongyuxin-cell/cailiao
- 目标项目最新 main：`1a9dfdf55d78474f0936da26034c4385b4188c50`（Add anonymized retrieval eval seed）
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
- [x] `cailiao` 已推进到：MVP + 阶段1完成 + 阶段2A完成 + 阶段2B 检索评测基座与匿名占位评测集

## 最近完成

- 2026-07-25：Codex 核对 `cailiao` GitHub main 与阶段分支均为 `86ca6b03c8d12e6ef455c5b2ef68fc7a86196a38` 后，向隔离 Claude Code 派发阶段 2B 任务。
- 2026-07-25：Claude 在 `/home/kiro/kiro-work/work/cailiao-task` 实现匿名检索评测集、逐 case miss 诊断、测试与文档更新，并写入 `/home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md`。
- 2026-07-25：Codex 将改动复制到 `E:\tmp\cailiao-remote`，独立执行门禁：`python -m unittest discover -s tests -v`（52 tests OK）、`python -m py_compile backend/server.py tests/test_library.py`、`git diff --check`、凭据扫描。
- 2026-07-25：Codex 提交并推送 `cailiao` main：`1a9dfdf55d78474f0936da26034c4385b4188c50`。

## 待完成

- [ ] 实现本机傻瓜式无人化控制台（规划见 `docs/OPERATOR_CONSOLE_PLAN.md`），用文件信箱和白名单命令替代 GUI 长文本粘贴
- [ ] 建立 50-100 条真实匿名检索查询集，替换 `tests/data/retrieval_eval_suite.json` 的占位合成集
- [ ] 中文 BM25/FTS 参数调优
- [ ] 向量检索、embedding 管线与可插拔重排
- [ ] 引用蕴含、冲突证据检测与证据不足拒答深化
- [ ] 验证失败返工自动循环并固化为脚本，减少 GUI/窗口定位依赖
- [ ] 修正 Claude 启动脚本 UTF-8 BOM 问题

## 已知约束

- WSL 无法直接使用 Windows localhost 代理；必要时由 Codex 在 Windows 侧准备干净副本或让 WSL 直接 clone public GitHub。
- Claude 的 Key 不落盘，因此进程或 WSL 重启后需要用户重新隐藏输入一次。
- Claude 不应自行执行 Git push；所有真实测试、提交和发布由 Codex 完成。
- 交互窗口派发必须先验证窗口标题与前台句柄；不要向目录名为 `material-writing-system` 的 Codex 标签发送任务。
