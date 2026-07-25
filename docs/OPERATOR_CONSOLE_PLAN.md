# 傻瓜式无人化控制台规划

更新时间：2026-07-25

## 目标

做一个本机网页控制台，让用户在一个界面里完成：

1. 选择目标项目；
2. 启动或检查 Codex 工作区；
3. 启动或检查隔离 Claude Code；
4. 向 Claude 派发阶段任务；
5. 低 token 监控 Claude 执行状态；
6. Codex 提取 diff、测试、审查、返工或推送；
7. 自动更新 README、路线图、交接文件和无人化状态。

控制台不是让 Claude 获得 GitHub Token，也不是让 Codex 读取 Claude/Kiro API Key。它只是把已有职责分离流程固化为可点击、可恢复、可审计的本地编排器。

## 核心约束

- Claude 只在隔离 WSL 项目副本内读写授权文件。
- Codex 负责真实测试、审查、Git commit/push。
- API Key 不落盘；Claude 或 WSL 重启后仍由用户在本机启动器隐藏输入一次。
- 不通过窗口猜测和长文本粘贴作为主通道。
- GUI 交互只作为最后兜底；主通道必须是文件信箱 + 非交互 runner。
- 每轮最多 3 次 Claude 返工；连续失败后 Codex 接管诊断，避免无限 token 消耗。

## Token 消耗控制

### 不消耗模型 token 的监控

以下状态全部由本机程序读取，不向 Claude 或 Codex 提问：

- runner 是否 ready：检查 `CLAUDE_AUTOMATION_READY.txt`；
- Claude 是否完成：检查 `CLAUDE_TO_CODEX.md` 的存在、mtime、大小和状态 JSON；
- 是否有代码改动：运行 `git status --short`；
- 修改范围：运行 `git diff --name-only` 和 `git diff --stat`；
- 测试结果：由 Codex/本机 shell 运行测试命令；
- 凭据风险：本机 `rg` 扫描；
- 远端是否同步：`git ls-remote`。

这些操作只消耗本机 CPU/IO，不消耗 Claude token，也不消耗 Codex 推理 token，除非把大段输出拿回对话让 Codex分析。

### 消耗 token 的动作

只允许这些动作调用模型：

- Codex 生成阶段任务书；
- Claude 执行一次阶段任务；
- Claude 按精确返工单修复；
- Codex 审查关键 diff 或失败日志；
- Codex 生成下一阶段任务书。

禁止模式：

- 每 10 秒问 Claude “你完成了吗”；
- 把完整日志反复发给 Codex；
- 让 Claude 自己跑长时间诊断并连续解释；
- 把整仓文件反复塞进 prompt。

### 输出限额

Claude 每轮必须写结构化小报告：

```json
{
  "task_id": "...",
  "status": "done|blocked|needs_rework",
  "changed_files": [],
  "implemented": [],
  "not_implemented": [],
  "suggested_tests": [],
  "risks": []
}
```

限制：

- `changed_files` 最多 30 项；
- 每个数组项最多 200 字；
- 不粘贴完整 diff；
- 不粘贴测试全文；
- 失败时只写复现命令、错误摘要和定位文件。

## 推荐架构

```text
Browser UI
  |
  | HTTP localhost
  v
Control Server (Windows, Python stdlib)
  |
  |-- Project Registry
  |-- WSL Runner Manager
  |-- Claude Mailbox Manager
  |-- Diff/Test/Git Gate
  |-- Status Store
  |
  +-- Windows repo: E:\tmp\cailiao-remote
  +-- WSL sandbox: /home/kiro/kiro-work/work/cailiao-task
  +-- mailbox: /home/kiro/kiro-work/work/CODEX_TO_CLAUDE.md
  +-- report: /home/kiro/kiro-work/work/CLAUDE_TO_CODEX.md
```

前端不直接保存密钥，不直接调用 GitHub，不直接读写浏览器数据。所有危险操作由后端按白名单命令执行。

## 控制台页面

### 1. 项目页

显示：

- 项目名；
- GitHub URL；
- Windows 发布仓库路径；
- WSL 隔离工作区路径；
- 当前 main commit；
- 当前阶段；
- 最近一次 Codex 验证结果；
- 最近一次 Claude 交付报告。

按钮：

- `刷新状态`
- `同步 GitHub main`
- `准备隔离副本`
- `生成阶段任务`
- `派发给 Claude`
- `运行 Codex 门禁`
- `提交并推送`

每个按钮都显示将执行的白名单命令和影响范围。

### 2. Claude 状态页

显示：

- Claude runner：未启动 / 等待 Key / ready / running / done / error；
- ready 文件时间；
- 当前任务 ID；
- 当前任务文件 hash；
- 报告文件 hash；
- 上次心跳时间；
- 是否需要用户输入 Key。

按钮：

- `启动 runner`
- `重启 runner`
- `打开任务文件`
- `打开交付报告`

安全规则：

- 控制台不读取 API Key；
- 控制台不显示环境变量；
- 控制台不读取 Claude 进程内存或日志里的凭据。

