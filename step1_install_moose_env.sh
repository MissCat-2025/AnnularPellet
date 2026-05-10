#!/bin/bash
# 先运行chmod +x step1_install_moose_env.sh
# 安装MOOSE环境的脚本

echo "===== 开始安装MOOSE环境 ====="

# 检查miniforge文件夹是否已存在
if [ -d "$HOME/miniforge" ]; then
    echo "miniforge文件夹已存在，跳过下载和解压步骤..."
else
    # 检查Miniforge3安装包是否已存在
    if [ -f "Miniforge3-Linux-x86_64.sh" ]; then
        echo "Miniforge3安装包已存在，跳过下载步骤..."
    else
        # 下载Miniforge3
        echo "正在下载Miniforge3...,如果太慢，就直接用浏览器去官网https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh下载，注意下载好后放入当前目录"
        curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
    fi

    # 解压Miniforge3
    echo "正在解压Miniforge3..."
    bash Miniforge3-Linux-x86_64.sh -b -p ~/miniforge
fi

# 导出环境路径
echo "正在设置环境路径..."
export PATH=$HOME/miniforge/bin:$PATH

# 初始化conda
echo "正在初始化conda环境..."
conda init --all

# 更新python环境
echo "正在更新Python环境..."
conda update --all --yes


# 检查moose环境是否已存在
if conda env list | grep -q "moose"; then
    echo "moose环境已存在，跳过安装步骤..."
    moose_version="已安装"
else
    # 添加MOOSE通道
    echo "正在添加MOOSE通道..."
    conda config --add channels https://conda.software.inl.gov/public

    # 提示用户确认MOOSE版本
    printf '\033[1;31m%s\033[0m\n' "============================================================"
    printf '\033[1;31m%s\033[0m\n' "【重要】请先访问官网查看最新的 MOOSE 版本，再继续安装。"
    printf '\033[1;31m%s\033[0m\n' "官网地址："
    printf '\033[1;31m%s\033[0m\n' "https://mooseframework.inl.gov/getting_started/installation/conda.html"
    printf '\033[1;31m%s\033[0m\n' "请以 Install MOOSE 部分公布的最新版本为准，不要直接照搬脚本中的默认值。"
    printf '\033[1;31m%s\033[0m\n' "============================================================"

    echo "默认版本为2025.10.27，请一定使用官网最新版本，请输入最新版本号(格式为xxxx.xx.xx)："
    read -p "默认MOOSE版本: [2025.10.27]: " moose_version
    moose_version=${moose_version:-2025.10.27}

    # 安装MOOSE环境
    echo "正在安装MOOSE环境 (版本: $moose_version)..."
    conda create -y -n moose moose-dev=$moose_version=mpich
fi

# 激活MOOSE环境
echo "正在激活MOOSE环境..."
conda activate moose
echo "===== MOOSE环境安装完成 ====="
echo "每次使用MOOSE前，请先运行: conda activate moose"
echo "注意：这只是MOOSE的运行环境，您还需要下载并编译MOOSE软件本身" 