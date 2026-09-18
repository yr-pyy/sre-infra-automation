## 三、Shell脚本实战

### （一）分支控制（case语句）

**【详细用法】** 

case语句用于多分支选择，语法清晰、执行效率高。基本语法为case $变量 in 模式1) 命令1;; 模式2) 命令2;; *) 默认命令;; esac。支持多模式匹配（y|Y|yes|YES）和通配符。每个分支末尾必须以;;结束，最后一个分支可使用*作为默认匹配（相当于else）。

**【原理】** 

case语句通过模式匹配（pattern matching）将变量值与多个模式逐一比较。匹配成功则执行对应的命令列表，直到遇到;;（相当于break）跳出case结构。*是通配符，匹配任何值，作为最后的默认分支。模式之间用|分隔表示或关系，如y|Y|yes|YES匹配大小写各种形式的”是”。case语句比多层if-elif-else更高效，因为Shell可以对case的模式进行优化（如哈希查找）。

**【我的操作记录】** 

我编写了多个case语句脚本进行练习：

服务控制脚本casetest.sh：

```bash
[root@192 ~]# ./casetest.sh
请输入操作（start/stop/restart/status）：start
服务启动中...
[root@192 ~]# ./casetest.sh
请输入操作（start/stop/restart/status）：stop
服务停止中...
[root@192 ~]# ./casetest.sh
请输入操作（start/stop/restart/status）：lie
错误，未知操作lie
支持：start | stop | restart | status
```

确认删除脚本casetest1.sh，支持多模式匹配：

```bash
[root@192 ~]# ./casetest1.sh
确认删除吗？（y/n）y
执行删除...
[root@192 ~]# ./casetest1.sh
确认删除吗？（y/n）yes
执行删除...
```

运维工具箱casetest2.sh，结合case和系统命令：

```bash
[root@192 ~]# ./casetest2.sh
=====运维工具箱=====
1）查看磁盘使用率
2）查看内存使用率
3）查看系统负载
4）退出
请选择（1-4）：1
文件系统                  容量  已用  可用 已用% 挂载点
...
[root@192 ~]# ./casetest2.sh
...
请选择（1-4）：2
               total        used        free      shared  buff/cache   available
Mem:           7.5Gi       561Mi       6.9Gi       9.0Mi       289Mi       6.9Gi
...
[root@192 ~]# ./casetest2.sh
...
请选择（1-4）：4
再见！
```

**【我的脚本代码】** 

casetest.sh（服务控制）：

```bash
#!/bin/bash
read -p "请输入操作（start/stop/restart/status）：" opt
case $opt in
        start)
                echo "服务启动中..."
                ;;
        stop)
                echo "服务停止中..."
                ;;
        restart)
                echo "服务重启中..."
                ;;
        status)
                echo "服务运行中..."
                ;;
        *)
                echo "错误，未知操作$opt"
                echo "支持：start | stop | restart | status"
                exit 1
                ;;
esac
```

casetest1.sh（确认删除）：

```bash
#!/bin/bash
read -p "确认删除吗？（y/n）" ans
case $ans in
        y|Y|yes|YES)
                echo "执行删除..."
                ;;
        n|N|no|NO)
                echo "取消删除..."
                ;;
        *)
                echo "输入无效，请输入y或n"
                ;;
esac
```

casetest2.sh（运维工具箱）：

```bash
#!/bin/bash
echo "=====运维工具箱====="
echo "1）查看磁盘使用率"
echo "2）查看内存使用率"
echo "3）查看系统负载"
echo "4）退出"
read -p "请选择（1-4）：" choice
case $choice in
        1) df -h;;
        2) free -h;;
        3) uptime ;;
        4) echo "再见！"; exit 0;;
        *) echo "无效选择" ;;
esac
```

**【易错点】** 

1. 每个分支末尾必须用;;结束，遗漏;;会导致所有后续分支都被执行
2. esac（case倒写）忘记写会导致未预期的文件结束符错误
3. *默认分支中若不需要退出脚本，不应写exit 1，否则脚本会直接终止
4. 模式匹配是精确匹配，start不会匹配starting，需注意模式的粒度
5. case中的变量未加引号时，若值为空或含空格可能导致模式匹配异常

### （二）循环控制

**【详细用法】** 

for循环用于遍历列表，语法为for var in list; do ... done。while循环用于满足条件时的重复执行，语法为while [[ condition ]]; do ... done。while read -r line; do ... done < file.txt用于逐行读取文件。

**【原理】** 

