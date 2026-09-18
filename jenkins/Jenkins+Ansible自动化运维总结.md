# Jenkins + Ansible 自动化运维总结

> 实验环境：Rocky Linux 9

## 一、环境准备篇

### （一）安装 Java 环境

Jenkins 是一个 Java Web 应用，其核心是一个 Servlet 容器（Jetty），因此运行 Jenkins 需要 Java 运行时环境（JRE）。openjdk 是开源的 Java 实现，-devel 包包含编译工具，-headless 包适合无图形界面的服务器环境。

**操作命令：**

```bash
yum install java-17-openjdk -y
```

**易错点：**

Java 版本不兼容：不同版本的 Jenkins 对 Java 版本有明确要求。新版 Jenkins 要求 Java 21，若安装 Java 17 会导致启动失败，报错信息：which is older than the minimum required version。解决方案：查看 Jenkins 官方文档确认版本要求，或根据报错信息升级 Java。

### （二）下载 Jenkins

Jenkins 提供了两种安装方式：WAR 包（通用）和操作系统原生包（如 RPM）。WAR 包方式最灵活，适用于任何支持 Java 的环境。Jenkins 的稳定版（Stable）更新周期较长，可靠性更高，适合生产环境。

**操作命令：**

```bash
cd /opt
mkdir jenkins && cd jenkins
wget https://get.jenkins.io/war-stable/latest/jenkins.war
```

**易错点：**

下载不完整：网络不稳定时可能导致 WAR 包下载中断，文件大小偏小（正常约 70-80MB）。解决方案：用 ls -lh 查看文件大小，异常时重新下载。

## 二、Jenkins 启动与排障篇

### （一）启动 Jenkins

**操作命令：**

```bash
# 前台启动（用于调试）
java -jar jenkins.war --httpPort=8080

# 后台启动（用于生产）
nohup java -Dfile.encoding=UTF-8 -jar jenkins.war --httpPort=9090 > jenkins.log 2>&1 &
```

**原理讲解：**

nohup：使进程忽略 HUP（挂断）信号，即使用户退出终端，进程仍继续运行。2>&1：将标准错误（stderr）重定向到标准输出（stdout），确保所有日志都在一个流中。&：将进程放入后台运行。--httpPort：指定 Jenkins Web 界面监听的端口，默认是 8080。

**易错点：**

| 序号  | 常见错误                                   | 原因分析                     | 解决方案                  |
| --- | -------------------------------------- | ------------------------ | --------------------- |
| 1   | Error: Unable to access jarfile        | 当前目录不存在 jenkins.war 文件   | 切换到正确的目录或指定完整路径       |
| 2   | 进程启动后立即退出                              | Java 版本不兼容或端口被占用         | 检查 jenkins.log 定位具体原因 |
| 3   | java.lang.UnsupportedClassVersionError | Jenkins 编译版本高于当前 Java 版本 | 升级 Java 版本            |
| 4   | Address already in use: bind           | 端口被其他进程占用                | 更换端口或杀掉占用进程           |

### （二）端口冲突排障（实战案例）

**问题现象：**

```bash
[root@192 jenkins]# netstat -tulnp | grep 8080
tcp 0 0 0.0.0.0:8080 0.0.0.0:* LISTEN 965/nginx: master p
```

Jenkins 无法启动，端口 8080 已被 Nginx 占用。

**排障流程：**

1. 用 netstat -tulnp | grep 8080 查看端口占用情况
2. 发现是 Nginx（PID 965）占用了 8080
3. 解决方案：让 Jenkins 换到 9090 端口，而非杀掉 Nginx（因为它是 Zabbix 的前端服务）

**原理讲解：**

Linux 中一个端口同时只能被一个进程绑定。多个 Web 服务共存时，需要合理规划端口分配。Nginx 通常用于反向代理和静态资源服务，Jenkins 是独立的 Web 应用，两者可以共存。

**学到了什么：**

端口规划是运维的基础工作；不能简单用 kill 解决问题，要考虑服务之间的依赖关系；netstat 是排查端口问题的基础命令。

### （三）查看日志定位问题

**操作命令：**

```bash
tail -50 /opt/jenkins/jenkins.log
```

**原理讲解：**

日志是运维排查问题的第一手信息。tail -50 查看文件末尾 50 行，因为最新的错误信息通常出现在日志末尾。-f 参数可以实时跟踪日志更新。

**易错点：**

日志信息量大，容易忽略关键信息。关注 ERROR、Caused by、Exception 等关键词。日志定位问题，解决方案从日志中找线索。

## 三、Jenkins 初始化配置篇

### （一）访问 Jenkins Web 界面

访问地址：http://你的LinuxIP:9090

**获取初始密码：**

```bash
cat /root/.jenkins/secrets/initialAdminPassword
```

**原理讲解：**

Jenkins 启动后会在 JENKINS_HOME 目录（默认为 ~/.jenkins）生成一个随机密码，用于管理员首次登录验证，确保安全性。密码在首次登录后可修改。

**易错点：**

找不到密码文件：Jenkins 的 JENKINS_HOME 默认是执行用户的 .jenkins 目录，用 root 执行则密码在 /root/.jenkins。解决方案：find / -name initialAdminPassword 2>/dev/null 全局搜索。

### （二）插件选择

推荐只安装 4 个核心插件：

- Pipeline：流水线核心引擎
- Pipeline Graph View：流水线可视化流程图
- Git：拉取代码
- Localization: Chinese (Simplified)：中文语言包

**原理讲解：**

Jenkins 插件是其功能扩展的基础。安装过多插件会拖慢 Jenkins 启动速度、增加插件冲突风险、占用更多系统资源。

**易错点：**

