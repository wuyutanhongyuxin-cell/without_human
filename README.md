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
├─ docs/
│  ├─ IMPLEMENTATION_PLAN.md         # 完整阶段规划
│  ├─ SECURITY_BOUNDARY.md           # 权限和凭据边界
│  ├─ QUALITY_GATES.md               # 合并与发布门禁
│  └─ AUTONOMY_LESSONS.md            # 无人化编排经验和反模式
├─ orchestration/
│  └─ stages.json                    # 机器可读阶段状态
└─ templates/
   ├─ CLAUDE_TASK.md                 # Claude阶段任务书模板
   └─ CODEX_REVIEW.md                # Codex审查报告模板
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

当前处于`阶段0：自动化执行环境`。详情见[STATUS.md](STATUS.md)。

## 许可证

仓库暂未附加开源许可证，默认保留全部权利。
