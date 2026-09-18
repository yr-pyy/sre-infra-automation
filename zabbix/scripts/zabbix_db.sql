
-- Zabbix 数据库建库建用户脚本
-- 来源：《zabbix安装及配置手册》步骤 3.4 / 3.5
-- 用法：先 mysql -u root -p 登录，再粘贴执行下面 create/grant 部分

-- ---------- 3.4 创建zabbix的数据库和用户（按官方说明）----------
-- password不带引号，自己设置必须带特殊字符、大小写、数字，长度超过8位
-- 'zabbix'@'%'允许所有ip地址登录，也可以改为指定ip地址
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user 'zabbix'@'%' identified by 'password';
grant all privileges on zabbix.* to 'zabbix'@'%';
set global log_bin_trust_function_creators = 1;
quit;

-- ---------- 3.5 导入zabbix数据库表项（在 shell 中执行，非SQL）----------
-- zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
-- 按回车后输入密码，一定要输对，输入密码后可能会卡住，是正常的。

-- ---------- 导入完成后恢复相关权限（mysql -u root -p 后执行）----------
set global log_bin_trust_function_creators = 0;
quit;
