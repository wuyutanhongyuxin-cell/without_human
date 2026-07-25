# 无人化编排经验

更新时间：2026-07-25

## 复盘结论

本项目的无人化不是让 Codex 直接接管 Claude 终端、读取 Claude/Kiro 凭据、修改 Claude Code trust 配置，或让 Claude 获得 GitHub Token。

正确边界仍是职责分离：

```text
Codex 生成阶段任务书
Claude 在隔离工作区内阅读任务书并修改文件
Claude 写交付报告
Codex 提取差异、运行测试、审查和提交
失败则 Codex 写精确返工单
通过则 Codex 推送并进入下一阶段
```

## 本次确认的事实

- `C:\Users\16191\without-human-publish` 保存了无人化编排方案。
- `cailiao` 主线已推进到阶段 2A，下一步是阶段 2B。
- Kiro/Claude 隔离环境的 Key 不落盘；Claude 或 WSL 重启后必须由用户重新隐藏输入一次。
- Codex 禁止从运行进程、环境变量、日志或调试接口提取 Key。
- 禁止为了无人化而持久放宽 `C:\Users\16191\.claude.json` 的 trust 边界。
- 若 Claude 禁用 Bash，则真实测试必须由 Codex 执行。

## 反模式

- 试图用 GUI 自动粘贴控制正在运行的 Claude Code：窗口焦点不可可靠验证，可能误输入到错误会话。
- 试图复用非标准本地 router settings 作为认证通道：属于凭据路径探测，必须有明确授权且仍不应记录凭据。
- 试图把共享目录或用户目录标记为全局 trusted：会持久削弱 Claude Code 信任边界。
- 试图让 Claude 直接 `git push`：会破坏最小权限模型。

## 后续执行规则

1. 阶段推进前，Codex 必须生成 `CLAUDE_TASK.md`，写明允许修改、禁止修改、必须实现、明确不实现和验收测试。
2. Claude 只能在当前授权项目副本内改文件，完成后写交付报告，不自行宣布通过。
3. Codex 独立运行测试、审查 diff、扫描凭据和许可证风险。
4. 连续三轮返工失败后，Codex 接管诊断和实现，避免无限消耗 token。
5. API Key 不落盘是高优先级安全要求；“重启后需要用户输入一次 Key”不是无人化失败，而是安全边界。
6. 若已能在 WSL 内定位 Claude Code 的 TTY，优先向该 TTY 发送短命令，避免 Windows Terminal 标签/句柄错配。

## 2026-07-23 追加：交互终端不可注入时的补救

本次确认：已经打开的 Windows Terminal / OpenConsole 中的 Claude Code 输入框，不能可靠地由 Codex 自动注入消息。GUI 粘贴可能进入错误窗口；低层 `AttachConsole` / `WriteConsoleInputW` 也会失败。因此不要把“控制当前交互窗口”作为无人化基础设施。

补救方案已落地为共享目录脚本：

- `C:\Users\16191\KiroIsolated\OnlySharedWithKiro\Start-Claude-Kiro-Automated.ps1`
- 输入文件：`work\CODEX_TO_CLAUDE.md`
- 输出文件：`work\CLAUDE_TO_CODEX.md`
- ready 文件：`work\CLAUDE_AUTOMATION_READY.txt`
- 日志文件：`work\CLAUDE_AUTOMATION.log`

运行方式：启动自动化 runner 后，用户只需隐藏输入一次 Kiro API Key；之后 Codex 通过写入 `CODEX_TO_CLAUDE.md` 投递任务，runner 用 `claude --print` 非交互执行，并把结果写回 `CLAUDE_TO_CODEX.md`。

边界保持不变：Key 不落盘；Codex 不读取进程环境或日志凭据；Claude 只允许 `Read,Edit`；真实测试、Git 和 GitHub 仍由 Codex 执行。

## 2026-07-25 追加：优先使用 WSL TTY 派发短命令

本次确认：Windows Terminal 的顶层窗口标题、句柄和活动标签可能不一致。即使枚举到标题像 `Claude Code` 的窗口，也可能因为同一 Terminal 进程的活动标签切换，把短命令发到 Codex/material 会话。

更稳定的派发路径是在 WSL 内定位 Claude Code 进程的 TTY：

```bash
ps -eo pid,ppid,tty,stat,comm,args | grep -E 'claude|node|kiro|bash' | grep -v grep
```

确认 `claude` 所在 TTY（本轮为 `pts/0`）后，只把短命令写入该 TTY：

```bash
printf '%s\r' '请读取 /home/kiro/kiro-work/work/CODEX_TO_CLAUDE_LATEST.md 并严格执行。完成后把交付报告写入 /home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md。' > /dev/pts/0
```

长任务仍写入 `CODEX_TO_CLAUDE_LATEST.md`，不要通过 TTY 粘长文本。Codex 继续通过报告时间戳、`git diff --stat`、交付报告和门禁结果低频轮询，避免用高 token 方式盯屏。若 Claude 长时间停滞且未补齐测试/文档/报告，Codex 可接管补齐并在 handoff 中记录接管原因。

## 2026-07-25 追加：TTY 也必须用产物闭环确认

本轮确认：向 `/dev/pts/0` 写入短命令后，不能只凭命令返回 0 判断 Claude 已消费输入。必须继续用低频轮询确认三件事：

- `git status --short` 或 `git diff --stat` 是否出现本轮相关改动；
- `/home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md` 的时间戳和 Task ID 是否更新；
- 必要时用 UIA 明确区分 Codex 窗口（例如 `material-writing-system`）和 Claude 窗口（例如 `Execute Codex-to-Claude task instructions`），再截图确认 Claude 是否正在执行。

如果 TTY 写入没有被消费，可以把完整任务仍保留在 `CODEX_TO_CLAUDE_LATEST.md`，只通过已验证的 Claude 窗口粘贴一行短命令。GUI 发送后仍必须以 diff/report 作为真实依据。

本轮还确认：Claude Code 可能在 `fs_write` 等工具调用阶段出现 `API Error: Upstream ended before completing tool_use`，导致代码 diff 已存在但交付报告未写入。处理规则：

1. 不把旧 `CLAUDE_TO_CODEX.md` 当作本轮报告；
2. 若 diff 已足够完整，Codex 可接管审查、补齐测试稳定性问题、修复 handoff 编码/状态；
3. 在 `CODEX_HANDOFF.json` 和 `without_human` 进度中明确记录“Claude 实现 + Codex 接管验证/修正”的边界；
4. 只有本地门禁、凭据扫描、GitHub Actions 都通过后才更新目标 main commit。
