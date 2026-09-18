## 二、Shell脚本进阶

### （一）算术运算

**【详细用法】** 

Shell原生支持整数运算，使用$((表达式))语法，支持加(+)、减(-)、乘(*)、除(/)、取模(%)等运算符。例如a=10, b=3时：

```bash
[root@192 ~]# echo $((a + b))
13
[root@192 ~]# echo $((a-b))
7
[root@192 ~]# echo $((a*b))
30
[root@192 ~]# echo $((a%b))
1
[root@192 ~]# echo $((a/b))
3
```

还支持自增((count++))和复合赋值count=((count+1))。对于需要小数精度的浮点运算，需安装bc工具（yuminstall-ybc），通过管道将表达式传递给bc处理：rate=(echo "scale=2; a/b" | bc)，其中scale设置小数位数。

**【原理】** 

(())是Shell的算术求值表达式（ArithmeticEvaluation），Shell解析器在遇到(( ))时，会将其中的内容作为数学表达式进行求值，自动进行变量展开和算术运算，最终返回数值结果。由于Shell变量本质是字符串，(())内部会自动将变量名当作数值处理。bc（BasicCalculator）是一个独立的命令行计算器程序，支持任意精度的浮点运算。通过管道|将字符串表达式传递给bc的标准输入，bc执行计算后将结果输出到标准输出，( )捕获该输出。

**【我的操作记录】** 

在测试浮点运算时，我遇到了以下操作和错误：

```bash
[root@192 ~]# echo "scale=2;30/80*100"
scale=2;30/80*100
[root@192 ~]# echo "scale=2;30/80*100" | bc
37.00
[root@192 ~]# used=35
[root@192 ~]# total=80
[root@192 ~]# rate=(echo"scale=1;{uesd}/${total}*100" | bc)
(standard_in) 1: syntax error
[root@192 ~]# rate=(echo"scale=1;{used}/${total}*100" | bc)
[root@192 ~]# echo "磁盘使用率：${rate}"
磁盘使用率：40.0
```

第一次直接输出echo "scale=2;30/80*100"只是打印了字符串，必须通过管道传给bc才能计算。第二次变量名拼写错误uesd应为{used}，修正后成功计算磁盘使用率。

**【易错点】** 

1. $(( ))仅支持整数运算，10/3结果为3而非3.333…，需使用bc处理小数
2. echo "scale=2;30/80*100"直接输出的是字符串而非计算结果，必须通过管道传给bc
3. 变量名拼写错误导致bc报syntax error，如uesd应为{used}
4. bc的scale设置只影响除法运算，乘法和加法不受scale影响
5. (())中不能直接使用变量名前的符号，如((a + $b ))虽然能工作但不规范

### （二）用户输入与格式化输出

**【详细用法】** 

使用read命令接收用户输入，支持多种选项：-p指定提示文本（read -p "请输入姓名：" name），-s隐藏输入内容（适用于密码输入read -s -p "请输入密码：" passwd），-t设置超时时间（read -t 5 -p "5秒内选择(y/n)：" choice）。可同时读取多个变量：read -p "请输入用户名和密码：" user password。

输出方面，echo -e支持\n换行和\t制表符，printf提供更精确的格式化输出，支持%-8s左对齐、%5d固定宽度等格式控制符。例如：

```bash
[root@192 ~]# printf "%-8s %-5s %-10s\n" "姓名" "年龄" "城市" "张三" "25" "成都"
姓名   年龄 城市
张三   25    成都
```

**【原理】** 

read是Shell内置命令，从标准输入（stdin）读取一行文本，按空格分割后依次赋值给指定的变量名。-p选项在读取前输出提示信息（写入标准输出）。-s选项关闭终端的回显功能（通过stty -echo实现），使输入内容不可见。-t选项设置超时秒数，超时后read返回非零退出码。printf是Shell内置的格式化输出命令，遵循C语言printf的格式规范：%-8s表示左对齐8字符宽的字符串，%5d表示右对齐5字符宽的整数，\n表示换行符。与echo -e相比，printf提供更精确的格式控制且不会自动添加换行。

**【我的操作记录】** 

