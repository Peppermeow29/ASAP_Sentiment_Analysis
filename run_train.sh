#!/bin/bash
# ASAP Sentiment Analysis - 训练启动脚本

# ============== 配置区域 ==============
MODEL_NAME="ASAP_RoBERTa"
ROBERTA_PATH="hfl/chinese-roberta-wwm-ext"  # 或本地路径如 "/root/model/chinese-roberta-wwm-ext"
NUM_EPOCHS=15
BATCH_SIZE=16
LEARNING_RATE=2e-5
DEVICE="cuda"
LOG_DIR="logs"
SAVE_DIR="checkpoints"

# ============== 环境检查 ==============
echo "=========================================="
echo "ASAP 训练启动"
echo "=========================================="

# 检查 PyTorch 和 CUDA
python -c "import torch; assert torch.cuda.is_available(), 'CUDA 不可用'" || {
    echo "错误: 需要 CUDA 支持"
    exit 1
}

# 创建必要的目录
mkdir -p $LOG_DIR $SAVE_DIR

# ============== 生成日志文件名 ==============
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/train_${TIMESTAMP}.log"

echo "日志文件: $LOG_FILE"
echo "模型保存: $SAVE_DIR"
echo ""

# ============== 训练命令 ==============
CMD="python generation1/train.py \
    --roberta_path $ROBERTA_PATH \
    --num_epochs $NUM_EPOCHS \
    --batch_size $BATCH_SIZE \
    --lr $LEARNING_RATE \
    --device $DEVICE"

echo "执行命令:"
echo "$CMD"
echo ""

# ============== 开始训练 ==============
echo "=========================================="
echo "训练开始: $(date)"
echo "=========================================="

# 使用 nohup 后台运行，保留输出到日志
nohup $CMD > $LOG_FILE 2>&1 &

# 获取进程 ID
PID=$!
echo "进程 PID: $PID"

# 保存 PID 到文件
echo $PID > ${SAVE_DIR}/train.pid

# ============== 等待启动 ==============
sleep 3

# 检查进程是否正常运行
if ps -p $PID > /dev/null; then
    echo ""
    echo "✓ 训练已在后台启动"
    echo ""
    echo "监控命令:"
    echo "  查看日志: tail -f $LOG_FILE"
    echo "  查看 GPU: watch -n 1 nvidia-smi"
    echo "  停止训练: kill \$(cat ${SAVE_DIR}/train.pid)"
    echo ""
    echo "=========================================="

    # 显示最新日志
    echo ""
    echo "最新日志输出:"
    echo "------------------------------------------"
    tail -20 $LOG_FILE
else
    echo ""
    echo -e "${RED}错误: 训练进程启动失败${NC}"
    echo "请查看日志: $LOG_FILE"
    exit 1
fi
