#!/bin/bash

# SSH-Panel-Pro Auto-Launcher on Login
# Add this to ~/.bashrc or ~/.bash_profile

# Check if ssh-panel-pro is installed
if [ -f /usr/local/bin/ssh-panel-pro ]; then
    # Only show menu on interactive login (not on SCP/SFTP)
    if [ -z "$SSH_ORIGINAL_COMMAND" ] && [ "$-" = "*i*" ]; then
        # Show banner
        echo -e "\033[0;36m"
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║           Welcome to SSH-Panel-Pro Control Panel           ║"
        echo "║        VPS Management System - All Protocols Ready         ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo -e "\033[0m"
        
        # Show quick menu
        echo -e "\033[1;33mQuick Commands:\033[0m"
        echo "  1) Open SSH-Panel-Pro Menu"
        echo "  2) Exit to Shell"
        echo ""
        
        # Read choice with timeout
        read -t 15 -p "Choose (1-2) [default: 1, auto in 15s]: " quick_choice
        quick_choice=${quick_choice:-1}
        
        echo ""
        
        case $quick_choice in
            1)
                sudo /usr/local/bin/ssh-panel-pro
                ;;
            2)
                echo -e "\033[0;33m[*] You can run 'ssh-panel-pro' anytime\033[0m"
                ;;
            *)
                echo -e "\033[0;31m[*] Invalid choice, opening SSH-Panel-Pro...\033[0m"
                sleep 1
                sudo /usr/local/bin/ssh-panel-pro
                ;;
        esac
    fi
fi