```bash
[root@192 ~]# read -p "请输入你的姓名：" name
请输入你的姓名：yr
[root@192 ~]# echo "${name}"
yr
[root@192 ~]# read -p "请输入用户名和密码（空格分隔）：" user password
请输入用户名和密码（空格分隔）：yr 123456
[root@192 ~]# echo "${user}"
yr
[root@192 ~]# echo "${password}"
123456
[root@192 ~]# read -s -p "请输入密码：" passwd
请输入密码：[root@192 ~]# echo "${passwd}"
123456
[root@192 ~]# read -t 5 -p "你有5秒钟输入你的选择（y/n）：" choice
你有5秒钟输入你的选择（y/n）：yes
[root@192 ~]# echo $choice
yes
```

测试了-p、-s、-t三个选项，以及多变量同时读取。注意-s隐藏输入时提示信息不会自动换行，光标紧跟在提示文字后面。

**【易错点】** 

1. read -s输入密码时，提示信息不会自动换行，密码输入后光标紧跟在提示文字后面
2. read -t超时后变量值为空（或未改变），需检查$?判断是超时退出还是正常输入
3. printf的格式字符串中%与s之间不能有空格，printf "%-8 s"会报错
4. echo -e中的\n和\t需要双引号包裹才生效，单引号中\n会被当作普通字符输出
5. 同时读取多个变量时，输入需用空格分隔，且变量数多于输入值时多余变量为空

### （三）输出重定向

**【详细用法】** 

Shell支持输出重定向操作：>将输出覆盖写入文件，>>将输出追加到文件末尾。例如date > /tmp/report.txt将当前时间写入文件（覆盖），df -h >> /tmp/report.txt将磁盘使用情况追加到同一文件。还可将错误输出重定向到/dev/null丢弃：command &> /dev/null或command 2> /dev/null。

**【原理】** 

Linux系统中每个进程启动时会自动打开三个标准文件描述符：0（stdin标准输入）、1（stdout标准输出）、2（stderr标准错误）。重定向操作符>和>>修改了这些文件描述符的指向。>file表示将stdout指向file（截断写入），>>file表示将stdout指向file（追加写入）。2>file将stderr指向file，&>file将stdout和stderr都指向file。/dev/null是Linux的空设备文件，写入其中的数据会被丢弃，常用于屏蔽不需要的输出。

**【我的操作记录】** 

```bash
[root@192 ~]# echo "hello" > file.txt
[root@192 ~]# echo "world" >> file.txt
[root@192 ~]# cat file.txt
hello
world
[root@192 ~]# date > /tmp/report.txt
[root@192 ~]# echo "---" >> /tmp/report.txt
[root@192 ~]# df -h >> /tmp/report.txt
[root@192 ~]# cat /tmp/report.txt
2026年 08月 16日 星期日 16:17:15 CST
---
文件系统                  容量  已用  可用 已用% 挂载点
devtmpfs                  3.8G     0  3.8G    0% /dev
tmpfs                     3.8G     0  3.8G    1% /run
/dev/mapper/rlm_192-root   70G  2.9G   68G    5% /
/dev/nvme0n1p1            960M  399M  562M   42% /boot
/dev/mapper/rlm_192-home   42G  326M  41G    1% /home
tmpfs                     765M     0  765M    0% /run/user/0
```

通过>覆盖写入和>>追加写入，成功生成了包含系统信息的report.txt文件。

**【易错点】** 

1. > 会覆盖文件内容，如需追加必须使用>>，否则之前的数据会丢失
2. 对不存在的目录进行重定向会报No such file or directory错误
3. 重定向到只读文件（如系统配置文件）会报Permission denied，需使用sudo或切换到root
4. &> /dev/null中&不能省略，2> /dev/null仅重定向错误输出，标准输出仍会显示
5. 重定向操作符优先级高于管道，echo "hello" | sort > output.txt中sort的输入来自echo而非终端

### （四）条件判断

**【详细用法】** 

