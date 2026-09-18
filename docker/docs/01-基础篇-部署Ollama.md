# 一、Docker基础篇：部署Ollama大模型运行环境

## （一）Docker安装与配置

### 部署步骤

第一步：安装依赖包

```bash
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```

第二步：添加Docker官方YUM软件源（使用阿里云镜像加速）

```bash
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

第三步：安装Docker CE及相关组件

```bash
sudo yum install -y docker-ce docker-ce-cli containerd.io
```

第四步：启动Docker服务并设置开机自启

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

第五步：验证安装

```bash
sudo docker run hello-world
```

### 原理讲解

1. **yum install 安装依赖包**：yum-utils包提供了yum-config-manager工具，用于方便地添加、删除和管理YUM软件源仓库。device-mapper是Linux内核提供的存储驱动框架，Docker依赖其进行镜像层管理和容器存储。lvm2是逻辑卷管理工具，为Docker存储驱动提供底层支持。
2. **yum-config-manager --add-repo**：该命令将Docker官方仓库的YUM配置文件添加到系统的软件源列表中。使用阿里云镜像源（mirrors.aliyun.com）是因为官方源在国外，国内访问速度极慢。
3. **yum install docker-ce docker-ce-cli containerd.io**：docker-ce是Docker社区版引擎（核心守护进程），docker-ce-cli是命令行客户端工具，containerd.io是容器运行时（container runtime），负责容器的完整生命周期管理，包括镜像传输、存储、容器执行和网络等。
4. **systemctl start/enable docker**：systemctl是systemd系统和服务管理器。start命令启动Docker守护进程（dockerd），enable命令创建符号链接到multi-user.target.wants目录，使Docker在系统启动时自动运行。
5. **docker run hello-world**：该命令验证Docker安装是否成功。Docker Client通过REST API与Docker Daemon通信，将run请求发送给Daemon处理。Daemon从Docker Hub拉取hello-world镜像并在容器中运行，输出欢迎信息。

**Docker的C/S架构原理**：Docker采用C/S（客户端/服务器）架构。Docker Daemon（守护进程）是后台运行的服务进程，负责管理镜像、容器、网络、卷等资源。Docker Client（命令行工具）通过REST API与Daemon通信，用户执行的每一条docker命令都会被转换为API请求发送给Daemon处理。

### 易错点

1. **忘记安装依赖包**：缺少yum-utils会导致yum-config-manager命令不可用；缺少device-mapper-persistent-data和lvm2会导致Docker存储驱动初始化失败。
2. **SELinux未关闭**：CentOS默认开启SELinux，会阻止Docker容器访问宿主机文件系统。需执行setenforce 0临时关闭，或修改/etc/selinux/config中SELINUX=disabled永久关闭。
3. **防火墙端口未开放**：Docker服务默认监听/var/run/docker.sock Unix socket，远程访问需开放2375端口（不安全）或使用TLS加密。
4. **使用sudo执行docker命令**：每次都要输入sudo很麻烦，可以将当前用户加入docker用户组：sudo usermod -aG docker $USER，然后重新登录生效。
5. **Docker服务启动失败**：检查journalctl -u docker.service查看错误日志，常见原因是端口冲突或存储驱动配置错误。

## （二）配置镜像加速器

### 部署步骤

第一步：创建Docker配置目录

```bash
sudo mkdir -p /etc/docker
```

第二步：写入镜像加速配置

```bash
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://docker.m.daocloud.io"]
}
EOF
```

第三步：重启Docker服务使配置生效

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

第四步：验证配置是否生效

```bash
sudo docker info | grep -A 1 "Registry Mirrors"
```

### 原理讲解

1. **mkdir -p /etc/docker**：创建Docker的配置文件目录。-p参数表示如果目录已存在则不报错，同时创建所有必要的父目录。
2. **tee /etc/docker/daemon.json**：daemon.json是Docker守护进程的核心配置文件。registry-mirrors字段配置镜像加速器地址。当Docker需要从Docker Hub拉取镜像时，会先向加速器地址请求，如果加速器缓存中有该镜像，则直接返回；如果没有，则从Docker Hub拉取并缓存后再返回给客户端。
3. **systemctl daemon-reload && systemctl restart docker**：daemon-reload命令重新加载systemd的配置文件（包括修改后的服务单元文件），restart命令重启Docker守护进程使其读取新的daemon.json配置。
4. **docker info | grep "Registry Mirrors"**：docker info命令显示Docker系统的详细信息，grep过滤出Registry Mirrors部分，确认加速器地址已生效。

**配置优先级**：daemon.json > 命令行参数 > 环境变量。即daemon.json中的配置会覆盖命令行参数，命令行参数又会覆盖环境变量。

### 易错点

1. **daemon.json格式错误**：JSON要求键名必须用双引号，值如果是数组需用方括号，末尾不能有逗号。
2. **阿里云镜像加速器返回403错误**：阿里云对免费用户的镜像加速器进行了访问限制，改用DaoCloud镜像源https://docker.m.daocloud.io。
3. **配置后未重启Docker**：修改daemon.json后必须执行systemctl restart docker重启服务，否则配置不会生效。
4. **多个镜像源冲突**：不建议同时配置多个镜像加速器，可能导致拉取行为不确定。
5. **镜像加速器地址过期**：部分公共镜像加速器可能停止维护，如果拉取镜像仍很慢，需要更换新的加速器地址。

## （三）部署Ollama容器

### 部署步骤

第一步：拉取Ollama官方镜像

```bash
sudo docker pull ollama/ollama
```

第二步：运行Ollama容器（后台运行、端口映射、数据卷挂载）

```bash
sudo docker run -d \
  --name ollama \
  -p 11434:11434 \
  -v ollama_data:/root/.ollama \
  ollama/ollama
