#!/bin/bash

# SSH-Panel-Pro Quick Installer (1-Line Command)
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/wawuhda-gif/Nexus/main/INSTALL.sh)
# Or: bash <(wget -O - https://raw.githubusercontent.com/wawuhda-gif/Nexus/main/INSTALL.sh)

set -e

echo -e "\033[0;36m"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     SSH-PANEL-PRO v2.1 - Auto Installer & Launcher       ║"
echo "║        All Protocols + ZiVPN (Zahid Islam Binary)         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"

echo -e "\033[0;33m[*] Checking root privileges...\033[0m"
if [ "$EUID" -ne 0 ]; then 
    echo -e "\033[0;31m[✗] This script must be run as root!\033[0m"
    echo "Run with: sudo bash <(curl -fsSL ...)"
    exit 1
fi
echo -e "\033[0;32m[✓] Running as root\033[0m"

echo -e "\033[0;33m[*] Detecting system architecture...\033[0m"
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_NAME="AMD64 (x86_64)"
elif [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "armv8l" ]; then
    ARCH_NAME="ARMv7"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH_NAME="ARM64 (aarch64)"
else
    ARCH_NAME="$ARCH"
fi
echo -e "\033[0;32m[✓] Architecture: $ARCH_NAME\033[0m"

echo -e "\033[0;33m[*] Downloading main script...\033[0m"
if command -v curl &> /dev/null; then
    curl -fsSL -o /usr/local/bin/ssh-panel-pro https://raw.githubusercontent.com/wawuhda-gif/Nexus/main/ssh-panel-pro.sh 2>/dev/null
elif command -v wget &> /dev/null; then
    wget -q -O /usr/local/bin/ssh-panel-pro https://raw.githubusercontent.com/wawuhda-gif/Nexus/main/ssh-panel-pro.sh 2>/dev/null
else
    echo -e "\033[0;31m[✗] curl or wget not found!\033[0m"
    exit 1
fi

if [ -f /usr/local/bin/ssh-panel-pro ]; then
    chmod +x /usr/local/bin/ssh-panel-pro
    echo -e "\033[0;32m[✓] Script downloaded successfully\033[0m"
else
    echo -e "\033[0;31m[✗] Failed to download script\033[0m"
    exit 1
fi

echo -e "\033[0;33m[*] Installing essential packages...\033[0m"
apt-get update -qq 2>/dev/null
apt-get install -y curl wget openssl >/dev/null 2>&1
echo -e "\033[0;32m[✓] Essential packages installed\033[0m"

echo ""
echo -e "\033[0;36m╔════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[0;36m║              INSTALLATION COMPLETE!                         ║\033[0m"
echo -e "\033[0;36m╚════════════════════════════════════════════════════════════╝\033[0m"
echo ""

echo -e "\033[1;32m✓ SSH-Panel-Pro is ready to use!\033[0m"
echo ""
echo "To start the panel, run:"
echo -e "  \033[1;36mssh-panel-pro\033[0m"
echo -e "  Or: \033[1;36msudo ssh-panel-pro\033[0m"
echo ""
echo "Quick commands:"
echo -e "  \033[1;33mManual run:\033[0m /usr/local/bin/ssh-panel-pro"
echo -e "  \033[1;33mHelp:\033[0m ssh-panel-pro --help"
echo ""

read -p "Start SSH-Panel-Pro now? (yes/no): " start_choice
if [ "$start_choice" = "yes" ] || [ "$start_choice" = "y" ]; then
    /usr/local/bin/ssh-panel-pro
else
    echo -e "\033[0;33m[*] You can start it later with: ssh-panel-pro\033[0m"
fi