if条件判断是Shell脚本的核心控制结构，语法为if [[ 条件 ]]; then ... fi。支持字符串比较（=）、空值检测（-z）、文件/目录检测（-d存在、-w可写）等操作。逻辑运算符||（或）和&&（与）可组合多个条件。例如验证用户名密码：if [[ -z name]]||[[{#psword} -lt 6 ]]; then ... fi，其中#psword获取密码长度。检测目录是否存在：if[[!-dsrc_dir ]]; then ... fi，其中!表示逻辑非。

**【原理】** 

[[ ]]是Shell的关键字（比[ ]更强大），用于执行条件表达式测试。Shell解析器评估[[ ]]内的条件，返回退出码0（true）或非0（false）。if语句根据条件表达式的退出码决定执行then分支还是else分支。${#var}是Shell的参数扩展操作符，#表示获取变量值的字符长度。-d、-w、-f等是文件测试操作符，由[[ ]]内置支持，用于查询文件系统元数据。||和&&是Shell的逻辑运算符，实现短路求值：a || b表示a为true时不执行b，a && b表示a为false时不执行b。

**【我的操作记录】** 

在编写条件判断脚本时，我经历了多次调试：

第一次尝试编写test.sh，但遇到了语法错误：

```bash
[root@192 ~]# ./test.sh
请输入姓名：yr
./test.sh:行5: 条件表达式中有语法错误：未预期的符号";"
./test.sh:行5: "if [[ $name = "袁瑞"]]; then"
```

原因是[[ ]]内运算符=两侧缺少空格。修正后：

```bash
[root@192 ~]# ./test.sh
请输入姓名：yr
（无输出，条件不满足）
[root@192 ~]# ./test.sh
请输入姓名：袁瑞
匹配
[root@192 ~]# ./test.sh
请输入姓名：
输入内容为空
```

在编写用户名密码验证脚本时，又遇到了变量引用错误：

```bash
[root@192 ~]# ./test.sh
请输入用户名和密码（用空格分割）yr 123
./test.sh:行6: 寻找匹配的")"时遇到了未预期的文件结束符
```

发现是(psword)误写，应该是{#psword}获取密码长度。修正后：

```bash
[root@192 ~]# ./test.sh
请输入用户名和密码（用空格分割）yr 123
用户名或密码不符合要求
[root@192 ~]# ./test.sh
请输入用户名和密码（用空格分割）yr 123456
（通过验证，无输出）
```

**【我的脚本代码】** 

test.sh（条件判断测试）：

```bash
#!/bin/bash
read -p "请输入姓名：" name
if [[ $name = "袁瑞" ]]; then
        echo "匹配"
fi
if [[ -z $name ]]; then
        echo "输入内容为空"
fi
```

calc.sh（计算器脚本）：

```bash
#!/bin/bash
read -p "请输入第一个数字：" a
read -p "请输入第二个数字：" b
sum=$((a+b))
diff=$((a-b))
prod=$((a*b))
quot=(echo"scale=2;a/$b" | bc)
echo "计算结果："
echo "a+{b} = ${sum}"
echo "a-{b} = ${diff}"
echo "a*{b} = ${prod}"
echo "a/{b} = ${quot}"
```

backup.sh（备份检测脚本）：

```bash
#!/bin/bash
src_dir="/data/app"
backup_dir='/backup'
#1.检测目录是否存在
if [[ ! -d $src_dir ]]; then
        echo "错误，源目录不存在"
        exit 1
fi
#2.备份目录不存在，自动创建
if [[ ! -d $backup_dir ]]; then
        echo "备份目录不存在，正在创建..."
        mkdir -p $backup_dir
fi
#3.检测备份目录是否可写
if [[ ! -w $backup_dir ]]; then
        echo "错误：备份目录不可写"
        exit 1
fi
echo "所有检测通过，开始备份..."
```

**【易错点】** 

1. [[ ]]内运算符两侧必须有空格，if [[ $name="袁瑞" ]]; then会报语法错误
2. 获取字符串长度时误写(#psword)而非{#psword}，前者尝试执行#psword命令
3. if条件中混用[ ]和[[ ]]，[ ]需要更严格的花括号和引号保护
4. 字符串比较使用=而非==（虽然bash中==也能用，但POSIX标准只规定=）
5. 数值比较应使用-eq/-ne/-lt/-gt而非=（字符串比较）
6. fi忘记写导致”寻找匹配的)时遇到了未预期的文件结束符”错误
