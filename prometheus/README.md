# 基于 Prometheus + Grafana 的主机监控体系建设

本项目旨在 Rocky Linux 环境下，从零搭建一套云原生主流的“采集-存储-可视化”全链路主机监控系统。项目解决了实际部署中遇到的环境依赖、下载超时及端口冲突等问题。

## 🏗️ 架构说明
* **Node Exporter**：部署于被监控端，负责采集 CPU、内存、磁盘、网络等底层系统指标，暴露 `9100` 端口的 `/metrics` 接口。
* **Prometheus Server**：采用 Pull（拉取）模式，定期从 Node Exporter 抓取指标，并持久化至本地 TSDB 时序数据库。
* **Grafana**：可视化展示层，对接 Prometheus 数据源，通过 PromQL 查询数据并渲染仪表盘。

## 💻 环境说明
* **操作系统**：Rocky Linux 9.8 (x86_64)
* **组件版本**：Node Exporter (v1.10.2) / Prometheus (v2.45.0) / Grafana (Latest)

## 🚀 核心排障记录
* **现象**：启动 `prometheus.service` 失败，状态为 `status=1/FAILURE`。
* **排查**：使用 `journalctl -u prometheus -n 20 --no-pager` 查日志，发现报错 `listen tcp 0.0.0.0:9090: bind: address already in use`。
* **定位**：执行 `ss -tulnp | grep 9090` 发现端口被占用；`ps -ef | grep <PID>` 查明是服务器原有的 **Jenkins 服务占用了 9090 端口**。
* **解决**：为保证现有业务不中断，未杀 Jenkins。通过修改 Prometheus 的 systemd 启动参数，将监听端口平滑迁移至 `0.0.0.0:9091`。同时修改了 `prometheus.yml` 里的抓取目标（Target）地址。
* **后续问题处理**：修改后 systemd 依然报错 `Start request repeated too quickly`，通过执行 `systemctl reset-failed prometheus` 清空失败计数后，服务成功启动。
