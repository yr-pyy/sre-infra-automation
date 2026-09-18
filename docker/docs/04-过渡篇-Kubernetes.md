# 四、Docker至Kubernetes过渡总结

## （一）Docker与K8s核心概念映射

### 部署步骤

本部分为知识总结，无需实际操作步骤。以下通过表格形式梳理Docker与Kubernetes的核心概念映射关系，帮助你建立从容器到容器编排的完整知识体系。

### 原理讲解

Docker是容器化的基础技术，解决了"一次构建、到处运行"的问题。Kubernetes（K8s）是容器编排引擎，解决了"大规模容器管理"的问题。理解两者概念的映射关系，是顺利过渡到K8s的关键。

**Docker与K8s核心概念映射表：**

| Docker概念       | Kubernetes概念                                      | 说明                                                   |
| -------------- | ------------------------------------------------- | ---------------------------------------------------- |
| 容器(Container)  | Pod                                               | K8s最小部署单元，一个Pod可包含一个或多个紧密关联的容器（Sidecar模式）            |
| docker run     | Deployment                                        | 声明式管理Pod副本数、更新策略（滚动更新/回滚），实现应用的自动化部署和扩缩容             |
| docker network | Service + Ingress                                 | Service提供稳定的网络端点和服务发现（DNS），Ingress管理外部HTTP/HTTPS流量路由 |
| Volume         | PersistentVolume(PV) + PersistentVolumeClaim(PVC) | PV是集群级存储资源，PVC是用户对存储的请求，两者通过绑定机制实现存储的声明式管理           |
| docker-compose | Helm Chart                                        | Helm是K8s的包管理工具，通过Chart模板定义多资源应用的部署配置，支持版本管理和参数化      |
| docker inspect | kubectl describe                                  | kubectl describe用于查看K8s资源的详细信息和事件，是排查问题的核心命令         |

**Docker与K8s架构差异：**

Docker采用C/S架构：Docker Client通过REST API与Docker Daemon通信，管理单机上的容器。K8s采用主从架构：Master节点运行API Server（统一入口）、Scheduler（资源调度）、Controller Manager（控制器管理器）、etcd（分布式键值存储）；Node节点运行kubelet（节点代理）、kube-proxy（网络代理）、容器运行时。K8s通过声明式API工作——用户提交期望状态（YAML），控制平面持续调整集群状态以匹配期望状态。

### 易错点

1. 概念混淆：初学者容易将Pod等同于容器。实际上Pod是K8s的最小部署单元，一个Pod可以包含多个容器（主容器和Sidecar容器），共享网络命名空间和存储卷。
2. docker run思维惯性：习惯用docker run一次性指定所有参数，在K8s中需要拆分为多个资源对象（Deployment、Service、ConfigMap等）并通过YAML声明式管理。
3. 端口映射方式不同：Docker使用-p参数直接端口映射，K8s中需要通过Service（ClusterIP/NodePort/LoadBalancer）暴露服务，不能直接在Pod层面映射端口。
4. 数据持久化方式不同：Docker直接使用-v挂载宿主机目录或命名卷，K8s中需要通过PVC向存储系统申请存储，由StorageClass自动或静态创建PV。
5. 网络模型差异：Docker容器间通过自定义网络的DNS名通信，K8s中Pod间通过ClusterIP（虚拟IP）通信，Service通过kube-proxy的iptables/IPVS规则实现负载均衡。

## （二）学习收获

### 部署步骤

本部分为学习总结，无需实际操作步骤。以下通过表格形式梳理从Docker到K8s的完整学习路径和核心收获。

### 原理讲解

通过本次Docker实验，结合Kubernetes的Nginx部署实践，我对容器化技术形成了完整的知识闭环。从单机容器管理到集群编排，技术栈的升级带来了管理维度的质变。

**学习路径与核心收获：**

| 学习阶段     | 核心收获                                                                       |
| -------- | -------------------------------------------------------------------------- |
| Docker基础 | 掌握了Docker的安装、镜像加速配置、容器生命周期管理（run/start/stop/rm），理解了C/S架构原理和镜像分层机制          |
| 容器网络     | 理解了Docker网络模型（bridge/host/overlay/macvlan），学会了自定义网络的创建和容器间DNS通信配置          |
| 数据持久化    | 掌握了数据卷(Volume)的创建、挂载、备份与恢复，理解了容器无状态设计的局限性及数据持久化的必要性                        |
| 容器运维     | 通过Portainer监控面板和自动化备份脚本，建立了容器化应用的运维意识，掌握了日志排查和资源监控的基本方法                    |
| K8s进阶    | 通过Nginx部署实践，理解了Deployment、ConfigMap、Secret、PVC、Service、HPA等核心资源对象及其声明式管理思想 |

## （三）遇到的典型问题总结

### 部署步骤

本部分为问题总结，无需实际操作步骤。以下通过表格形式梳理在Docker和K8s实践过程中遇到的典型问题及解决策略。

### 原理讲解

问题排查是容器化运维的核心能力。以下总结了实践中遇到的典型问题，按问题类型分类，帮助建立系统化的故障排查思路。

**典型问题与解决策略：**

| 问题类型 | 典型案例               | 解决策略                                                           |
| ---- | ------------------ | -------------------------------------------------------------- |
| 网络类  | 物理机无法访问虚拟机容器       | 理解NAT/桥接模式区别，配置端口转发或改用桥接模式使虚拟机与物理机同网段                          |
| 镜像类  | ghcr.io拉取超时/中断     | 使用国内镜像代理（ghcr.nju.edu.cn）拉取后docker tag重新打标签，或配置Docker多镜像源      |
| 配置类  | Open WebUI汉化环境变量失效 | 查阅官方文档，采用Web界面内设置而非环境变量方式，注意环境变量与应用的兼容性                        |
| 权限类  | 备份脚本无执行权限          | chmod +x添加执行权限，使用sudo crontab配置root级定时任务确保权限一致                 |
| 服务类  | cron定时任务未自动执行      | 检查crond服务状态(systemctl status crond)，使用绝对路径，查看/var/log/cron日志排查 |

## （四）学习建议

### 部署步骤

本部分为学习建议，无需实际操作步骤。以下总结五条核心学习建议，帮助后续深入学习容器化技术。

### 原理讲解

**基于Docker和K8s的学习实践经验，提出以下五条建议：**

1. 理论与实践结合：每学习一个Docker或K8s命令/概念，立即动手实践并观察效果。例如学习docker run后，立即运行一个nginx容器并验证访问；学习Deployment后，立即创建并观察Pod的创建过程。
2. 善用日志排查：docker logs是排查容器问题的第一工具，kubectl logs和kubectl describe是K8s中排查Pod问题的核心命令。养成遇到问题先看日志的习惯。
3. 理解网络模型：网络问题是容器化部署中最常见的故障点。深入理解Docker的bridge/overlay网络和K8s的Service/Ingress/CNI网络模型，能大幅减少排查时间。
4. 数据备份先行：在生产环境中，数据备份比应用部署更关键。养成定期备份数据卷的习惯，并定期测试恢复流程，确保备份可用。
5. 从Docker到K8s循序渐进：理解Docker是学习Kubernetes的基础。先掌握容器生命周期管理、网络、存储等基础概念，再过渡到K8s的声明式编排。不要跳过Docker直接学K8s，否则会对资源对象的设计思想理解不深。
