#!/bin/bash
# ASAP Sentiment Analysis - 服务器环境配置脚本
# 用于在远程服务器上自动配置训练环境

set -e  # 遇到错误立即退出

echo "=========================================="
echo "ASAP 训练环境配置脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查函数
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 已安装: $(which $1)"
    else
        echo -e "${RED}✗${NC} $1 未安装"
        return 1
    fi
}

echo ""
echo ">>> 1. 检查基础环境"
echo "------------------------------------------"

check_command python || { echo "请先安装 Python"; exit 1; }
check_command pip || { echo "请先安装 pip"; exit 1; }
check_command git || { echo "请先安装 git"; exit 1; }

# Python 版本检查
PYTHON_VERSION=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
echo "Python 版本: $PYTHON_VERSION"

if [[ $(echo "$PYTHON_VERSION" | cut -d. -f1) -lt 3 ]] || \
   [[ $(echo "$PYTHON_VERSION" | cut -d. -f1) -eq 3 && $(echo "$PYTHON_VERSION" | cut -d. -f2) -lt 8 ]]; then
    echo -e "${RED}错误: Python 版本需要 >= 3.8${NC}"
    exit 1
fi

echo ""
echo ">>> 2. 检查 GPU"
echo "------------------------------------------"

if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv
else
    echo -e "${YELLOW}警告: nvidia-smi 未找到，GPU 可能不可用${NC}"
fi

# 检查 CUDA
if python -c "import torch; print(torch.version.cuda)" 2>/dev/null; then
    echo "CUDA 版本: $(python -c 'import torch; print(torch.version.cuda)')"
else
    echo -e "${YELLOW}警告: PyTorch 未安装或不支持 CUDA${NC}"
fi

echo ""
echo ">>> 3. 检查/创建 conda 环境（可选）"
echo "------------------------------------------"

read -p "是否创建新的 conda 环境? (y/n, 默认n): " create_env
create_env=${create_env:-n}

if [[ "$create_env" == "y" || "$create_env" == "Y" ]]; then
    read -p "环境名称 (默认 asap): " env_name
    env_name=${env_name:-asap}

    echo "创建 conda 环境: $env_name"
    conda create -n $env_name python=3.10 -y
    source ~/.bashrc 2>/dev/null || true
    conda activate $env_name
    echo "已激活环境: $env_name"
fi

echo ""
echo ">>> 4. 安装 PyTorch"
echo "------------------------------------------"

# 检测 CUDA 版本
if command -v nvidia-smi &> /dev/null; then
    CUDA_VERSION=$(nvidia-smi -i 0 --query-gpu=driver_version --format=csv,noheader | cut -d. -f1)
    echo "Anthropic 驱动版本: $CUDA_VERSION"

    # RTX 4090 需要 CUDA 12.x
    echo "检测到 RTX 4090，使用 CUDA 12.x..."
    echo "安装 PyTorch 2.1.0 (CUDA 12.1)..."
    pip install torch==2.1.0 torchvision==0.16.0 --index-url https://download.pytorch.org/whl/cu121
else
    echo "未检测到 GPU，安装 CPU 版本..."
    pip install torch==2.2.0 torchvision==0.17.0
fi

echo ""
echo ">>> 5. 安装其他依赖"
echo "------------------------------------------"

pip install transformers==4.38.0
pip install pandas scikit-learn tqdm numpy
pip install tensorboard  # 可选，用于可视化

echo ""
echo ">>> 6. 验证安装"
echo "------------------------------------------"

python -c "
import torch
print(f'PyTorch: {torch.__version__}')
print(f'CUDA 可用: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU 数量: {torch.cuda.device_count()}')
    print(f'GPU 名称: {torch.cuda.get_device_name(0)}')
"

echo ""
echo "=========================================="
echo -e "${GREEN}环境配置完成!${NC}"
echo "=========================================="
echo ""
echo "下一步操作:"
echo "  1. 上传代码: scp -r ASAP_Sentiment_Analysis user@server:/path/"
echo "  2. 进入目录: cd ASAP_Sentiment_Analysis"
echo "  3. 运行训练: bash run_train.sh"
