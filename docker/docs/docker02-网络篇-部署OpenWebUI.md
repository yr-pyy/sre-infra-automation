# 二、Docker网络篇：部署Open WebUI容器

## （一）创建自定义网络

### 部署步骤

第一步：创建自定义桥接网络

```bash
sudo docker network create ollama-net
```

第二步：查看网络详情

```bash
sudo docker network inspect ollama-net
```

第三步：将已运行的ollama容器连接到该网络

```bash
sudo docker network connect ollama-net ollama
```

### 原理讲解

1. **docker network create ollama-net**：创建一个自定义桥接网络。Docker支持多种网络模式：bridge（默认桥接）、host（共享宿主机网络）、none（无网络）、overlay（跨主机通信，用于Swarm集群）、macvlan（为容器分配MAC地址，像物理设备一样接入物理网络）。
2. **docker network inspect ollama-net**：查看网络的详细配置信息，包括子网、网关、已连接的容器等。自定义网络会自动分配一个独立的IP段（如172.18.0.0/16），为每个连接的容器分配IP。
3. **docker network connect ollama-net ollama**：将已运行的ollama容器连接到ollama-net网络。连接后，open-webui容器可以通过http://ollama:11434访问Ollama服务，因为Docker内置的DNS服务器会自动将容器名ollama解析为ollama容器在ollama-net网络中的IP地址。

**自定义网络的核心优势**：容器间可通过容器名直接通信，Docker内置的DNS服务器（127.0.0.11）会自动将容器名解析为对应的IP地址。而默认bridge网络不支持容器名解析，只能通过IP通信。不同网络间的容器默认无法通信，这增强了安全性。

### 易错点

1. **容器间无法通过容器名通信**：确保两个容器都连接到同一个自定义网络。默认bridge网络不支持容器名DNS解析。
2. **网络IP段冲突**：如果自定义网络的子网与宿主机其他网络（如VPN、其他Docker网络）重叠，会导致路由混乱。使用docker network inspect查看子网，或使用--subnet指定不冲突的网段。
3. **连接后容器IP变化**：每次容器重启，Docker可能分配不同的IP地址。但容器名始终指向正确的IP，所以应始终使用容器名而非IP进行通信。
4. **跨主机容器通信**：自定义bridge网络仅在同一台宿主机上有效。如果需要跨主机通信，需要使用overlay网络（Docker Swarm模式）或第三方网络插件。
5. **删除网络时容器仍连接**：尝试删除被容器使用的网络会报错。需先执行docker network disconnect或将容器删除后再删除网络。

## （二）部署Open WebUI容器

### 部署步骤

第一步：拉取Open WebUI镜像

```bash
sudo docker pull ghcr.io/open-webui/open-webui:main
```

第二步：运行Open WebUI容器

```bash
sudo docker run -d \
  --name open-webui \
  --network ollama-net \
  -p 3000:8080 \
  -v open-webui-data:/app/backend/data \
  -e OLLAMA_BASE_URL=http://ollama:11434 \
  ghcr.io/open-webui/open-webui:main
```

第三步：开放防火墙端口

```bash
sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload
```

### 原理讲解

1. **docker pull ghcr.io/open-webui/open-webui:main**：从GitHub Container Registry（ghcr.io）拉取Open WebUI镜像。ghcr.io是GitHub Container Registry的域名，GitHub提供的容器镜像托管服务，类似于Docker Hub但专注于GitHub生态。:main是镜像标签，指定拉取main分支的最新版本。
2. **docker run -d --name open-webui --network ollama-net -p 3000:8080 -v open-webui-data:/app/backend/data -e OLLAMA_BASE_URL=http://ollama:11434 ghcr.io/open-webui/open-webui:main**：
   - --network ollama-net：将open-webui容器连接到ollama-net自定义网络，与Ollama容器处于同一网络中，实现容器间通信。
   - -p 3000:8080：宿主机3000端口映射到容器8080端口。Open WebUI应用内部监听8080端口，通过端口映射暴露给外部访问。
   - -v open-webui-data:/app/backend/data：数据卷挂载，将宿主机卷open-webui-data挂载到容器内/app/backend/data目录。卷挂载实现数据持久化的原理是：Docker Volume是宿主机上的一个目录（通常在/var/lib/docker/volumes/下），通过bind mount挂载到容器内。容器对挂载目录的读写操作实际上是在宿主机文件系统上进行的，因此即使容器被删除重建，数据仍然存在。
   - -e OLLAMA_BASE_URL=http://ollama:11434：环境变量注入。Docker在容器启动时，会将-e参数指定的环境变量写入容器内的环境配置中。应用程序启动时读取这些环境变量来配置自身行为。注意使用容器名ollama而非localhost——在容器内，localhost指向容器自身，而非宿主机。
   - 服务发现原理：Docker的自定义网络内置了DNS服务器（127.0.0.11）。当容器内发起DNS查询时，Docker DNS会检查该名称是否对当前网络中的某个容器名有效，如果有效则返回该容器的IP地址。这使得容器间可以通过语义化的名称而非硬编码IP进行通信。