```

第三步：进入容器内部

```bash
sudo docker exec -it ollama /bin/bash
```

第四步：在容器内下载模型

```bash
ollama pull deepseek-r1:1.5b
ollama pull qwen2:1.5b
```

第五步：测试模型

```bash
ollama run deepseek-r1:1.5b
```

### 原理讲解

1. **docker pull ollama/ollama**：从Docker Hub拉取Ollama官方镜像。镜像是只读的模板文件，包含应用程序及其运行所需的文件系统、库、依赖等。拉取完成后镜像存储在宿主机上，可以被多次用于创建容器。
2. **docker run -d --name ollama -p 11434:11434 -v ollama_data:/root/.ollama ollama/ollama**：这是核心部署命令，各参数原理如下：
   - -d（detached模式）：容器在后台运行不占用终端。Docker Daemon在后台管理容器的生命周期，终端可以释放用于其他操作。
   - --name ollama：为容器指定名称为ollama，方便后续通过名称管理容器（如docker exec ollama、docker stop ollama），而不需要使用容器ID。
   - -p 11434:11434（端口映射）：通过宿主机NAT网络实现，将宿主机的11434端口流量转发到容器的11434端口。外部请求访问宿主机IP:11434时，流量会被转发到容器的11434端口。格式为宿主机端口:容器端口。
   - -v ollama_data:/root/.ollama（数据卷挂载）：数据卷（Volume）是Docker管理的持久化存储机制，独立于容器的生命周期。即使删除容器，数据卷中的数据也不会丢失。这解决了容器无状态设计的局限性——容器销毁后数据会丢失，而数据卷可以跨容器共享和持久化。/root/.ollama是Ollama存储模型文件的目录。
   - ollama/ollama（镜像名）：指定要运行的镜像名称。
3. **docker exec -it ollama /bin/bash**：在运行中的容器内执行命令。-i表示交互式（STDIN保持打开），-t表示分配伪TTY终端，使命令可以像直接在容器内操作一样。/bin/bash在容器内启动一个交互式bash shell。
4. **ollama pull**：从Ollama Hub拉取指定的大语言模型文件到容器内的/root/.ollama/models目录。模型文件通常占用数GB空间，存储在之前挂载的数据卷中。
5. **ollama run**：运行指定的模型进行对话测试。Ollama容器启动后，会在容器内运行一个HTTP API服务，默认监听11434端口，提供模型管理、推理对话等接口。

### 易错点

1. **忘记挂载数据卷**：如果不使用-v参数挂载数据卷，容器内下载的模型文件会存储在容器的可写层中。删除容器后模型文件将永久丢失，下次启动需要重新下载。
2. **端口冲突**：如果宿主机11434端口已被其他服务占用，容器启动会失败。使用netstat -tlnp | grep 11434检查端口占用情况。
3. **容器内模型下载慢**：容器内网络可能受限，如果ollama pull频繁中断，可以尝试在宿主机上先下载模型文件再挂载，或使用--network host模式。
4. **磁盘空间不足**：大模型文件通常占用数GB空间，确保宿主机有足够磁盘空间。使用docker system df查看Docker磁盘使用情况。
5. **ollama pull后模型不显示**：确保在容器内执行ollama list，而不是在宿主机执行。容器内的ollama命令作用于容器内的Ollama服务实例。

## （四）验证Ollama服务

### 部署步骤

第一步：查看容器运行状态

```bash
sudo docker ps | grep ollama
```

第二步：测试API是否正常

```bash
curl http://localhost:11434/api/tags
```

第三步：查看容器日志

```bash
sudo docker logs ollama
```

第四步：查看容器资源占用

```bash
sudo docker stats ollama
```

### 原理讲解

1. **docker ps | grep ollama**：docker ps命令通过Docker API查询当前运行中的容器信息，包括容器ID、名称、镜像、状态、端口映射、创建时间等。grep过滤出包含ollama的行。
2. **curl http://localhost:11434/api/tags**：Ollama容器启动后，会在容器内运行一个HTTP API服务，默认监听11434端口。该API提供了模型管理、推理对话等接口。/api/tags端点返回已下载的模型列表（JSON格式），包含模型名称、大小、修改时间等信息。如果返回空列表，说明模型尚未下载或下载失败。
3. **docker logs ollama**：读取容器的stdout和stderr输出。Ollama服务启动时会打印加载模型、初始化API等日志信息，是排查启动问题的第一工具。
4. **docker stats ollama**：通过读取cgroup统计信息，实时显示容器的CPU使用率、内存占用、网络IO和磁盘IO。

### 易错点

1. **curl连接被拒绝**：如果curl返回Connection refused，说明Ollama服务尚未完全启动。等待10-20秒后重试，或查看docker logs确认服务已就绪。
2. **从宿主机curl localhost无法访问**：确保端口映射正确（-p 11434:11434），且防火墙未阻止11434端口。执行firewall-cmd --query-port=11434/tcp检查。
3. **docker logs输出为空**：如果容器刚启动，日志可能还未写入。使用docker logs -f ollama实时跟踪日志输出。
4. **容器状态为Exited**：说明容器已退出，使用docker logs ollama查看退出原因，通常是启动命令错误或配置问题。使用docker start ollama重新启动。
