# 当前状态

更新时间：2026-07-19

## 总体进度

- 当前阶段：阶段0，自动化执行环境
- 状态：进行中
- 目标项目：https://github.com/wuyutanhongyuxin-cell/cailiao
- 执行策略：Claude只改代码，Codex负责验证、Git和发布

## 已确认

- [x] Claude运行在KiroUbuntu隔离WSL中
- [x] Windows盘未挂载
- [x] WSL interop已禁用
- [x] Claude不保存API Key
- [x] GitHub写操作由Codex承担
- [x] Benchmark资产库已建立在本机项目目录
- [x] 无人化总体路线已经定义

## 待完成

- [ ] 清理WSL中超时留下的不完整仓库副本
- [ ] 建立`/home/kiro/cailiao-work`独立工作区
- [ ] 修正Claude启动脚本UTF-8 BOM问题
- [ ] 限定Claude只能访问材料项目工作区
- [ ] 建立阶段任务书与交付报告交换机制
- [ ] 验证Codex可稳定提取Claude修改
- [ ] 验证失败返工和恢复流程

## 已知约束

- WSL无法直接使用Windows localhost代理，GitHub clone可能超时；项目副本应由Codex从Windows侧注入。
- Claude的Key不落盘，因此进程或WSL重启后需要用户重新隐藏输入一次。
- Claude禁止Bash后不能自行执行测试，所有真实测试由Codex完成。
