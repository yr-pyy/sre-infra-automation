# 基于 Prometheus + Grafana 的主机监控体系建设

本项目旨在 Rocky Linux 环境下，从零搭建一套云原生主流的“采集-存储-可视化”全链路主机监控系统。项目不仅实现了基础指标的实时监控，还配置了基于阈值的告警规则，并解决了实际部署中遇到的端口冲突等工程问题。

## 📂 项目目录结构
```text
prometheus/
├── README.md               # 项目说明文档
├── prometheus.yml          # Prometheus 核心配置文件（包含抓取目标与标签）
├── alert_rules.yml         # 告警规则文件（CPU 使用率阈值触发）
└── dashboard.png           # Grafana 可视化大屏截图
