# Without Human

<p align="center"><strong>Claude实施，Codex审查，硬门禁决定是否进入GitHub。</strong></p>
<p align="center">隔离执行 · 最小权限 · 独立验证 · 阶段推进 · Benchmark交付</p>

> 本仓库是“材料写作硬审系统”的无人化开发编排方案。目标是在不向共享Claude账号开放宿主机、GitHub凭据或敏感文件的前提下，持续完成开发、审查、测试、推送和路线图更新。

## 核心目标

```text
Codex生成阶段任务书
        ↓
Claude在隔离WSL中只修改代码
        ↓
Codex提取差异并独立审查
        ↓
静态检查 → 单元测试 → 集成测试 → UI测试 → 安全检查
        ↓
失败：生成精确返工单 → Claude修复
通过：Codex提交并push → 更新进度 → 下一阶段
        ↓
完整Benchmark → 发布候选 → 最终交付
```

模型不能自行宣布任务完成。是否进入下一阶段由可复现的测试、质量门禁和Codex审查决定。

## 为什么不是让Claude直接push

Claude使用共享API账号，并运行在隔离WSL中。给它GitHub Token、宿主机访问或任意Bash权限，会破坏已经建立的安全边界。本方案采用职责分离：

| 角色 | 负责 | 禁止 |
|---|---|---|
| Claude | 阅读任务书，创建和修改项目文件，补充测试代码 | Bash、push、GitHub Token、宿主盘、旧工作区、`.env` |
| Codex | 架构决策、提取差异、测试、审查、修复、提交、push、benchmark | 未验证即合并、向Claude暴露凭据 |
| 自动门禁 | 测试、格式、安全、许可证、数据泄漏和评测阈值 | 用主观印象替代硬指标 |
| 用户 | 初次或重启后隐藏输入Claude API Key、最终业务验收 | 日常阶段推进无需参与 |

## 无人化边界

在Claude进程和WSL持续运行期间，阶段循环可以无人工推进。由于API Key坚持“不保存”，Claude或WSL重启后需要用户重新隐藏输入一次Key。Codex不得从运行进程、日志或环境中提取凭据。

因此本项目追求的是：

- 开发流程无人值守；
- 凭据仍由人掌控；
- 最终业务签收仍由人负责；
- 不以降低安全性换取表面上的绝对无人化。

## 项目范围