for循环在in后面列出所有元素，每次迭代将下一个元素赋值给循环变量var。for server in "servers[@]";do...done是遍历数组的标准写法，必须用双引号包裹"{servers[@]}"以防止文件名展开（globbing）。while循环每次迭代前评估条件表达式，为true时执行循环体。while read -r line; do ... done < file.txt利用重定向将文件内容作为read的标准输入，read每次读取一行并返回退出码0（有内容）或1（文件结束），-r选项防止反斜杠转义。

**【我的操作记录】** 

批量ping检测脚本casetest3.sh：

```bash
[root@192 ~]# ./casetest3.sh
正在检测：192.168.166.1
192.168.166.1 离线
正在检测：192.168.166.45
192.168.166.45 离线
正在检测：192.168.166.0
192.168.166.0 离线
```

计数while循环whiletest.sh：

```bash
[root@192 ~]# ./whiletest.sh
count = 1
count = 2
count = 3
count = 4
count = 5
```

逐行读取文件whiletest1.sh：

```bash
[root@192 ~]# ./whiletest1.sh
行内容：root:x:0:0:root:/root:/bin/bash
行内容：bin:x:1:1:bin:/bin:/sbin/nologin
行内容：daemon:x:2:2:daemon:/sbin:/sbin/nologin
...
行内容：mysql:x:27:27:MySQL Server:/var/lib/mysql:/sbin/nologin
行内容：zabbix:x:995:995:Zabbix Monitoring System:/var/lib/zabbix:/sbin/nologin
```

读取服务器列表文件whiletest1.sh（结合serverlist.txt）：

```bash
[root@192 ~]# ./whiletest1.sh
web01的ip地址是：192.168.166.1
web02的ip地址是：192.168.182.4
database01的ip地址是：192.168.166.44
```

在编写whiletest1.sh时，曾因拼写错误eche导致无限循环输出错误信息，修正为echo后恢复正常。

**【我的脚本代码】** 

casetest3.sh（批量ping检测）：

```bash
#!/bin/bash
for ip in 192.168.166.1 192.168.166.45 192.168.166.0; do
        echo "正在检测：$ip"
        ping -c 2 -W 1 $ip &> /dev/null
        if [[ $? -eq 0 ]]; then
                echo "$ip 在线"
        else
                echo "$ip 离线"
        fi
done
```

whiletest.sh（计数循环）：

```bash
#!/bin/bash
count=1
while [[ $count -le 5 ]]; do
        echo "count = $count"
        ((count++))
done
```

whiletest1.sh（逐行读取文件）：

```bash
#!/bin/bash
while read -r line; do
        echo "行内容：$line"
done < /etc/passwd
```

**【易错点】** 

1. for循环中${servers[@]}未加双引号，导致含空格的数组元素被拆分
2. while循环中缺少((count++))等增量语句，导致死循环无限输出
3. read -r中-r选项遗漏，导致含反斜杠的行被错误转义
4. while read < file.txt在循环体内若也有read输入，会冲突读取同一文件描述符
5. ping命令未将输出重定向到/dev/null，导致大量输出污染终端
6. 在while循环中修改的变量在循环结束后可能丢失（子Shell问题），需使用< file重定向而非pipe

### （三）文本处理

**【详细用法】** 

grep命令用于文本搜索匹配，支持基本匹配、-i忽略大小写、-E扩展正则表达式等选项。例如grep -i "error" app.log查找包含error的行（忽略大小写），grep -E "(WARN|ERROR)" app.log使用扩展正则匹配WARN或ERROR的行。

awk命令是一种强大的文本处理工具，支持字段分割、数组统计和END块处理。例如awk '{count[$3]++} END {for (k in count) print k, count[k]}' app.log统计日志中INFO/WARN/ERROR各级别的出现频次。

**【原理】** 

grep（Global Regular Expression Print）在文件中搜索匹配指定模式的行并输出。-i选项使匹配忽略大小写，-E启用扩展正则表达式（支持|、+、?等元字符），基本正则中这些元字符需加反斜杠转义（\|、\+）。awk是一种编程语言式的文本处理工具，默认按空白字符分割字段，1/2/3表示第1/2/3个字段。awk '{count[3]++} END {for (k in count) print k, count[k]}'的含义是：对每行记录，以$3（第3个字段，即日志级别）为键递增计数器数组count；所有行处理完毕后（END块），遍历count数组并打印键值对。

**【我的操作记录】** 

