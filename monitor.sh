#!/bin/bash
# ASAP Sentiment Analysis - 训练监控脚本

PID_FILE="checkpoints/train.pid"
LOG_DIR="logs"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo "ASAP 训练监控工具"
    echo ""
    echo "用法: bash monitor.sh [命令]"
    echo ""
    echo "命令:"
    echo "  status    - 查看训练状态"
    echo "  log       - 查看最新日志 (实时跟踪)"
    echo "  gpu       - 查看 GPU 使用情况"
    echo "  stop      - 停止训练"
    echo "  restart   - 重新启动训练"
    echo "  help      - 显示此帮助"
    echo ""
}

show_status() {
    echo -e "${BLUE}>>> 训练状态${NC}"
    echo "------------------------------------------"

    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if ps -p $PID > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} 训练正在运行 (PID: $PID)"

            # 获取内存和 CPU 使用
            ps -p $PID -o %mem,%cpu --no-headers | while read mem cpu; do
                echo "  内存: $mem%"
                echo "  CPU: $cpu%"
            done

            # 获取运行时长
            if command -v ps &> /dev/null; then
                runtime=$(ps -p $PID -o etime --no-headers | tr -d ' ')
                echo "  运行时间: $runtime"
            fi
        else
            echo -e "${RED}✗${NC} 训练已停止 (PID 文件存在但进程不存在)"
        fi
    else
        echo -e "${YELLOW}○${NC} 训练未启动"
    fi

    echo ""
    echo "最新日志文件:"
    if [ -d "$LOG_DIR" ]; then
        latest_log=$(ls -t "$LOG_DIR"/train_*.log 2>/dev/null | head -1)
        if [ -n "$latest_log" ]; then
            echo "  $latest_log"
            echo ""
            echo "最近 5 行:"
            tail -5 "$latest_log"
        else
            echo "  无日志文件"
        fi
    fi
}

show_log() {
    if [ -d "$LOG_DIR" ]; then
        latest_log=$(ls -t "$LOG_DIR"/train_*.log 2>/dev/null | head -1)
        if [ -n "$latest_log" ]; then
            echo "跟踪日志: $latest_log"
            echo "按 Ctrl+C 退出"
            echo "------------------------------------------"
            tail -f "$latest_log"
        else
            echo "无日志文件"
        fi
    else
        echo "日志目录不存在"
    fi
}

show_gpu() {
    echo -e "${BLUE}>>> GPU 状态${NC}"
    echo "------------------------------------------"

    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu \
                   --format=csv,noheader,nounits | \
        awk -F', ' '{printf "GPU %s: %s\n  使用率: %s%% | 显存: %s/%s MB | 温度: %s°C\n", $1, $2, $3, $4, $5, $6}'
    else
        echo "nvidia-smi 不可用"
    fi
}

stop_train() {
    echo -e "${YELLOW}>>> 停止训练${NC}"
    echo "------------------------------------------"

    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if ps -p $PID > /dev/null 2>&1; then
            echo "正在停止进程 $PID..."
            kill $PID
            sleep 2
            if ps -p $PID > /dev/null 2>&1; then
                echo "强制终止..."
                kill -9 $PID
            fi
            echo -e "${GREEN}✓${NC} 训练已停止"
        else
            echo "进程已停止"
        fi
        rm -f "$PID_FILE"
    else
        echo "未找到 PID 文件"
    fi
}

restart_train() {
    echo -e "${YELLOW}>>> 重新启动训练${NC}"
    stop_train
    echo ""
    echo "启动新训练..."
    bash run_train.sh
}

# ============== 主逻辑 ==============
case "${1:-status}" in
    status)
        show_status
        ;;
    log)
        show_log
        ;;
    gpu)
        show_gpu
        ;;
    stop)
        stop_train
        ;;
    restart)
        restart_train
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