### 3. 门禁页

显示固定步骤：

1. diff 范围；
2. 语法检查；
3. 单元测试；
4. API 测试；
5. UI 测试；
6. 凭据扫描；
7. README/ROADMAP/交接文件同步检查；
8. commit/push 准备。

每个步骤有：

- 状态：pending/running/pass/fail/skipped；
- 命令；
- 摘要；
- 完整日志文件路径。

前端只显示摘要，完整日志落盘，避免把大日志带入 Codex 上下文。

### 4. 返工页

失败后自动生成返工单：

```text
任务ID：
失败门禁：
复现命令：
预期：
实际：
允许修改：
禁止修改：
必须补测试：
交付报告路径：
```

返工最多 3 轮。第 3 轮仍失败时，状态变为 `codex_takeover_required`。

## 状态机

```text
idle
  -> preparing_workspace
  -> task_ready
  -> claude_running
  -> claude_done
  -> codex_extracting_diff
  -> codex_testing
  -> codex_reviewing
  -> rework_needed -> task_ready
  -> ready_to_push
  -> pushed
  -> next_stage_ready
```

错误状态：

- `needs_user_key`：Claude runner 未认证，需要用户在本机窗口隐藏输入一次；
- `wrong_window_detected`：只在 GUI 兜底模式出现；
- `scope_violation`：Claude 修改了禁止文件或访问越界；
- `test_failed`：Codex 门禁失败；
- `push_blocked`：远端或权限问题；
- `codex_takeover_required`：连续 3 次返工失败。

## 窗口交互策略

默认不使用窗口粘贴。

优先级：

1. 文件信箱 runner：`CODEX_TO_CLAUDE.md` -> `claude --print` -> `CLAUDE_TO_CODEX.md`；
2. 已认证非交互 `claude --print`，限定工作目录和工具；
3. GUI 兜底：只发送“一行读取任务文件”的短命令。

GUI 兜底必须满足：

- 枚举窗口标题，精确匹配 `Claude Code`；
- 验证真实窗口矩形大于最小阈值；
- 激活后读取前台句柄；
- 截屏确认当前标签确为 Claude Code；
- 只粘贴短命令，不粘贴长任务；
- 发送后用报告文件和 git status 判断是否成功。

## MVP 实施切片

### P0：控制台骨架

- `control/server.py`：Python 标准库 HTTP 服务；
- `control/projects.json`：项目注册表；
- `control/state.json`：运行状态；
- `control/logs/`：门禁日志；
- `frontend`：单页 HTML/CSS/JS。

只做状态显示和手动按钮，不做自动循环。

### P1：一键准备项目

- 拉取 GitHub main；
- 创建/刷新 WSL 隔离副本；
- 写入 `CODEX_TO_CLAUDE.md`；
- 检查 Claude runner ready。

### P2：一键派工与收工

- 调用 runner；
- 监听报告；
- 提取 diff；
- 运行测试；
- 生成 Codex review 摘要。

### P3：一键返工

- 失败后生成精确返工单；
- 控制返工次数；
- 记录每轮 hash、测试结果和失败原因。

### P4：一键发布

- 检查 README/ROADMAP/交接文件；
- commit；
- push；
- `ls-remote` 验证；
- 更新 `without_human` STATUS/stages。

## MVP 项目注册表示例

```json
{
  "projects": [
    {
      "id": "cailiao",
      "name": "材料写作硬审系统",
      "github": "https://github.com/wuyutanhongyuxin-cell/cailiao",
      "windows_repo": "E:\\tmp\\cailiao-remote",
      "wsl_repo": "/home/kiro/kiro-work/work/cailiao-task",
      "branch": "main",
      "test_commands": [
        "python -m py_compile backend/server.py tests/test_library.py",
        "python -m unittest discover -s tests -v",
        "git diff --check"
      ],
      "required_docs": [
        "README.md",
        "docs/ROADMAP.md",
        "CODEX_HANDOFF.json"
      ]
    }
  ]
}
```

## 安全白名单

控制台后端只允许固定命令模板：

- `git fetch origin`
- `git status --short`
- `git diff --stat`
- `git diff --name-only`
- `git diff --check`
- `git ls-remote origin refs/heads/main`
- `python -m py_compile ...`
- `python -m unittest discover -s tests -v`
- `rg` 凭据扫描
- `wsl -d KiroUbuntu -- test/ls/cp/git status`

禁止：

- 任意 shell 文本输入；
- 读取 `.env`、SSH、浏览器、用户目录；
- `git reset --hard` 旧工作区；
- Claude push；
- 将 API Key 写入任何文件；
- 自动扩大 Claude trust。

## 结论

这个前端应当是“本地无人化控制台”，不是聊天窗口自动点击器。低 token、稳定、安全的关键是：

- 用文件状态监控，不用模型问答监控；
- 用短任务 ID 和结构化报告，不传大日志；
- 用白名单命令做门禁；
- Claude 只改隔离副本；
- Codex 只在门禁通过后发布；
- GUI 只作为兜底，并且只发送短命令。
