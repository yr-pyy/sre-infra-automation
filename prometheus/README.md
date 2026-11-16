# 基于 Prometheus + Grafana 的主机监控体系建设

本项目旨在 Rocky Linux 环境下，从零搭建一套云原生主流的“采集-存储-可视化”全链路主机监控系统。项目不仅实现了基础指标的实时监控，还配置了基于阈值的告警规则，并解决了实际部署中遇到的端口冲突等工程问题。

## 📂 项目目录结构
```text
prometheus/
├── README.md               # 项目说明文档
├── prometheus.yml          # Prometheus 核心配置文件（包含抓取目标与标签）
├── alert_rules.yml         # 告警规则文件（CPU 使用率阈值触发）
└── dashboard.png           # Grafana 可视化大屏截图
🏗️ 架构说明
Node Exporter：部署于被监控端，负责采集 CPU、内存、磁盘、网络等底层系统指标，暴露 9100 端口的 /metrics 接口。

Prometheus Server：采用 Pull（拉取）模式，定期从 Node Exporter 抓取指标，并持久化至本地 TSDB 时序数据库。

Grafana：可视化展示层，对接 Prometheus 数据源，通过 PromQL 查询数据并渲染仪表盘。

Alertmanager (预留)：结合 alert_rules.yml 实现异常状态下的告警推送（如触发 CPU 告警）。

💻 环境说明
操作系统：Rocky Linux 9.8 (x86_64)

组件版本：Node Exporter (v1.10.2) / Prometheus (v2.45.0) / Grafana (Latest)

🚀 核心排障记录与工程实践
在实际部署过程中，秉承“不影响现有业务”的原则，解决了以下关键问题：

现象：启动 prometheus.service 失败，状态为 status=1/FAILURE。

排查：使用 journalctl -u prometheus -n 20 --no-pager 查日志，发现报错 listen tcp 0.0.0.0:9090: bind: address already in use。

定位：执行 ss -tulnp | grep 9090 发现端口被占用；ps -ef | grep <PID> 查明是服务器原有的 Jenkins 服务占用了 9090 端口。

解决：为保证现有业务不中断，未强杀 Jenkins。通过修改 Prometheus 的 systemd 启动参数，将监听端口平滑迁移至 0.0.0.0:9091。同时修改了 prometheus.yml 里的抓取目标（Target）地址。

后续问题处理：修改后 systemd 依然报错 Start request repeated too quickly，通过执行 systemctl reset-failed prometheus 清空失败计数后，服务成功启动。

告警规则补充：初次配置 rule_files 时因未创建文件导致校验失败。后补充编写 alert_rules.yml，利用 promtool check config 校验通过后，成功实现了 CPU 使用率 > 80% 持续 5 分钟即触发的告警策略。

🖼️ 成果展示
通过部署 Grafana 并导入社区面板 (ID: 11074)，实现了主机底层资源的多维度可视化监控：

https://./dashboard.png

🎓 技术沉淀
运维排障方法论：按图索骥，逐层收敛。看日志 -> 查端口 -> 定归属 -> 清状态。

PromQL 实战：掌握 Counter 类型指标的处理（如 rate() 函数计算 CPU 使用率）。

配置分离设计：将监控目标配置（prometheus.yml）与告警逻辑（alert_rules.yml）解耦，方便后期维护与迭代。
