#!/bin/bash
notify() {
    termux-notification --id lindream_install --title "LinDream Installer" --content "$1"
}

progress_bar() {
    local progress=$1
    local total=100
    local width=40
    local filled=$((progress * width / total))
    local empty=$((width - filled))

    printf "\r["
    printf "%0.s#" $(seq 1 $filled)
    printf "%0.s-" $(seq 1 $empty)
    printf "] %d%%" "$progress"
}

# =============================
#         开始执行
# =============================
notify "开始安装 LinDream..."
echo "开始安装 LinDream..."

# -------- 0. 检查 termux-api --------
if ! command -v termux-notification >/dev/null 2>&1; then
    echo "正在安装 termux-api..."
    pkg install -y termux-api
fi
progress_bar 5
notify "Termux-API OK"

# -------- 1. 更新系统 --------
echo -e "\n更新系统中..."
pkg update -y && pkg upgrade -y
progress_bar 15
notify "系统更新完成"

# -------- 2. 安装 Git --------
if ! command -v git >/dev/null 2>&1; then
    echo "安装 Git..."
    pkg install -y git
fi
progress_bar 25
notify "Git 已准备"

# -------- 3. 克隆项目 --------
echo -e "\n克隆 LinDream 仓库..."
if [ ! -d "./LinDream" ]; then
    git clone http://github.fufumc.top/https://github.com/DXBbyd/LinDream.git
fi
cd LinDream || exit
progress_bar 40
notify "项目克隆完成"

# -------- 4. 安装 uv --------
if ! command -v uv >/dev/null 2>&1; then
    echo "安装 uv 包管理器..."
    pip install uv
fi
progress_bar 55
notify "uv 已安装"

# -------- 5. 创建虚拟环境 --------
echo -e "\n创建虚拟环境..."
uv venv
source .venv/bin/activate
progress_bar 70
notify "虚拟环境已激活"

# -------- 6. 安装依赖 --------
echo -e "\n安装依赖..."
uv pip install -r requirements.txt -i https://mirrors.aliyun.com/pypi/simple
progress_bar 90
notify "依赖安装完成"

# -------- 7. 完成 --------
progress_bar 100
notify "🎉 LinDream 安装成功！"

echo -e "\n================================="
echo "      LinDream 安装成功！"
echo "=================================\n"
echo "开始安装NapCat，进度将不在通知栏显示"
clear

MAGENTA='\033[0;1;35;95m'
RED='\033[0;1;31;91m'
GREEN='\033[0;1;32;92m'
NC='\033[0m'

execute_command() {
    echo -e "${2}中...${NC}"
    $1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$2 成功${NC}"
    else
        echo -e "${RED}$2 失败${NC}"
        exit 1
    fi
}

echo -e "准备proot-distro环境中..."
apt update -y && apt install -y proot-distro screen
if [ $? -eq 0 ]; then
    echo -e "${GREEN}准备proot-distro环境成功${NC}"
else
    pkg update -y && pkg install -y proot-distro screen
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}准备proot-distro环境成功${NC}"
    else
        echo -e "${RED}准备proot-distro环境失败${NC}"
        exit 1
    fi
fi

execute_command "proot-distro install debian --override-alias napcat" "安装napcat容器"

echo -e "${GREEN}正在初始化napcat容器...${NC}"
init_cmd="apt update -y && \
apt install -y sudo curl libgcrypt20 && \
curl -sSL http://github.fufumc.top/DXBbyd/LinDreamInstall/main/install.sh | sh&& \
sudo bash install.sh --docker n --cli n && \
apt autoremove -y && \
apt clean && \
rm -rf /tmp/* /var/lib/apt/lists"
proot-distro sh napcat -- bash -c "$init_cmd"
if [ $? -ne 0 ]; then
    proot-distro remove napcat
    echo -e "${RED}napcat容器初始化失败。${NC}"
    exit 1
fi
echo "每次启动请执行以下步骤："
echo
echo "1. 进入项目目录："
echo "   cd ~/LinDream"
echo
echo "2. 激活虚拟环境："
echo "   source .venv/bin/activate"
echo
echo "3. 启动主程序："
echo "   python main.py"
echo
echo -e "\n请输入${GREEN} proot-distro sh napcat -- bash -c \"xvfb-run -a /root/Napcat/opt/QQ/qq --no-sandbox\" ${NC}命令启动。"
echo -e "保持后台运行 请输入${GREEN} screen -dmS napcat bash -c 'proot-distro sh napcat -- bash -c \"xvfb-run -a /root/Napcat/opt/QQ/qq --no-sandbox\"'${NC}"
echo -e "后台快速登录 请输入${GREEN} screen -dmS napcat bash -c 'proot-distro sh napcat -- bash -c \"xvfb-run -a /root/Napcat/opt/QQ/qq --no-sandbox -q QQ号码\"'${NC}"
echo -e "进入容器内部 请输入${GREEN} proot-distro login napcat ${NC}"
echo -e "容器数据位置${MAGENTA} /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/napcat${NC}"
echo -e "Napcat安装位置(容器外真实路径)${MAGENTA} /data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/napcat/root/Napcat/opt/QQ/resources/app/app_launcher/napcat${NC}"
echo -e "注意, 您可以随时使用${GREEN}screen -r napcat${NC}来进入后台进程并使用${GREEN}ctrl + a + d${NC}离开(离开不会关闭后台进程)。"
echo -e "${GREEN}WEB_UI访问密钥请查看 Napcat安装位置/config/webui.json ${NC}"
echo "安装脚本运行完成"
