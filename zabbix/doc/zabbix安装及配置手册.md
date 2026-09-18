# 配置zabbix服务器 —— 一、服务器安装与环境准备

> 说明：本篇对应手册的「1. 关闭防火墙」「2. 安装相关软件」两个步骤。命令的完整汇总脚本见仓库 `zabbix/scripts/install_zabbix_server.sh`。

## 1. 关闭防火墙以及安全增强机制

```bash
systemctl stop firewalld
#systemctl disable firewalld  开机不自启
setenforce 0
```

## 2. 安装相关软件

### 2.1 安装基础软件

```bash
yum install vim tar net-tools wget -y
```

说明：vim是文本编辑器，tar是压缩解压工具
net-tools是网络管理工具，wget是下载工具

### 2.2 安装lnmp核心软件

```bash
yum install nginx -y            # 安装nginx主程序，用于网站页面显示。
yum install php php-fpm -y      # 安装php主程序，用于将鼠标动作转换成机器语言。
yum install mysql-server -y     # 安装数据库主程序，用于存储网页内容等信息。
yum install php-mysqlnd -y      # 安装数据库扩展主程序，用于数据库和php对接程序。
```

### 2.3 安装zabbix官方源

```bash
rpm -Uvh https://repo.zabbix.com/zabbix/7.2/release/centos/9/noarch/zabbix-release-latest-7.2.el9.noarch.rpm
```

### 2.4 安装zabbix相关软件

```bash
yum install zabbix-server-mysql zabbix-web-mysql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent -y
```

# 配置zabbix服务器 —— 二、数据库与Nginx配置

> 说明：本篇对应手册的「3. 数据库配置」「4. nginx配置」两个步骤。数据库建库建用户的完整 SQL 见仓库 `zabbix/scripts/zabbix_db.sql`。

## 3. 数据库配置

### 3.1 数据库基础环境配置

```bash
systemctl start mysqld          # 启动数据库
systemctl enable mysqld         # 设置开机自启动
```

### 3.2 设置管理员root密码

```bash
mysql_secure_installation
```

回车后：（此处原文为操作截图）

### 3.3 登录和设置数据库

```bash
mysql -u root -p
```

之后输入刚刚设置的密码

### 3.4 创建zabbix的数据库和用户

按官方说明，创建数据库

```sql
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user 'zabbix'@'%' identified by 'password';    #password不带引号，自己设置必须带特殊字符、大小写、数字，长度超过8位。
grant all privileges on zabbix.* to 'zabbix'@'%';     #'zabbix'@'%'允许所有ip地址登录，也可以改为指定ip地址。
set global log_bin_trust_function_creators = 1;
quit;
```

### 3.5 导入zabbix数据库表项

```bash
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```

按回车后输入密码，一定要输对，输入密码后可能会卡住，是正常的。

恢复相关权限：

```bash
mysql -u root -p
set global log_bin_trust_function_creators = 0;
quit;
```

## 4. nginx配置

配置文件

```bash
vim /etc/nginx/conf.d/zabbix.conf
```

（此处原文为配置截图）

将监听端口前面的#删掉（端口号可以自行设置）

开启nginx：

```bash
systemctl start nginx
systemctl enable nginx
```

# 配置zabbix服务器 —— 三、Zabbix服务器配置与Web初始化

> 说明：本篇对应手册的「5. zabbix服务器配置」步骤。

## 5. zabbix服务器配置

### 5.1 编辑配置文件

```bash
vim /etc/zabbix/zabbix_server.conf
```

把DBPassword参数设置为刚刚设置的密码（前面的#删掉）

```
# Mandatory: no
# Default:
DBPassword=@Yr3522741412
```

启动相关服务

```bash
systemctl restart zabbix-server zabbix-agent nginx php-fpm
```

设置开机自启动：

```bash
systemctl enable mysqld
systemctl enable zabbix-server
systemctl enable zabbix-agent
systemctl enable nginx
systemctl enable php-fpm
```

### 5.2 输入IP地址访问

选择简体中文：（此处原文为操作截图）

点击下一步，检查是否全为OK，如果是，点击下一步：（此处原文为操作截图）

输入相关信息点击下一步（此处原文为操作截图）

设置主机名，选择时区为上海：点击下一步（此处原文为操作截图）

后面一直点下一步，完成配置，进行登录（此处原文为操作截图）

默认用户名：Admin
密码：zabbix

Zabbix主机配置完成。

# 配置zabbix服务器 —— 四、被监控主机配置（Linux / Windows / 网络设备）

