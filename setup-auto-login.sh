#!/bin/bash

# SSH-Panel-Pro Setup Auto-Login Menu
# This script adds the auto-login menu to ~/.bashrc

echo -e "\033[0;36m[*] Setting up auto-login menu...\033[0m"

# Get current user
CURRENT_USER=$(whoami)
BASHRC_FILE="/home/$CURRENT_USER/.bashrc"

if [ ! -f "$BASHRC_FILE" ]; then
    touch "$BASHRC_FILE"
    chmod 644 "$BASHRC_FILE"
fi

# Check if already added
if grep -q "SSH-Panel-Pro Auto-Launcher" "$BASHRC_FILE"; then
    echo -e "\033[0;33m[*] Auto-login menu already configured\033[0m"
    exit 0
fi

# Download bashrc addon
echo -e "\033[0;33m[*] Downloading auto-launcher script...\033[0m"
wget -q -O /tmp/bashrc-addon.sh https://raw.githubusercontent.com/wawuhda-gif/Nexus/main/bashrc-addon.sh

if [ -f /tmp/bashrc-addon.sh ]; then
    # Add to bashrc
    cat /tmp/bashrc-addon.sh >> "$BASHRC_FILE"
    rm /tmp/bashrc-addon.sh
    echo -e "\033[0;32m[✓] Auto-login menu added to ~/.bashrc\033[0m"
    echo -e "\033[0;33m[*] Changes will apply on next login\033[0m"
else
    echo -e "\033[0;31m[✗] Failed to download auto-launcher script\033[0m"
    exit 1
fi
