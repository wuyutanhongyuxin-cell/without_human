# 无人化编排经验

更新时间：2026-07-23

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
