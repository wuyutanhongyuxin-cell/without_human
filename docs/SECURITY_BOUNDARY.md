# 安全边界

## Claude允许范围

- 当前阶段的项目工作副本；
- 阶段任务书；
- 项目内普通源代码和测试代码；
- 创建、编辑和删除本阶段明确授权的项目文件。

## Claude禁止范围

- Windows宿主盘和WSL互操作；
- `/home/kiro/kiro-work/work`旧工作区；
- `.env`、密钥、Token、证书、SSH、AWS和GPG目录；
- GitHub Token和任何push操作；
- Bash、PowerShell和绕过权限模式；
- 未经许可的浏览器账户、宿主浏览器和个人数据；
- Benchmark隐藏测试答案；
- 无许可证第三方代码、字体、图片和数据。

## Codex职责

- 不读取或提取Claude进程中的API Key；
- 不把凭据写入任务书、日志、Git或模型上下文；
- 只从已知项目工作区提取修改；
- 对删除、迁移和依赖更新进行独立审查；
- push前扫描凭据、运行数据和许可证风险；
- 所有外部发布行为保留可追溯提交。

## 无人化限制

API Key不落盘是高优先级安全要求。Claude进程或WSL重启后，必须由用户重新输入一次Key。禁止通过读取其他进程环境、终端记录或调试日志绕过该要求。

## WSL 网络代理边界

- 允许在用户明确要求时，通过官方 WSL 配置启用 `networkingMode=mirrored`、`autoProxy=true`、`dnsTunneling=true` 和 `firewall=true`，让隔离 WSL 继承 Windows 系统代理。
- 优先使用 WSL mirrored networking，不优先开启 v2rayN 的“允许来自局域网连接”。
- 如必须桥接 Windows 代理端口，只能绑定 WSL 虚拟网卡地址并限制 WSL 子网；不得为了省事把代理监听开放到 `0.0.0.0` 或整个局域网。
- 诊断代理时只能输出是否设置、长度、监听地址和连通性结果；不得输出 token、API key、代理认证信息或浏览器会话信息。
- 如果 WSL HTTPS 正常但 Claude Web Search 返回 `502 upstream`，应记录为上游搜索/网关故障候选，不得继续扩大本机权限来“硬钻”。
