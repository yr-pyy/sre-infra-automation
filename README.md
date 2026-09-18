## 💡 技术栈与实战亮点

- **容器化与编排**：熟练掌握 Docker 容器网络配置与数据卷管理；具备 K8s 集群资源调度实战经验，独立编写 Deployment、Service、ConfigMap 及 HPA 自动扩缩容等生产级 YAML 清单。
- **CI/CD 流水线**：实践 Jenkins 结合 Ansible 的自动化发布流程，理解从代码提交到服务部署的完整 DevOps 闭环。
- **自动化运维**：具备扎实的 Shell 编程能力，封装系统日常自动化巡检脚本（inspection.sh），提升服务器运维效率。
- **可观测性体系**：从零搭建 Zabbix 6.x 企业级监控平台，涵盖 LNMP 环境部署、Agent 配置及邮件告警策略落地。

# 🛠️ DevOps & SRE 自动化运维实战知识库

本仓库汇集了我在 **Ansible、Docker、Jenkins、Kubernetes (K8s)、Shell 脚本及 Zabbix 监控** 等领域的实战笔记、配置清单与自动化脚本。

所有内容均基于真实生产环境或实验环境记录，遵循**「文档讲解与配置代码分离」**的原则整理，旨在提供一套可复用、可追溯的运维知识体系。

## 📚 目录导航

### 1. Ansible 自动化配置

- **简介**：基于 Ansible 的批量服务器管理与 Nginx 部署实践。
- **结构**：
  - `inventory/`：主机清单文件。
  - `playbooks/`：包含 Nginx 部署、变量演示及 Jinja2 模板渲染示例。
  - `templates/`：存放 `site.conf.j2` 等动态配置文件模板。

### 2. Docker 容器化部署

- **简介**：Docker 环境搭建及 AI 应用（Ollama/OpenWebUI）的容器化落地。
- **核心内容**：
  - **基础篇**：Ollama 本地大模型部署。
  - **网络篇**：OpenWebUI 界面部署与网络配置。
  - **运维篇**：容器监控与数据备份策略。
  - **过渡篇**：从 Docker 向 Kubernetes 迁移的思考。
- **文件**：`config/daemon.json` (Docker 守护进程配置), `scripts/backup-openwebui.sh` (自动备份脚本)。

### 3. Jenkins CI/CD 流水线

- **简介**：Jenkins 结合 Ansible 实现持续集成与持续部署的总结。
- **文件**：`Jenkins+Ansible自动化运维总结.md` (详细记录了流水线构建逻辑与踩坑经验)。

### 4. Kubernetes (K8s) 集群管理

- **简介**：K8s 核心资源定义与高级特性应用。
- **结构**：
  - `docs/`：涵盖基础概念、核心资源配置（Deployment/Service/PVC等）及 HPA 自动扩缩容详解。
  - `manifests/`：生产级 YAML 清单，包括 Nginx 部署、ConfigMap 配置、持久化存储声明及服务暴露配置。

### 5. Shell 脚本编程

- **简介**：从基础语法到系统巡检的 Shell 编程进阶之路。
- **结构**：
  - `docs/`：分阶段教程（基础篇 -> 进阶篇 -> 实战篇），包含变量、循环、文本处理及函数封装。
  - `scripts/`：`inspection.sh` (系统日常自动化巡检脚本)。

### 6. Zabbix 监控系统

- **简介**：Zabbix 6.x 企业级监控平台的完整安装与配置手册。
- **特点**：包含完整的 LNMP 环境搭建、Agent 配置及邮件告警设置，**文档内嵌真实操作截图**。
- **结构**：
  - `doc/`：《zabbix安装及配置手册.md》（含数据库 SQL 语句与环境配置命令）。
  - `scripts/`：`zabbix_db.sql` (数据库初始化与授权脚本)。
  - `images/`：手册配套的操作界面截图。

## 💡 使用说明

1. **克隆仓库**

   ```bash
   git clone <你的仓库地址>
   cd <仓库名>
   ```

2. **阅读文档**
   建议先阅读各目录下的 Markdown 文档理解原理，再参考 `manifests`、`scripts` 或 `playbooks` 中的代码进行实操。

3. **关于 Zabbix 截图**
   Zabbix 手册中的图片存储在 `zabbix/images/` 目录下，请在支持图片预览的 Markdown 阅读器（如 VS Code、Typora 或 GitHub 网页版）中查看以获得最佳体验。

## ⚠️ 注意事项

- **安全性**：部分配置文件（如 `zabbix_db.sql`、`daemon.json`）中可能包含示例密码或内网 IP，**在生产环境使用前请务必替换为敏感信息**。
- **版本差异**：软件版本（如 Zabbix 6.x, K8s v1.2x+）可能会随时间更新，请根据实际环境调整命令参数。

---

> 📝 **维护者**：[你的名字/ID]
> 📅 **最后更新**：2026-09-18
