#!/bin/bash

# ProxySBX - Modern Proxy Deployment Script
# License: MIT
# Author: Open Source Community

# --- Configuration Variables (Defaults) ---
PORT=${PORT:-443}
UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
# A safe fallback SNI for Reality (mimics Microsoft traffic)
DEST_HOST=${DEST_HOST:-"www.microsoft.com"} 
DEST_PORT=${DEST_PORT:-443}
# Protocol choice: reality, hysteria2, tuic
PROTOCOL=${PROTOCOL:-"reality"} 

# --- Colors & formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Helper Functions ---
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root.${NC}" 
        exit 1
    fi
}

install_dependencies() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update -y && apt-get install -y curl jq openssl
    elif command -v yum &> /dev/null; then
        yum update -y && yum install -y curl jq openssl
    elif command -v apk &> /dev/null; then
        apk add curl jq openssl
    else
        echo -e "${RED}Unsupported package manager.${NC}"
        exit 1
    fi
}

get_singbox() {
    echo -e "${YELLOW}Downloading latest Sing-box core...${NC}"
    # Fetch latest release tag from GitHub API
    LATEST_VER=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | jq -r .tag_name)
    if [[ -z "$LATEST_VER" || "$LATEST_VER" == "null" ]]; then
        echo -e "${RED}Failed to fetch version. Using fallback.${NC}"
        LATEST_VER="v1.8.0" # Fallback version
    fi
    
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) SB_ARCH="amd64" ;;
        aarch64) SB_ARCH="arm64" ;;
        *) echo -e "${RED}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
    esac

    URL="https://github.com/SagerNet/sing-box/releases/download/${LATEST_VER}/sing-box-${LATEST_VER#v}-linux-${SB_ARCH}.tar.gz"
    
    curl -L -o sing-box.tar.gz "$URL"
    tar -xzf sing-box.tar.gz
    mv sing-box-*/sing-box /usr/local/bin/
    chmod +x /usr/local/bin/sing-box
    rm -rf sing-box.tar.gz sing-box-*
}

generate_keys() {
    # Generate X25519 keys for Reality/Hysteria
    KEYS=$(/usr/local/bin/sing-box generate reality-keypair)
    PRIVATE_KEY=$(echo "$KEYS" | grep "PrivateKey" | awk '{print $2}')
    PUBLIC_KEY=$(echo "$KEYS" | grep "PublicKey" | awk '{print $2}')
    SHORT_ID=$(openssl rand -hex 8)
}

generate_config() {
    mkdir -p /etc/sing-box
    cat <<EOF > /etc/sing-box/config.json
{
  "log": {
    "level": "warn",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": $PORT,
      "users": [
        {
          "uuid": "$UUID",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "$DEST_HOST",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "$DEST_HOST",
            "server_port": $DEST_PORT
          },
          "private_key": "$PRIVATE_KEY",
          "short_id": [
            "$SHORT_ID"
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ]
}
EOF
}

setup_systemd() {
    cat <<EOF > /etc/systemd/system/sing-box.service
[Unit]
Description=Sing-box Proxy Service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
User=root
WorkingDirectory=/usr/local/bin
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
RestartSec=10
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable sing-box
    systemctl restart sing-box
}

print_info() {
    echo -e "\n${GREEN}=== ProxySBX Installation Complete ===${NC}"
    echo -e "Core: Sing-box (${LATEST_VER})"
    echo -e "Protocol: VLESS-Reality (Vision)"
    echo -e "Port: $PORT"
    echo -e "UUID: $UUID"
    echo -e "SNI: $DEST_HOST"
    echo -e "Public Key: $PUBLIC_KEY"
    echo -e "Short ID: $SHORT_ID"
    echo -e "\n${YELLOW}Client Link (VLESS):${NC}"
    echo "vless://$UUID@<YOUR_IP>:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$DEST_HOST&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&headerType=none#ProxySBX-Reality"
    echo -e "\n${RED}NOTE: Replace <YOUR_IP> with your VPS Public IP.${NC}"
}

# --- Main Execution ---
check_root
install_dependencies
get_singbox
generate_keys
generate_config
setup_systemd
print_info