```bash
[root@192 ~]# cat app.log
2026-07-08 10:00:01 INFO User login: zhangsan
2026-07-08 10:00:03 ERROR Database connection failed
2026-07-08 10:00:05 WARN Disk usage above 80%
2026-07-08 10:00:08 INFO Order placed: #8921
[root@192 ~]# grep -i "error" app.log
2026-07-08 10:00:03 ERROR Database connection failed
[root@192 ~]# grep -E "(WARN|ERROR)" app.log
2026-07-08 10:00:03 ERROR Database connection failed
2026-07-08 10:00:05 WARN Disk usage above 80%
[root@192 ~]# awk '{count[$3]++} END {for (k in count) print k, count[k]}' app.log
WARN 1
ERROR 1
INFO 2
```

测试了grep -i忽略大小写匹配和grep -E扩展正则匹配，以及awk的字段统计功能。注意grep "(WARN|ERROR)"不加-E选项时不会匹配到结果，因为括号和|会被当作普通字符。

**【易错点】** 

1. grep "(WARN|ERROR)"不加-E选项时，括号和|会被当作普通字符而非正则元字符，导致无匹配结果
2. awk中$3引用的是分割后的第3个字段，若日志格式变化（如日期格式改变），字段位置可能偏移
3. awk的for (k in count)遍历顺序不确定，如需排序需配合sort命令
4. grep匹配模式中含特殊字符（如.、*、?）时需加-E或转义，否则会被当作正则元字符处理
5. 管道传递大量数据时注意awk的内存占用，超大文件应考虑逐行处理

### （四）数组与函数

**【详细用法】** 

Shell数组使用圆括号定义：servers=("web-01" "web-02" "db-01" "db-02" "monitor-01")。通过servers[@]获取所有元素，{servers[0]}访问索引0的元素。支持动态添加（servers+=("cache-01")）、删除（unset "servers[5]"）和获取长度（${#servers[@]}）操作。

函数使用function name { ... }或name() { ... }定义，local关键字声明局部变量，函数内外可分别访问局部变量和全局变量。使用source命令（或.）执行脚本可使变量和函数在当前Shell环境中生效，而非创建子Shell。

**【原理】** 

Shell数组是有序的元素集合，索引从0开始。array[@]展开为所有元素（每个元素独立quoted），{array[*]}展开为空格分隔的单个字符串。+=操作符向数组末尾追加元素。unset删除指定索引的元素（但不会重新编号）。${#array[@]}返回数组的元素个数。函数是Shell中的代码复用机制，function关键字定义时函数体在花括号内。local变量在函数内部创建，函数返回后自动销毁，避免与全局变量冲突。source命令在当前Shell进程中执行脚本（而非创建子进程），因此脚本中定义的变量和函数在source后可用。直接执行./script.sh会创建子Shell，子Shell中的变量不会影响到父Shell。

**【我的操作记录】** 

数组操作交互测试：

```bash
[root@192 ~]# source arrtest.sh
正在检测服务器：web-01
正在检测服务器：web-02
正在检测服务器：db-01
正在检测服务器：db-02
正在检测服务器：monitor-01
[root@192 ~]# echo ${servers[@]}
web-01 web-02 db-01 db-02 monitor-01
[root@192 ~]# echo ${servers[0]}
web-01
[root@192 ~]# servers+=("cache-01")
[root@192 ~]# echo ${servers[@]}
web-01 web-02 db-01 db-02 monitor-01 cache-01
[root@192 ~]# unset "servers[5]"
[root@192 ~]# echo ${servers[@]}
web-01 web-02 db-01 db-02 monitor-01
[root@192 ~]# echo ${#servers[@]}
5
```

注意到直接./arrtest.sh执行时，数组变量在脚本结束后消失，而source arrtest.sh执行后变量保留在当前Shell环境中。

函数与变量作用域测试：

```bash
[root@192 ~]# ./vartest.sh
函数内：局部变量
函数内：全局变量
```

**【我的脚本代码】** 

arrtest.sh（数组遍历）：

```bash
#!/bin/bash
servers=("web-01" "web-02" "db-01" "db-02" "monitor-01")
for server in "${servers[@]}"; do
        echo "正在检测服务器：$server"
done
```

**【易错点】** 

1. 数组定义时元素间需用空格分隔，逗号分隔会报错
2. servers[@]遍历数组时必须加双引号：forserverin"{servers[@]}"; do，否则含空格的元素会被拆分
3. unset删除元素后不重新编号，${#servers[@]}会反映实际元素数但索引可能不连续
4. 函数中未使用local声明的变量是全局的，同名变量会被覆盖
5. 直接./script.sh执行脚本时，其中定义的变量和函数在脚本结束后消失，需用source script.sh在当前Shell中加载
6. 函数名不能以数字开头，且不能与Shell内置命令同名