> 说明：本篇对应手册的「6. Linux端配置被监控主机」「7. Windows端配置被监控主机」「8. 网络设备配置被监控主机」。Linux端 agent 的完整配置命令见仓库 `zabbix/scripts/zabbix_agent_setup.sh`。

## 6. Linux端配置被监控主机

### 6.1 关闭服务器防火墙和安全增强机制

```bash
systemctl stop firewalld
#systemctl disable firewalld  开机不自启
setenforce 0
```

### 6.2 安装zabbix官方源

```bash
rpm -Uvh https://repo.zabbix.com/zabbix/7.2/release/centos/9/noarch/zabbix-release-latest-7.2.el9.noarch.rpm
```

### 6.3 安装agent程序

```bash
yum install zabbix-agent -y
```

### 6.4 配置agent

```bash
vi /etc/zabbix/zabbix_agentd.conf
```

修改两项参数：

1. （此处原文为参数截图）改为zabbix服务器的ip地址

2. （此处原文为参数截图）删掉Hostname前面的#，后面输入被监控主机（自己）的ip地址。

3. 设置启动和开机自启动

```bash
systemctl start zabbix-agent
systemctl enable zabbix-agent
```

回到图形化界面，选择数据采集->主机->创建主机：（此处原文为操作截图）

输入主机名称、可见名称（可以为中文）、模版（用于区分不同服务器监控指标）选择Linux by zabbix-agent，主机群组，接口：（此处原文为操作截图）

回到监控->主机，等待一会，看可用性为绿色，即为添加成功（此处原文为操作截图）

点击主机，选择图形，就可以看到图形化数据显示：（此处原文为操作截图）

### 解决图形界面中文字体无法正常显示

在Windows的：C:\Windows\Fonts里面选择一个喜欢的字体，上传到zabbix服务器，进行替换：

```bash
cp -ar /STKAITI.TTF /usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf  #/STKAITI.TTF以实际文件名为准
```

替换后按F5刷新（此处原文为操作截图）

## 7. Windows端配置被监控主机

### 7.1 选择zabbix agent

（此处原文为操作截图）

### 7.2 根据被监控主机选择和下载agent

（此处原文为操作截图）

### 7.3 下载后点击运行，一直下一步，输入服务器主机地址：

（此处原文为操作截图）

### 7.4 回到图形化界面，选择数据采集->主机->创建主机：

（此处原文为操作截图）

回到监控->主机，等待一会，看可用性为绿色，即为添加成功（此处原文为操作截图）

## 8. 网络设备（如防火墙、路由器、交换机）配置被监控主机

### 8.1

（此处原文为操作截图）

勾选snmp（此处原文为操作截图）

配置防火墙策略：（此处原文为操作截图）

# 配置zabbix服务器 —— 五、告警配置与邮件发送

> 说明：本篇对应手册的「9. 告警配置」「10. 邮件发送告警邮件」。s-nail 邮件配置文件内容见仓库 `zabbix/scripts/snail.rc`。

## 9. 告警配置

### 9.1 进入数据采集->模版进行配置

（此处原文为操作截图）

点击Linux by zabbix agent->宏进行数值告警配置（此处原文为操作截图）

点击触发器，对详细数值进行编辑（此处原文为操作截图）

## 10. 邮件发送告警邮件

### 10.1 登录网易邮箱，点击设置->pop1/smtp/imap

（此处原文为操作截图）

确保授权密码存在、记住SMTP（我的授权密码：AAQJzZqh2R8F2b9z）（此处原文为操作截图）

### 10.2 在Linux的zabbix服务器上安装发邮件的软件

最新版本是s-nail，非最新版是mailx

```bash
yum install s-nail -y
```

或

```bash
yum install mailx -y
```

### 10.3 配置邮箱

如果是s-nail

```bash
vim /etc/snail.rc
```

会提示只读，并不影响，进入后先点击大写G跳到文件末尾，再点击o，保存时wq!即可

配置内容（见仓库 `zabbix/scripts/snail.rc`）：

```
set v15-compat
set from="邮箱用户名@163.com"
set mta=smtps://邮箱用户名%40163.com:授权码@smtp.163.com:465 
set smtp-auth=login
```

（此处原文为配置截图）

测试：

```bash
echo 'zabbix test' | mail -s 'zabbix test' 19881295059@163.com
```

（此处原文为操作截图）

### 10.3 添加告警媒介：点击告警->媒介->创建媒介类型

（此处原文为操作截图）

### 10.4 配置触发器

点击告警->动作->触发器动作->创建动作（此处原文为操作截图）

配置操作：（此处原文为操作截图）

配置恢复操作：（此处原文为操作截图）

点击用户->用户->admin（此处原文为操作截图）

然后点击更新和应用。（此处原文为操作截图）
