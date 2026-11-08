#!/bin/sh
# Description: node-agent Service Manager

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Root check
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}This script must be run as root${NC}" 
   exit 1
fi

# 安装函数
install() {
    if [ -z "$1" ]; then 
        echo -e "${RED}Error: Token is required for installation${NC}"
        echo -e "Usage: $0 install <your_token>"
        exit 1
    fi
    
    TOKEN="$1"
    echo -e "${GREEN}Starting node-agent installation...${NC}"

    # 安装依赖
    # echo -e "${GREEN}Installing dependencies...${NC}"
    # apk update
    # apk add --no-cache libstdc++ libgcc icu-libs || {
    #     echo -e "${RED}Failed to install dependencies${NC}"
    #     exit 1
    # }

    # 创建目录
    echo -e "${GREEN}Creating directory...${NC}"
    mkdir -p /root/node-agent/ || {
        echo -e "${RED}Failed to create directory${NC}"
        exit 1
    }

    # 下载文件
    echo -e "${GREEN}Downloading node-agent client...${NC}"
    wget -P /root/node-agent/ https://raw.githubusercontent.com/Garfyyy/node-agent/main/cli || {
        echo -e "${RED}Failed to download cli${NC}"
        exit 1
    }

    # 切换目录并设置权限
    cd /root/node-agent/
    chmod 700 -R /root/node-agent/ || {
        echo -e "${RED}Failed to set permissions${NC}"
        exit 1
    }

    # 创建服务文件
    echo -e "${GREEN}Creating service file...${NC}"
    cat > /etc/init.d/node-agent << EOF
#!/sbin/openrc-run

supervisor=supervise-daemon
name="node-agent"
description="node-agent Service"
command="/root/node-agent/cli"
command_args="start accept --token ${TOKEN}"
directory="/root/node-agent"
supervise_daemon_args="--stdout /var/log/\${name}.log --stderr /var/log/\${name}.err"

EOF

    # 设置服务文件权限
    chmod +x /etc/init.d/node-agent || {
        echo -e "${RED}Failed to set service file permission${NC}"
        exit 1
    }

    # 添加到开机启动
    echo -e "${GREEN}Adding service to startup...${NC}"
    rc-update add node-agent default || {
        echo -e "${RED}Failed to add service to startup${NC}"
        exit 1
    }

    # # 启动服务
    # echo -e "${GREEN}Starting service...${NC}"
    # rc-service node-agent start
    # sleep 2
    # rc-service node-agent status

    # 启动服务
    echo -e "${GREEN}Starting service...${NC}"
    rc-service node-agent start || {
        echo -e "${RED}Failed to start service${NC}"
        exit 1
    }
    sleep 2
    # 检查服务状态
    rc-service node-agent status || {
        echo -e "${RED}Failed to check service status${NC}"
        exit 1
    }

    echo -e "${GREEN}Installation completed successfully${NC}"
    echo -e "Commands:"
    echo -e "  Start: rc-service node-agent start"
    echo -e "  Stop: rc-service node-agent stop"
    echo -e "  Restart: rc-service node-agent restart"
    echo -e "  Status: rc-service node-agent status"
}

# 卸载函数
uninstall() {
    echo -e "${GREEN}Starting node-agent uninstallation...${NC}"
    
    # 停止服务
    echo -e "Stopping service..."
    rc-service node-agent stop || true
    
    # 移除开机启动
    echo -e "Removing from startup..."
    rc-update del node-agent default || true
    
    # 删除文件
    echo -e "Removing files..."
    rm -rf /root/node-agent
    rm -f /etc/init.d/node-agent
    rm -f /var/log/node-agent.*
    
    # 删除依赖
    echo -e "Removing dependencies..."
    apk del libstdc++ libgcc icu-libs
    
    echo -e "${GREEN}Uninstallation completed successfully${NC}"
}

# 显示菜单
show_menu() {
    echo -e "Please select an option:"
    echo -e "1) Install node-agent"
    echo -e "2) Uninstall node-agent"
    echo -e "3) Exit"
    echo
    read -p "Enter your choice (1-3): " choice
}

# 获取token
get_token() {
    read -p "Please enter your token: " token
    if [ -z "$token" ]; then
        echo -e "${RED}Error: Token is required${NC}"
        exit 1
    fi
    echo -e "$token"
}

# 主循环
while true; do
    show_menu
    
    case $choice in
        1)
            token=$(get_token)
            install "$token"
            break
            ;;
        2)
            uninstall
            break
            ;;
        3)
            echo -e "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
done