目标项目：[wuyutanhongyuxin-cell/cailiao](https://github.com/wuyutanhongyuxin-cell/cailiao)

执行阶段：

1. 自动化执行环境；
2. 可信证据库；
3. 混合检索与引用验证；
4. 写作状态机；
5. 文种与硬审规则扩展；
6. 正式DOCX排版；
7. 安全与部署；
8. 完整Benchmark和正式交付。

完整定义见[实施计划](docs/IMPLEMENTATION_PLAN.md)。

## 仓库结构

```text
without_human/
├─ README.md
├─ STATUS.md                         # 当前进度和阻塞
├─ control/
│  ├─ projects.json                   # 本机项目注册表
│  └─ server.py                       # 本机控制台后端
├─ docs/
│  ├─ IMPLEMENTATION_PLAN.md         # 完整阶段规划
│  ├─ SECURITY_BOUNDARY.md           # 权限和凭据边界
│  ├─ QUALITY_GATES.md               # 合并与发布门禁
│  ├─ OPERATOR_CONSOLE_PLAN.md       # 本机傻瓜式控制台规划
│  └─ AUTONOMY_LESSONS.md            # 无人化编排经验和反模式
├─ frontend/
│  ├─ index.html                      # 本机控制台页面
│  ├─ styles.css
│  └─ app.js
├─ orchestration/
│  └─ stages.json                    # 机器可读阶段状态
└─ templates/
   ├─ CLAUDE_TASK.md                 # Claude阶段任务书模板
   └─ CODEX_REVIEW.md                # Codex审查报告模板
```

## 本机控制台

控制台已作为 P0 骨架落在本仓库，默认绑定 `127.0.0.1`，不保存 API Key，不读取 `.env`，只通过白名单命令查看状态、写入 WSL 任务文件和运行 Codex 门禁。

```powershell
python control/server.py
```

浏览器打开：

```text
http://127.0.0.1:8787
```

如果 `8787` 已被其他本地服务占用，控制台会自动改用下一个端口；也可以显式指定：

```powershell
$env:WITHOUT_HUMAN_PORT=8788
python control/server.py
```

默认项目配置在 `control/projects.json`，当前指向 `cailiao` 的 Windows 发布仓库 `E:\tmp\cailiao-remote` 与隔离 WSL 副本 `/home/kiro/kiro-work/work/cailiao-task`。运行产生的 `control/state.json` 和 `control/logs/*.json` 是本机状态，不纳入 Git。

Windows 一键启动入口：

```text
scripts\Start Without Human Console.cmd
```

这个脚本会先寻找已经运行的 Without Human 控制台；找到了就直接打开浏览器，没找到就从 `8787` 开始选择空闲端口启动后端，再打开浏览器。桌面快捷方式可以直接指向这个 `.cmd` 文件。

## CLI 桥接脚本

本仓库保留“两 CLI session”模式：Codex CLI 负责编排/审查/推送，Claude Code CLI 负责隔离实现。脚本只固定易错的桥接动作：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\check-claude-channel.ps1
powershell -ExecutionPolicy Bypass -File scripts\send-claude-handshake.ps1 -UseUiA
powershell -ExecutionPolicy Bypass -File scripts\send-claude-task.ps1 -TaskPath .\task.md -UseUiA
```

说明见 `docs/CLAUDE_CHANNEL_SCRIPTS.md`。

低风险任务可由 DeepSeek 作为 Codex 侧 helper 处理，凭据只从仓库外环境变量读取，不进入 Git。说明见 `docs/DEEPSEEK_DELEGATION.md`。

首次配置 DeepSeek key：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\set-deepseek-key.ps1
```

## Git策略

每个阶段使用独立分支：

```text
agent/execution-environment
agent/evidence-store
agent/hybrid-retrieval
agent/drafting-state-machine
agent/document-rules
agent/docx-layout
agent/security-deployment
agent/benchmark-release
```

只有以下条件全部满足时，Codex才能推送或合并：

- 修改范围符合阶段任务书；
- 不包含凭据、运行数据或无许可证资产；
- 原有测试与新增测试全部通过；
- 用户界面经过真实浏览器验证；
- README、架构、路线图和状态文件同步更新；
- 阶段审查报告不存在致命或高风险问题。

## 完成定义

项目只有同时满足以下条件才能标记完成：

- 路线图承诺项均已实现或明确移出范围；
- 自动测试和安全门禁通过；
- 完整benchmark达到发布阈值；
- 没有未处理的致命或高风险问题；
- 可从干净环境复现安装、启动、测试和导出；
- 创建正式版本标签与最终交付报告。

## 当前状态

当前状态以[STATUS.md](STATUS.md)为准；目前 `阶段2：混合检索与引用验证` 正在推进并已启动 `阶段3：写作状态机与定点修复`，已完成阶段 2B 的检索评测基座、匿名占位评测集、逐 case miss 诊断、中文 BM25/FTS 调优 v1、评测可解释性、评测 CLI 门禁、BM25 参数扫描框架、统一质量门禁脚本与 GitHub Actions、主张到证据精确映射 v1、可审计检索/核验面板 v1、元数据过滤 UI/评测覆盖 v1、评测集结构校验工具 v1、确定性冲突证据候选 v1、向量检索与可替换 embedding 管线骨架 v1、可插拔重排管线骨架 v1、证据不足/拒绝理由 v1、前端不足审计面板 v1，以及阶段 3 写作状态机 v1；已验证 Codex ↔ 隔离 Claude Code 的派工、返工、接管补齐、提取、测试、浏览器冒烟、推送和 GitHub CI 闭环；`KiroUbuntu` / Claude Code 通道已通过提权宿主视角恢复，普通沙箱视角仍可能看不到 WSL 发行版。

## 许可证

仓库暂未附加开源许可证，默认保留全部权利。
