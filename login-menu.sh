#!/bin/bash

# SSH-Panel-Pro Login Handler
# Auto-trigger SSH-Panel-Pro menu on SSH login

echo -e "\033[0;36m"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           Welcome to SSH-Panel-Pro Control Panel           ║"
echo "║        VPS Management System - All Protocols Ready         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "\033[0m"
echo ""

echo -e "\033[1;32m✓ System Ready!\033[0m"
echo ""
echo -e "\033[1;33mServer Information:\033[0m"
echo "  Hostname: $(hostname)"
echo "  IP Address: $(hostname -I | awk '{print $1}')"
echo "  OS: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
echo "  Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

echo -e "\033[1;33mQuick Menu Options:\033[0m"
echo "  [1] Open SSH-Panel-Pro"
echo "  [2] View System Status"
echo "  [3] View Users"
echo "  [4] View Logs"
echo "  [5] Shell Menu"
echo ""

while true; do
    read -t 30 -p "Select option (1-5) [Auto: 1 in 30s]: " login_choice
    login_choice=${login_choice:-1}
    
    case $login_choice in
        1)
            echo ""
            sudo /usr/local/bin/ssh-panel-pro
            break
            ;;
        2)
            echo -e "\033[0;33m[*] System Status:\033[0m"
            echo "CPU Cores: $(nproc)"
            echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
            echo "Disk: $(df -h / | tail -1 | awk '{print $2, $3, $5}')"
            echo "Uptime: $(uptime -p)"
            echo ""
            ;;
        3)
            echo -e "\033[0;33m[*] Active Users:\033[0m"
            if [ -f /etc/ssh-panel/users.conf ]; then
                grep "^[^#]" /etc/ssh-panel/users.conf 2>/dev/null | wc -l
                echo "users configured"
            else
                echo "No users configured yet"
            fi
            echo ""
            ;;
        4)
            echo -e "\033[0;33m[*] Recent Logs (Last 10 lines):\033[0m"
            if [ -f /var/log/ssh-panel.log ]; then
                tail -10 /var/log/ssh-panel.log
            else
                echo "No logs available"
            fi
            echo ""
            ;;
        5)
            echo -e "\033[0;33m[*] Entering shell...\033[0m"
            break
            ;;
        *)
            echo ""
            echo -e "\033[0;31m[*] Invalid option, opening SSH-Panel-Pro...\033[0m"
            sleep 1
            sudo /usr/local/bin/ssh-panel-pro
            break
            ;;
    esac
done

echo -e "\033[0;33m[*] Type 'ssh-panel-pro' to open panel anytime\033[0m"
echo ""