点击"安装推荐的插件"会安装 100+ 个插件，其中大部分用不到。按需安装，只装必要的核心插件。

## 四、Pipeline 脚本编写篇

### （一）第一个 Pipeline 脚本

**Pipeline 脚本示例：**

```groovy
pipeline {
    agent any

    stages {
        stage('环境检查') {
            steps {
                sh 'echo "===== 开始自动化部署 ====="'
                sh 'date'
                sh 'hostname'
            }
        }

        stage('执行 Ansible 部署 Nginx') {
            steps {
                sh '''
                    echo "===== 执行 Ansible Playbook ====="
                    ansible-playbook -i /root/inventory.ini /root/nginx.yml
                '''
            }
        }

        stage('部署完成验证') {
            steps {
                sh '''
                    echo "===== 验证 Nginx 是否已安装 ====="
                    ansible all -i /root/inventory.ini -m command -a "nginx -v"
                '''
            }
        }
    }

    post {
        always {
            sh 'echo "===== 部署流程结束 ====="'
        }
    }
}
```

**原理讲解：**

声明式 Pipeline：使用 pipeline 关键字，结构清晰，可读性强。agent any：在任意可用的 Jenkins 节点上执行。stages：流水线的阶段划分，每个 stage 代表一个逻辑步骤。steps：具体的执行步骤，sh 表示执行 Shell 命令。post：构建后的操作，always 表示无论成功失败都执行。

**设计思想：**

分层设计：环境检查 → 部署 → 验证，各阶段职责清晰。可视化：每个 stage 在 Jenkins 界面上单独显示，便于定位失败节点。自验证：部署后自动检查服务状态，确保部署成功。

**易错点：**

sh 命令中的脚本未加引号，或引号嵌套错误 -> 多行命令用 ''' 包裹。忘记写 stage 或括号不匹配 -> 在 Jenkins 的流水线语法工具中先验证语法。

### （二）与 Ansible 集成时的常见问题

**问题 1：ansible-playbook: command not found**

Jenkins 默认继承系统的 PATH 环境变量，但有时会丢失。解决方案：

方式一：在 Pipeline 中使用绝对路径

```bash
sh '/usr/bin/ansible-playbook -i /root/inventory.ini /root/nginx.yml'
```

方式二：在 Jenkins 系统配置中添加 PATH 环境变量

**问题 2：Ansible 连接目标主机失败**

确保 SSH 免密配置正确：

```bash
ssh-keygen -t rsa
ssh-copy-id root@目标主机IP
```

**原理讲解：**

Ansible 通过 SSH 连接目标主机执行命令，因此控制端需要能够免密登录目标主机。ssh-keygen 生成密钥对，ssh-copy-id 将公钥复制到目标主机的 ~/.ssh/authorized_keys 中。

## 五、GitHub/Gitee Webhook 自动触发篇

### （一）配置 Gitee 私人令牌

在 Gitee 生成令牌：https://gitee.com/profile/personal_access_tokens

勾选权限：projects 和 hooks

在 Jenkins 配置：系统管理 → 系统 → Gitee 配置

**原理讲解：**

开启 2FA 后，Git 操作无法使用密码验证，需要用私人令牌（Personal Access Token）替代。令牌类似于 API 密钥，可以在不暴露密码的情况下授权第三方工具访问 GitHub/Gitee 资源。

**易错点：**

令牌生成后忘记复制（关闭页面后无法再次查看）→ 立即复制保存到安全位置。权限勾选不全，导致 API 调用失败 → 至少勾选 repo 和 admin:repo_hook。

### （二）Webhook 配置流程

1. Jenkins 任务配置：勾选 Gitee webhook 触发构建
2. Gitee 仓库配置：管理 → WebHooks → 添加 WebHook
3. URL 格式：http://你的IP:9090/gitee-webhook/?job=任务名
4. 触发时机：勾选 Push

**原理讲解：**

Webhook 是一种"回调"机制：用户在 Gitee 上执行 Push 操作 → Gitee 向配置的 URL 发送 HTTP POST 请求（携带推送信息）→ Jenkins 收到请求后，根据 job 参数触发对应的流水线构建。实现"代码提交 → 自动构建 → 自动部署"的 CI/CD 全链路。

### （三）Webhook 排障

| 错误现象             | 可能原因            | 排查方法                         |
| ---------------- | --------------- | ---------------------------- |
| URL is invalid   | Gitee 无法访问内网 IP | Gitee 服务器在内网无法访问 192.168.x.x |
| 触发后 Jenkins 无响应  | Jenkins 端口未放行   | firewall-cmd --list-ports 检查 |
| Webhook 记录显示 500 | Jenkins 内部错误    | 查看 Jenkins 系统日志              |

## 六、完整学习成果总结

### （一）掌握的核心技能

| 技能领域         | 掌握程度 | 具体操作                  |
| ------------ | ---- | --------------------- |
| Jenkins 部署   | 独立完成 | Java 版本选择、端口规划、后台启动   |
| 声明式 Pipeline | 独立编写 | 3 阶段流水线：检查 → 部署 → 验证  |
| Ansible 集成   | 独立完成 | Pipeline 中调用 Playbook |
| Webhook 原理   | 掌握理论 | 内网环境下的限制与解决方案         |
| 排障能力         | 实战验证 | 端口冲突、Java 版本、日志定位     |

### （二）遇到并解决的关键问题

1. Java 版本不兼容：从 Java 17 升级到 Java 21
2. 端口被占用：Nginx 占用 8080，改用 9090
3. 密码文件路径：从 /opt/jenkins 找到 /root/.jenkins
4. Webhook URL 格式：gitee-project 改为 gitee-webhook/?job=任务名
5. 内网访问限制：理解 Webhook 在内网环境的限制与解决方案
