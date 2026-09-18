#!/bin/bash
# =============================================
# 系统日常巡检脚本
# 功能：检查磁盘、内存、CPU负载、进程、登录、网络、错误日志
# 适用：Rocky Linux / CentOS 7+
# 作者：根据学习内容编写
# =============================================
# ---------- 颜色定义 ----------
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m' # No Color
# ---------- 配置项 ----------
DISK_WARN=80          # 磁盘使用率警告阈值(%)
MEM_WARN=80           # 内存使用率警告阈值(%)
LOAD_WARN=5           # 负载警告阈值(5分钟平均)
PING_TARGET="192.168.166.2"   # 网关地址，用于网络检测
LOG_FILE="/var/log/messages"   # 系统日志文件
# ---------- 输出报告文件 ----------
REPORT_DIR="/tmp"
REPORT_FILE="${REPORT_DIR}/inspection_$(date +%Y%m%d_%H%M%S).txt"
# ---------- 函数：打印标题 ----------
print_title() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    系统日常巡检报告 - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}========================================${NC}"
}
# ---------- 函数：收集主机信息 ----------
collect_host_info() {
    echo -e "${GREEN}>>> 主机信息${NC}"
    echo "主机名: $(hostname)"
    echo "系统版本: $(cat /etc/rocky-release 2>/dev/null || cat /etc/redhat-release 2>/dev/null || echo '未知')"
    echo "内核版本: $(uname -r)"
    echo "运行时间: $(uptime -p | sed 's/up //')"
    echo "当前登录用户: $(who | wc -l) 人"
    echo ""
}
# ---------- 函数：检查磁盘使用率 ----------
check_disk() {
    echo -e "${GREEN}>>> 磁盘使用情况${NC}"
    df -h | grep -E '^/dev/' | while read -r line; do
        usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        mount=$(echo "$line" | awk '{print $6}')
        if [ "$usage" -ge "$DISK_WARN" ]; then
            echo -e "  ${RED}警告${NC}: $mount 使用率 ${usage}% (超过阈值 ${DISK_WARN}%)"
        else
            echo "  $mount 使用率 ${usage}%"
        fi
    done
    echo ""
}
# ---------- 函数：检查内存使用率 ----------
check_memory() {
    echo -e "${GREEN}>>> 内存使用情况${NC}"
    total=$(free -m | awk '/^Mem:/{print $2}')
    used=$(free -m | awk '/^Mem:/{print $3}')
    free=$(free -m | awk '/^Mem:/{print $4}')
    usage=$(( used * 100 / total ))
    echo "  总内存: ${total}MB"
    echo "  已用: ${used}MB, 空闲: ${free}MB"
    if [ "$usage" -ge "$MEM_WARN" ]; then
        echo -e "  ${RED}警告${NC}: 内存使用率 ${usage}% (超过阈值 ${MEM_WARN}%)"
    else
        echo "  内存使用率: ${usage}%"
    fi
    # Swap
    swap_total=$(free -m | awk '/^Swap:/{print $2}')
    if [ "$swap_total" -gt 0 ]; then
        swap_used=$(free -m | awk '/^Swap:/{print $3}')
        echo "  Swap 总: ${swap_total}MB, 已用: ${swap_used}MB"
    fi
    echo ""
}
# ---------- 函数：检查系统负载 ----------
check_load() {
    echo -e "${GREEN}>>> 系统负载${NC}"
    load1=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | sed 's/ //g')
    load5=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $2}' | sed 's/ //g')
    load15=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $3}' | sed 's/ //g')
    echo "  1分钟: $load1, 5分钟: $load5, 15分钟: $load15"
    # 将负载转为整数比较（取整）
    load_int=$(echo "$load5" | cut -d. -f1)
    if [ "$load_int" -ge "$LOAD_WARN" ]; then
        echo -e "  ${RED}警告${NC}: 5分钟负载 ${load5} 超过阈值 ${LOAD_WARN}"
    fi
    echo ""
}
# ---------- 函数：检查关键进程 ----------
check_processes() {
    echo -e "${GREEN}>>> 关键进程状态${NC}"
    for proc in sshd httpd nginx mysqld zabbix_server; do
        if pgrep -x "$proc" > /dev/null 2>&1; then
            echo "  $proc: 运行中"
        else
            echo -e "  ${YELLOW}$proc: 未运行${NC}"
        fi
    done
    echo ""
}
# ---------- 函数：网络连通性检测 ----------
check_network() {
    echo -e "${GREEN}>>> 网络连通性${NC}"
    if ping -c 2 -W 1 "$PING_TARGET" &> /dev/null; then
        echo "  网关 ${PING_TARGET}: 可达"
    else
        echo -e "  ${RED}网关 ${PING_TARGET}: 不可达${NC}"
    fi
    # 检测外网（可选）
    if ping -c 2 -W 1 8.8.8.8 &> /dev/null; then
        echo "  外网(8.8.8.8): 可达"
    else
        echo -e "  ${YELLOW}外网(8.8.8.8): 不可达${NC}"
    fi
    echo ""
}
# ---------- 函数：检查系统日志错误 ----------
check_logs() {
    echo -e "${GREEN}>>> 最近系统日志错误 (最后20行包含ERROR/WARN)${NC}"
    if [ -f "$LOG_FILE" ]; then
        grep -E "ERROR|WARN" "$LOG_FILE" 2>/dev/null | tail -20 | while read -r line; do
            echo "  $line"
        done
    else
        echo "  日志文件 $LOG_FILE 不存在"
    fi
    echo ""
}
# ---------- 主函数 ----------
main() {
    # 清屏，便于查看
    clear
    # 打印标题（同时屏幕显示和写入文件）
    print_title | tee -a "$REPORT_FILE"
    collect_host_info | tee -a "$REPORT_FILE"
    check_disk | tee -a "$REPORT_FILE"
    check_memory | tee -a "$REPORT_FILE"
    check_load | tee -a "$REPORT_FILE"
    check_processes | tee -a "$REPORT_FILE"
    check_network | tee -a "$REPORT_FILE"
    check_logs | tee -a "$REPORT_FILE"
    echo -e "${BLUE}========================================${NC}" | tee -a "$REPORT_FILE"
    echo -e "报告已保存至: ${GREEN}$REPORT_FILE${NC}"
}
# ---------- 执行主函数 ----------
main
# 退出
exit 0
