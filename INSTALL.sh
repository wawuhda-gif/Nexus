#!/bin/bash

# Enhanced INSTALL.sh with Auto-Login Menu Setup
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/wawuhda-gif/Nexus/main/INSTALL.sh)

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

echo -e "\033[0;33m[*] Setting up auto-login menu...\033[0m"
# Download login menu
curl -fsSL -o /usr/local/bin/ssh-panel-login https://raw.githubusercontent.com/wawuhda-gif/Nexus/main/login-menu.sh 2>/dev/null
chmod +x /usr/local/bin/ssh-panel-login

# Add to /etc/profile for all users
if ! grep -q "ssh-panel-login" /etc/profile; then
    cat >> /etc/profile <<'EOF'

# SSH-Panel-Pro Auto-Login Menu
if [ -f /usr/local/bin/ssh-panel-login ] && [ -z "$SSH_ORIGINAL_COMMAND" ]; then
    /usr/local/bin/ssh-panel-login
fi
EOF
fi
echo -e "\033[0;32m[✓] Auto-login menu configured\033[0m"

echo ""
echo -e "\033[0;36m╔════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[0;36m║              INSTALLATION COMPLETE!                         ║\033[0m"
echo -e "\033[0;36m╚════════════════════════════════════════════════════════════╝\033[0m"
echo ""

echo -e "\033[1;32m✓ SSH-Panel-Pro is ready to use!\033[0m"
echo ""
echo -e "\033[1;33m✨ Features Installed:\033[0m"
echo "  ✓ Main Control Panel"
echo "  ✓ Auto-Login Menu (shows on SSH login)"
echo "  ✓ All Protocol Support (SSH, Dropbear, VPN, etc)"
echo "  ✓ ZiVPN Support (Zahid Islam Binary)"
echo "  ✓ Telegram Bot Integration"
echo "  ✓ Domain Management with SSL"
echo ""
echo -e "\033[1;33mAvailable Commands:\033[0m"
echo "  • \033[1;36mssh-panel-pro\033[0m - Open main panel"
echo "  • \033[1;36mssh-panel-login\033[0m - Show login menu"
echo ""
echo -e "\033[1;33mNext Steps:\033[0m"
echo "  1. Next time you SSH login, auto-menu will appear"
echo "  2. Or run 'ssh-panel-pro' to open manually"
echo "  3. Configure Telegram bot in the panel"
echo "  4. Add first user"
echo ""

read -p "Start SSH-Panel-Pro now? (yes/no): " start_choice
if [ "$start_choice" = "yes" ] || [ "$start_choice" = "y" ]; then
    /usr/local/bin/ssh-panel-pro
else
    echo -e "\033[0;33m[*] You can start it later with: ssh-panel-pro\033[0m"
    echo -e "\033[0;33m[*] Or just disconnect and SSH login again\033[0m"
fi