3. **firewall-cmd --add-port=3000/tcp --permanent && firewall-cmd --reload**：CentOS默认开启firewalld防火墙，需要手动开放容器映射的端口。--permanent参数将规则保存到配置文件，--reload重载防火墙使规则生效。

**物理机访问问题**：在NAT模式下，物理机浏览器无法访问虚拟机的3000端口，因为NAT模式下虚拟机与物理机不在同一网段。解决方案：将虚拟机网络适配器改为桥接模式，重启后获得与物理机同网段的IP，物理机通过新IP:3000访问成功。

### 易错点

1. **OLLAMA_BASE_URL设置为localhost**：这是最常见的配置错误。在容器内，localhost指向容器自身，而非宿主机。必须使用容器名（http://ollama:11434）或宿主机的实际IP地址。
2. **ghcr.io拉取超时**：GitHub Container Registry在国内访问不稳定。可以使用国内镜像代理（如ghcr.nju.edu.cn）拉取后使用docker tag重新打标签。
3. **防火墙阻挡**：CentOS默认开启firewalld，需要手动开放容器映射的端口。
4. **环境变量大小写敏感**：OLLAMA_BASE_URL必须完全大写，拼写错误会导致配置不生效。
5. **端口冲突**：如果宿主机3000端口已被占用，容器启动会失败。使用netstat -tlnp | grep 3000检查端口占用。

## （三）验证部署结果与物理机访问

### 部署步骤

第一步：查看运行中的容器

```bash
sudo docker ps
```

第二步：浏览器访问
在物理机浏览器中输入 http://虚拟机IP:3000 访问Open WebUI

第三步：注册管理员账号并测试对话

### 原理讲解

1. **docker ps**：通过Docker API查询当前运行中的容器信息，确认ollama和open-webui两个容器均为Up状态。
2. **浏览器访问 http://虚拟机IP:3000**：Open WebUI作为Web应用，部署在容器中，通过HTTP协议提供服务（B/S架构：浏览器/服务器架构）。用户通过浏览器访问Web应用，无需安装额外客户端。
3. **Open WebUI自动检测Ollama服务**：Open WebUI启动后会读取OLLAMA_BASE_URL环境变量，向该地址发送API请求检测可用模型。如果Ollama服务正常响应，Open WebUI会显示模型列表供用户选择。

### 易错点

1. **浏览器无法访问**：确保防火墙已开放3000端口，且虚拟机网络模式正确（桥接模式下物理机与虚拟机同网段）。
2. **模型列表为空**：检查OLLAMA_BASE_URL环境变量是否正确设置，以及Ollama容器是否正常运行。
3. **NAT模式访问问题**：NAT模式下物理机无法直接访问虚拟机容器。需改为桥接模式或配置端口转发。
4. **忘记注册管理员**：首次访问Open WebUI必须注册管理员账号，之后才能使用。
5. **模型选择后无响应**：可能是模型文件下载不完整或磁盘空间不足。检查docker logs open-webui查看错误信息。

## （四）Open WebUI汉化与主题设置

### 部署步骤

第一步：登录Open WebUI
在浏览器中访问 http://虚拟机IP:3000，注册管理员账号并登录

第二步：设置语言
点击左下角用户头像 → Settings → General → Language → 选择"中文(简体)" → 保存

第三步：设置主题
Settings → General → Theme → 选择暗色主题（Dark）或亮色主题（Light）

### 原理讲解

1. **应用内语言设置原理**：Open WebUI在前端（JavaScript）层面管理界面文本，语言包作为静态资源文件存储在应用中。用户选择语言后，前端框架根据选择的语言加载对应的翻译文件，动态替换界面文本。
2. **环境变量方式的局限性**：尝试通过环境变量
