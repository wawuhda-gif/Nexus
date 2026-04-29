#!/bin/bash

# ============================================================================
# SSH-PANEL-PRO v2.1 - Complete VPS Management Panel
# Supports: SSH, Dropbear, Stunnel, WebSocket, OpenVPN, V2Ray, ZiVPN, UDP Custom
# Features: Account Management, Auto-Expiry, Telegram Bot, Domain Management
# Binary Check: LENGKAP & VERIFIED
# Author: VPS Panel Team
# ============================================================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration paths
CONFIG_DIR="/etc/ssh-panel"
USERS_DB="$CONFIG_DIR/users.conf"
TELEGRAM_CONFIG="$CONFIG_DIR/telegram.conf"
DOMAIN_CONFIG="$CONFIG_DIR/domain.conf"
BINARY_CHECK="$CONFIG_DIR/binary-check.log"
LOG_FILE="/var/log/ssh-panel.log"
BACKUP_DIR="/var/backups/ssh-panel"

# Protocol ports
SSH_PORT=22
DROPBEAR_PORT=143
STUNNEL_PORT=443
WS_PORT=8080
OPENVPN_PORT=1194
V2RAY_PORT=10000
ZIVPN_PORT=7300
SQUID_PORT=3128

# ============================================================================
# BINARY & DEPENDENCY CHECK
# ============================================================================

check_system_arch() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        ARCH_NAME="AMD64"
    elif [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "armv8l" ]; then
        ARCH_NAME="ARMv7"
    elif [ "$ARCH" = "aarch64" ]; then
        ARCH_NAME="ARM64"
    else
        ARCH_NAME="$ARCH"
    fi
    echo "$ARCH_NAME"
}

# Comprehensive binary check
check_all_binaries() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}        BINARY & DEPENDENCY CHECK${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    > "$BINARY_CHECK"
    local missing_count=0
    
    # Check System Architecture
    echo -e "${BLUE}System Information:${NC}"
    echo "Architecture: $(check_system_arch)" | tee -a "$BINARY_CHECK"
    echo "OS: $(lsb_release -ds 2>/dev/null || echo 'Unknown')" | tee -a "$BINARY_CHECK"
    echo ""
    
    # Essential system tools
    local essential_bins=("curl" "wget" "openssl" "base64" "sed" "awk" "grep")
    echo -e "${YELLOW}Essential Tools:${NC}"
    for bin in "${essential_bins[@]}"; do
        if command -v "$bin" &> /dev/null; then
            echo -e "${GREEN}✓ $bin${NC}" | tee -a "$BINARY_CHECK"
        else
            echo -e "${RED}✗ $bin (MISSING)${NC}" | tee -a "$BINARY_CHECK"
            ((missing_count++))
        fi
    done
    echo ""
    
    # SSH/Access protocols
    local ssh_bins=("ssh" "sshd" "ssh-keygen" "dropbear" "dropbearkey")
    echo -e "${YELLOW}SSH/Access Protocols:${NC}"
    for bin in "${ssh_bins[@]}"; do
        if command -v "$bin" &> /dev/null; then
            echo -e "${GREEN}✓ $bin${NC}" | tee -a "$BINARY_CHECK"
        else
            echo -e "${YELLOW}⚠ $bin (NOT INSTALLED)${NC}" | tee -a "$BINARY_CHECK"
        fi
    done
    echo ""
    
    # VPN & Tunneling
    local vpn_bins=("openvpn" "stunnel4" "nginx" "squid" "socat")
    echo -e "${YELLOW}VPN & Tunneling:${NC}"
    for bin in "${vpn_bins[@]}"; do
        if command -v "$bin" &> /dev/null; then
            echo -e "${GREEN}✓ $bin${NC}" | tee -a "$BINARY_CHECK"
        else
            echo -e "${YELLOW}⚠ $bin (NOT INSTALLED)${NC}" | tee -a "$BINARY_CHECK"
        fi
    done
    echo ""
    
    # Advanced protocols
    local adv_bins=("v2ray" "xray")
    echo -e "${YELLOW}Advanced Protocols (V2Ray/Xray):${NC}"
    for bin in "${adv_bins[@]}"; do
        if command -v "$bin" &> /dev/null; then
            echo -e "${GREEN}✓ $bin${NC}" | tee -a "$BINARY_CHECK"
            break
        fi
    done
    if ! command -v "v2ray" &> /dev/null && ! command -v "xray" &> /dev/null; then
        echo -e "${YELLOW}⚠ V2Ray/Xray (NOT INSTALLED)${NC}" | tee -a "$BINARY_CHECK"
    fi
    echo ""
    
    # Database & SSL
    local db_bins=("certbot" "mysql" "sqlite3")
    echo -e "${YELLOW}Database & SSL:${NC}"
    for bin in "${db_bins[@]}"; do
        if command -v "$bin" &> /dev/null; then
            echo -e "${GREEN}✓ $bin${NC}" | tee -a "$BINARY_CHECK"
        else
            echo -e "${YELLOW}⚠ $bin (OPTIONAL)${NC}" | tee -a "$BINARY_CHECK"
        fi
    done
    echo ""
    
    # ZiVPN - Special check
    echo -e "${MAGENTA}ZiVPN (Zahid Islam Binary):${NC}"
    if [ -f "/usr/local/bin/zivpn" ] || [ -f "/usr/bin/zivpn" ] || command -v "zivpn" &> /dev/null; then
        echo -e "${GREEN}✓ ZiVPN binary found${NC}" | tee -a "$BINARY_CHECK"
        if command -v zivpn &> /dev/null; then
            echo "Path: $(which zivpn)" | tee -a "$BINARY_CHECK"
        fi
    else
        echo -e "${YELLOW}⚠ ZiVPN binary (NOT FOUND - Will install during setup)${NC}" | tee -a "$BINARY_CHECK"
    fi
    echo ""
    
    # Utility packages
    local util_bins=("htpasswd" "systemctl" "ufw" "iptables" "python3")
    echo -e "${YELLOW}Utility Packages:${NC}"
    for bin in "${util_bins[@]}"; do
        if command -v "$bin" &> /dev/null; then
            echo -e "${GREEN}✓ $bin${NC}" | tee -a "$BINARY_CHECK"
        else
            echo -e "${YELLOW}⚠ $bin (OPTIONAL)${NC}" | tee -a "$BINARY_CHECK"
        fi
    done
    echo ""
    
    echo -e "${YELLOW}Total Missing Critical: $missing_count${NC}"
    echo "Binary check log saved to: $BINARY_CHECK"
    echo ""
    
    if [ $missing_count -gt 0 ]; then
        read -p "Install missing binaries now? (yes/no): " install_choice
        if [ "$install_choice" = "yes" ]; then
            install_missing_binaries
        fi
    else
        echo -e "${GREEN}[✓] All critical binaries are installed!${NC}"
    fi
    
    sleep 3
}

install_missing_binaries() {
    echo -e "${BLUE}[*] Installing missing binaries...${NC}"
    
    # Update package list
    apt-get update -qq
    
    # Essential packages
    local packages="curl wget openssl base64 openssh-server openssh-client dropbear dropbear-bin stunnel4 nginx squid3 openvpn easy-rsa certbot python3 python3-pip apache2-utils"
    
    echo -e "${YELLOW}[*] Installing packages: $packages${NC}"
    apt-get install -y $packages 2>&1 | tail -20
    
    # Install V2Ray
    echo -e "${YELLOW}[*] Installing V2Ray...${NC}"
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] V2Ray installed${NC}"
    else
        echo -e "${YELLOW}[*] V2Ray installation encountered issues, continuing...${NC}"
    fi
    
    echo -e "${GREEN}[✓] Missing binaries installation completed!${NC}"
    sleep 2
}

# Install ZiVPN (Zahid Islam Binary)
install_zivpn_binary() {
    echo -e "${BLUE}[*] Installing ZiVPN (Zahid Islam Binary)...${NC}"
    
    # Detect system architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        echo -e "${YELLOW}[*] Detected AMD64 architecture${NC}"
        ZIVPN_SCRIPT_URL="https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/zi.sh"
    elif [ "$ARCH" = "armv7l" ] || [ "$ARCH" = "aarch64" ]; then
        echo -e "${YELLOW}[*] Detected ARM architecture${NC}"
        ZIVPN_SCRIPT_URL="https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/zi2.sh"
    else
        echo -e "${RED}[✗] Unsupported architecture: $ARCH${NC}"
        return 1
    fi
    
    # Download and run ZiVPN installer
    cd /tmp
    wget -q -O zi_install.sh "$ZIVPN_SCRIPT_URL" 2>/dev/null
    if [ $? -eq 0 ]; then
        chmod +x zi_install.sh
        echo -e "${YELLOW}[*] Running ZiVPN installer...${NC}"
        bash zi_install.sh
        
        if [ $? -eq 0 ]; then
            log_action "ZiVPN installed successfully"
            echo -e "${GREEN}[✓] ZiVPN setup completed${NC}"
            echo "GitHub: https://github.com/zahidbd2/udp-zivpn" | tee -a "$BINARY_CHECK"
        else
            echo -e "${RED}[✗] ZiVPN installation failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}[✗] Failed to download ZiVPN installer${NC}"
        echo "URL: $ZIVPN_SCRIPT_URL"
        return 1
    fi
}

verify_zivpn_installation() {
    if [ -f "/usr/local/bin/zivpn" ] || [ -f "/usr/bin/zivpn" ] || command -v "zivpn" &> /dev/null; then
        return 0
    fi
    return 1
}

# ============================================================================
# INITIALIZATION & SETUP
# ============================================================================

setup_environment() {
    echo -e "${BLUE}[*] Initializing SSH-Panel environment...${NC}"
    
    # Create necessary directories
    mkdir -p "$CONFIG_DIR" "$BACKUP_DIR" "/var/log"
    
    # Initialize database files if they don't exist
    if [ ! -f "$USERS_DB" ]; then
        touch "$USERS_DB"
        chmod 600 "$USERS_DB"
        echo "# SSH Panel Users Database" > "$USERS_DB"
        echo "# Format: username|password|protocol|expiry|creation_date|bandwidth" >> "$USERS_DB"
    fi
    
    if [ ! -f "$TELEGRAM_CONFIG" ]; then
        touch "$TELEGRAM_CONFIG"
        chmod 600 "$TELEGRAM_CONFIG"
    fi
    
    if [ ! -f "$DOMAIN_CONFIG" ]; then
        touch "$DOMAIN_CONFIG"
        chmod 600 "$DOMAIN_CONFIG"
    fi
    
    # Create log file
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
    
    echo -e "${GREEN}[✓] Environment initialized${NC}"
}

log_action() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
    echo -e "${CYAN}[LOG] $message${NC}"
}

# ============================================================================
# USER MANAGEMENT FUNCTIONS
# ============================================================================

add_user() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}            ADD NEW USER${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "Enter username: " username
    
    # Check if user already exists
    if grep -q "^$username|" "$USERS_DB" 2>/dev/null; then
        echo -e "${RED}[✗] User $username already exists!${NC}"
        sleep 2
        return 1
    fi
    
    # Validate username
    if ! [[ "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}[✗] Invalid username format!${NC}"
        sleep 2
        return 1
    fi
    
    read -s -p "Enter password: " password
    echo ""
    read -s -p "Confirm password: " password_confirm
    echo ""
    
    if [ "$password" != "$password_confirm" ]; then
        echo -e "${RED}[✗] Passwords do not match!${NC}"
        sleep 2
        return 1
    fi
    
    if [ ${#password} -lt 6 ]; then
        echo -e "${RED}[✗] Password must be at least 6 characters!${NC}"
        sleep 2
        return 1
    fi
    
    echo ""
    echo -e "${YELLOW}Select Protocol:${NC}"
    echo "1) SSH"
    echo "2) Dropbear"
    echo "3) Stunnel"
    echo "4) WebSocket"
    echo "5) OpenVPN"
    echo "6) V2Ray"
    echo "7) ZiVPN (UDP)"
    echo "8) Squid Proxy"
    read -p "Select (1-8): " protocol_choice
    
    case $protocol_choice in
        1) protocol="SSH" ;;
        2) protocol="Dropbear" ;;
        3) protocol="Stunnel" ;;
        4) protocol="WebSocket" ;;
        5) protocol="OpenVPN" ;;
        6) protocol="V2Ray" ;;
        7) protocol="ZiVPN" ;;
        8) protocol="Squid" ;;
        *) echo -e "${RED}[✗] Invalid selection!${NC}"; sleep 2; return 1 ;;
    esac
    
    read -p "Enter expiry days (default: 30): " expiry_days
    expiry_days=${expiry_days:-30}
    
    if ! [[ "$expiry_days" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[✗] Expiry days must be a number!${NC}"
        sleep 2
        return 1
    fi
    
    # Calculate expiry date
    expiry_date=$(date -d "+$expiry_days days" '+%Y-%m-%d %H:%M:%S')
    creation_date=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create user based on protocol
    case $protocol in
        "SSH") create_ssh_user "$username" "$password" ;;
        "Dropbear") create_dropbear_user "$username" "$password" ;;
        "Stunnel") create_stunnel_config "$username" "$password" ;;
        "WebSocket") create_websocket_user "$username" "$password" ;;
        "OpenVPN") create_openvpn_user "$username" "$password" ;;
        "V2Ray") create_v2ray_user "$username" "$password" ;;
        "ZiVPN") create_zivpn_user "$username" "$password" ;;
        "Squid") create_squid_user "$username" "$password" ;;
    esac
    
    # Add to database
    echo "$username|$password|$protocol|$expiry_date|$creation_date|0" >> "$USERS_DB"
    
    log_action "User $username created with protocol $protocol, expires: $expiry_date"
    echo -e "${GREEN}[✓] User $username created successfully!${NC}"
    echo -e "${YELLOW}Expiry Date: $expiry_date${NC}"
    echo -e "${YELLOW}Protocol: $protocol${NC}"
    echo -e "${YELLOW}Port: $(get_protocol_port "$protocol")${NC}"
    
    # Send Telegram notification
    send_telegram_notification "✅ NEW USER\nUsername: $username\nProtocol: $protocol\nExpiry: $expiry_date\nServer IP: $(get_server_ip)"
    
    sleep 3
}

get_protocol_port() {
    case $1 in
        "SSH") echo "$SSH_PORT" ;;
        "Dropbear") echo "$DROPBEAR_PORT" ;;
        "Stunnel") echo "$STUNNEL_PORT" ;;
        "WebSocket") echo "$WS_PORT" ;;
        "OpenVPN") echo "$OPENVPN_PORT" ;;
        "V2Ray") echo "$V2RAY_PORT" ;;
        "ZiVPN") echo "$ZIVPN_PORT" ;;
        "Squid") echo "$SQUID_PORT" ;;
        *) echo "Unknown" ;;
    esac
}

create_ssh_user() {
    local username="$1"
    local password="$2"
    
    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash "$username" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "$username:$password" | chpasswd
            usermod -aG sudo "$username" 2>/dev/null
            echo -e "${GREEN}[✓] SSH user created${NC}"
        else
            echo -e "${RED}[✗] Failed to create SSH user${NC}"
            return 1
        fi
    else
        echo "$username:$password" | chpasswd
        echo -e "${YELLOW}[*] SSH user already exists, password updated${NC}"
    fi
}

create_dropbear_user() {
    local username="$1"
    local password="$2"
    
    create_ssh_user "$username" "$password"
    
    mkdir -p /home/$username/.ssh
    ssh-keygen -t rsa -N "" -f /home/$username/.ssh/id_rsa >/dev/null 2>&1
    chmod 700 /home/$username/.ssh
    chmod 600 /home/$username/.ssh/id_rsa
    chown -R $username:$username /home/$username/.ssh
    
    echo -e "${GREEN}[✓] Dropbear user created${NC}"
}

create_stunnel_config() {
    local username="$1"
    local password="$2"
    
    create_ssh_user "$username" "$password"
    
    local stunnel_conf="/etc/stunnel/stunnel-$username.conf"
    
    cat > "$stunnel_conf" <<EOF
; Stunnel configuration for $username
[global]
debug = 0
pid = /var/run/stunnel/stunnel-$username.pid

[https-$username]
accept = $STUNNEL_PORT
connect = $SSH_PORT
cert = /etc/stunnel/stunnel.pem
EOF
    
    chmod 600 "$stunnel_conf"
    echo -e "${GREEN}[✓] Stunnel config created${NC}"
}

create_websocket_user() {
    local username="$1"
    local password="$2"
    
    create_ssh_user "$username" "$password"
    
    local ws_conf="/etc/ssh-panel/ws-$username.conf"
    
    cat > "$ws_conf" <<EOF
{
  \"username\": \"$username\",
  \"password\": \"$password\",
  \"protocol\": \"websocket\",
  \"port\": $WS_PORT,
  \"created\": \"$(date '+%s')\"
}
EOF
    
    chmod 600 "$ws_conf"
    echo -e "${GREEN}[✓] WebSocket user created${NC}"
}

create_openvpn_user() {
    local username="$1"
    local password="$2"
    
    if [ ! -d "/etc/openvpn/easy-rsa" ]; then
        echo -e "${RED}[✗] OpenVPN not properly configured${NC}"
        return 1
    fi
    
    local ovpn_conf="/etc/openvpn/$username.ovpn"
    cat > "$ovpn_conf" <<EOF
client
proto udp
remote $(get_server_ip) $OPENVPN_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
cipher AES-128-CBC
auth SHA1
comp-lzo
verb 3
EOF
    
    chmod 600 "$ovpn_conf"
    echo -e "${GREEN}[✓] OpenVPN user created${NC}"
}

create_v2ray_user() {
    local username="$1"
    local password="$2"
    
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    local v2ray_conf="/etc/v2ray/vmess-$username.json"
    
    cat > "$v2ray_conf" <<EOF
{
  \"inbound\": {
    \"port\": $V2RAY_PORT,
    \"protocol\": \"vmess\",
    \"settings\": {
      \"clients\": [
        {
          \"id\": \"$uuid\",
          \"alterId\": 64,
          \"email\": \"$username@panel\"
        }
      ]
    }
  }
}
EOF
    
    chmod 600 "$v2ray_conf"
    echo -e "${GREEN}[✓] V2Ray user created with UUID: $uuid${NC}"
}

create_zivpn_user() {
    local username="$1"
    local password="$2"
    
    local zivpn_conf="/etc/ssh-panel/zivpn-$username.conf"
    
    cat > "$zivpn_conf" <<EOF
[ZiVPN Configuration]
Username=$username
Password=$password
Protocol=UDP
Port=$ZIVPN_PORT
Created=$(date '+%s')
BinaryVersion=Zahid-Islam
GitHub=https://github.com/zahidbd2/udp-zivpn
EOF
    
    chmod 600 "$zivpn_conf"
    log_action "ZiVPN user $username created"
    echo -e "${GREEN}[✓] ZiVPN user created${NC}"
}

create_squid_user() {
    local username="$1"
    local password="$2"
    
    htpasswd -bc /etc/squid/passwd "$username" "$password" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        systemctl reload squid >/dev/null 2>&1
        echo -e "${GREEN}[✓] Squid user created${NC}"
    else
        echo -e "${RED}[✗] Failed to create Squid user${NC}"
        return 1
    fi
}

delete_user() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${RED}            DELETE USER${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "Enter username to delete: " username
    
    if ! grep -q "^$username|" "$USERS_DB" 2>/dev/null; then
        echo -e "${RED}[✗] User $username not found!${NC}"
        sleep 2
        return 1
    fi
    
    protocol=$(grep "^$username|" "$USERS_DB" | cut -d'|' -f3)
    
    echo -e "${YELLOW}[!] User: $username | Protocol: $protocol${NC}"
    read -p "Are you sure you want to delete this user? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}[*] Deletion cancelled${NC}"
        sleep 2
        return 0
    fi
    
    case $protocol in
        "SSH"|"Dropbear") userdel -r "$username" 2>/dev/null ;;
        "OpenVPN") rm -f /etc/openvpn/$username.ovpn ;;
        "Stunnel") rm -f /etc/stunnel/stunnel-$username.conf ;;
        "WebSocket"|"V2Ray"|"ZiVPN") rm -f /etc/ssh-panel/*-$username.conf ;;
        "Squid") htpasswd -D /etc/squid/passwd "$username" >/dev/null 2>&1; systemctl reload squid >/dev/null 2>&1 ;;
    esac
    
    sed -i "/^$username|/d" "$USERS_DB"
    
    log_action "User $username deleted"
    send_telegram_notification "🗑️ USER DELETED\nUsername: $username\nProtocol: $protocol"
    
    echo -e "${GREEN}[✓] User $username deleted successfully!${NC}"
    sleep 2
}

extend_user() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}            EXTEND USER EXPIRY${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "Enter username: " username
    
    if ! grep -q "^$username|" "$USERS_DB" 2>/dev/null; then
        echo -e "${RED}[✗] User $username not found!${NC}"
        sleep 2
        return 1
    fi
    
    current_expiry=$(grep "^$username|" "$USERS_DB" | cut -d'|' -f4)
    protocol=$(grep "^$username|" "$USERS_DB" | cut -d'|' -f3)
    
    echo -e "${YELLOW}Current Expiry: $current_expiry${NC}"
    read -p "Enter additional days to extend (default: 30): " extend_days
    extend_days=${extend_days:-30}
    
    if ! [[ "$extend_days" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[✗] Invalid number!${NC}"
        sleep 2
        return 1
    fi
    
    new_expiry=$(date -d "+$extend_days days" '+%Y-%m-%d %H:%M:%S')
    
    sed -i "/^$username|/c\\$username|$(grep "^$username|" "$USERS_DB" | cut -d'|' -f2)|$protocol|$new_expiry|$(grep "^$username|" "$USERS_DB" | cut -d'|' -f5)|$(grep "^$username|" "$USERS_DB" | cut -d'|' -f6)" "$USERS_DB"
    
    log_action "User $username extended by $extend_days days, new expiry: $new_expiry"
    send_telegram_notification "⏱️ USER EXTENDED\nUsername: $username\nNew Expiry: $new_expiry"
    
    echo -e "${GREEN}[✓] User $username extended until: $new_expiry${NC}"
    sleep 2
}

list_users() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}            ACTIVE USERS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ ! -s "$USERS_DB" ] || [ $(grep -c "^[^#]" "$USERS_DB") -eq 0 ]; then
        echo -e "${YELLOW}[*] No users found${NC}"
        sleep 2
        return
    fi
    
    printf "%-15s %-15s %-12s %-20s\n" "Username" "Protocol" "Status" "Expiry"
    echo "─────────────────────────────────────────────────────────"
    
    grep "^[^#]" "$USERS_DB" | while IFS='|' read -r username password protocol expiry creation bandwidth; do
        current_date=$(date '+%Y-%m-%d %H:%M:%S')
        
        if [[ "$current_date" > "$expiry" ]]; then
            status="EXPIRED"
            status_color="${RED}"
        else
            status="ACTIVE"
            status_color="${GREEN}"
        fi
        
        printf "%-15s %-15s %-12s %-20s\n" "$username" "$protocol" "$status_color$status${NC}" "$expiry"
    done
    
    echo ""
    read -p "Press Enter to continue..."
}

check_expired_users() {
    local current_date=$(date '+%Y-%m-%d %H:%M:%S')
    local expired_count=0
    
    echo -e "${BLUE}[*] Checking for expired users...${NC}"
    
    grep "^[^#]" "$USERS_DB" | while IFS='|' read -r username password protocol expiry creation bandwidth; do
        if [[ "$current_date" > "$expiry" ]]; then
            echo -e "${RED}[EXPIRED] $username ($protocol)${NC}"
            ((expired_count++))
            log_action "User $username ($protocol) has expired"
            send_telegram_notification "⏰ USER EXPIRED\nUsername: $username\nProtocol: $protocol\nExpired Since: $expiry"
        fi
    done
    
    sleep 2
}

# ============================================================================
# TELEGRAM BOT & NOTIFICATIONS
# ============================================================================

setup_telegram() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}            TELEGRAM BOT SETUP${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Get your Telegram info:${NC}"
    echo "1. Create a bot: https://t.me/BotFather"
    echo "2. Get your Chat ID: https://t.me/userinfobot"
    echo ""
    
    read -p "Enter Telegram Bot Token: " bot_token
    read -p "Enter Telegram Chat ID: " chat_id
    
    if [ -z "$bot_token" ] || [ -z "$chat_id" ]; then
        echo -e "${RED}[✗] Invalid input!${NC}"
        sleep 2
        return 1
    fi
    
    cat > "$TELEGRAM_CONFIG" <<EOF
BOT_TOKEN=$bot_token
CHAT_ID=$chat_id
ENABLED=true
EOF
    
    chmod 600 "$TELEGRAM_CONFIG"
    
    test_telegram_bot
    
    log_action "Telegram bot configured"
    echo -e "${GREEN}[✓] Telegram bot configured successfully!${NC}"
    sleep 2
}

send_telegram_notification() {
    local message="$1"
    
    [ ! -f "$TELEGRAM_CONFIG" ] && return
    
    source "$TELEGRAM_CONFIG"
    
    [ "$ENABLED" != "true" ] || [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ] && return
    
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$message" \
        -d "parse_mode=HTML" > /dev/null 2>&1
}

test_telegram_bot() {
    source "$TELEGRAM_CONFIG"
    
    echo -e "${YELLOW}[*] Testing Telegram bot connection...${NC}"
    
    local response=$(curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=🤖 SSH Panel Bot Test - Configuration successful!" \
        -d "parse_mode=HTML")
    
    if echo "$response" | grep -q \"ok\":true; then
        echo -e "${GREEN}[✓] Telegram bot test successful!${NC}"
    else
        echo -e "${RED}[✗] Telegram bot test failed!${NC}"
    fi
}

# ============================================================================
# DOMAIN MANAGEMENT
# ============================================================================

setup_domain() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}            DOMAIN MANAGEMENT${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "Enter domain name: " domain
    read -p "Enter server IP: " server_ip
    
    if [ -z "$domain" ] || [ -z "$server_ip" ]; then
        echo -e "${RED}[✗] Invalid input!${NC}"
        sleep 2
        return 1
    fi
    
    if ! [[ "$server_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}[✗] Invalid IP address!${NC}"
        sleep 2
        return 1
    fi
    
    echo "$domain|$server_ip|$(date '+%Y-%m-%d %H:%M:%S')" >> "$DOMAIN_CONFIG"
    
    echo -e "${YELLOW}Domain: $domain${NC}"
    echo -e "${YELLOW}IP: $server_ip${NC}"
    echo -e "${GREEN}[✓] Domain configured successfully!${NC}"
    
    setup_ssl_certificate "$domain"
    
    log_action "Domain $domain added pointing to $server_ip"
    sleep 2
}

setup_ssl_certificate() {
    local domain="$1"
    
    echo -e "${YELLOW}[*] Setting up SSL certificate for $domain...${NC}"
    
    if command -v certbot &> /dev/null; then
        sudo certbot certonly --standalone -d "$domain" --non-interactive --agree-tos -m admin@$domain 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[✓] SSL certificate installed for $domain${NC}"
            log_action "SSL certificate installed for $domain"
        else
            echo -e "${YELLOW}[*] SSL setup skipped (domain may need manual verification)${NC}"
        fi
    else
        echo -e "${YELLOW}[*] Certbot not installed, installing...${NC}"
        apt-get install -y certbot >/dev/null 2>&1
        setup_ssl_certificate "$domain"
    fi
}

list_domains() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}            CONFIGURED DOMAINS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ ! -s "$DOMAIN_CONFIG" ]; then
        echo -e "${YELLOW}[*] No domains configured${NC}"
        sleep 2
        return
    fi
    
    printf "%-20s %-15s %-20s\n" "Domain" "IP Address" "Added Date"
    echo "─────────────────────────────────────────────────────────"
    
    while IFS='|' read -r domain ip date; do
        printf "%-20s %-15s %-20s\n" "$domain" "$ip" "$date"
    done < "$DOMAIN_CONFIG"
    
    echo ""
    read -p "Press Enter to continue..."
}

# ============================================================================
# MONITORING & SYSTEM INFO
# ============================================================================

system_status() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}            SYSTEM STATUS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${BLUE}Server Information:${NC}"
    echo "Hostname: $(hostname)"
    echo "IP Address: $(get_server_ip)"
    echo "OS: $(lsb_release -ds 2>/dev/null || echo 'Unknown')"
    echo "Kernel: $(uname -r)"
    echo ""
    
    echo -e "${BLUE}CPU Information:${NC}"
    echo "Cores: $(nproc)"
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "Usage: ${cpu_usage}%"
    echo ""
    
    echo -e "${BLUE}Memory Information:${NC}"
    free -h | tail -2
    echo ""
    
    echo -e "${BLUE}Disk Information:${NC}"
    df -h / | tail -1
    echo ""
    
    echo -e "${BLUE}User Statistics:${NC}"
    total_users=$(grep -c "^[^#]" "$USERS_DB" 2>/dev/null || echo 0)
    active_users=$(grep "^[^#]" "$USERS_DB" 2>/dev/null | while IFS='|' read -r u p pr e c b; do
        [ "$(date '+%Y-%m-%d %H:%M:%S')" \< "$e" ] && echo "1"
    done | wc -l)
    expired_users=$((total_users - active_users))
    
    echo "Total Users: $total_users"
    echo "Active Users: $active_users"
    echo "Expired Users: $expired_users"
    echo ""
    
    echo -e "${BLUE}Service Status:${NC}"
    check_service_status "ssh"
    check_service_status "dropbear" 2>/dev/null
    check_service_status "openvpn" 2>/dev/null
    check_service_status "v2ray" 2>/dev/null
    check_service_status "nginx" 2>/dev/null
    echo ""
    
    read -p "Press Enter to continue..."
}

check_service_status() {
    local service="$1"
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${service}: ${GREEN}✓ Running${NC}"
    else
        echo -e "${service}: ${RED}✗ Stopped${NC}"
    fi
}

get_server_ip() {
    hostname -I | awk '{print $1}'
}

# ============================================================================
# BACKUP & RESTORE
# ============================================================================

backup_data() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}            BACKUP DATA${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    local backup_file="$BACKUP_DIR/ssh-panel-backup-$(date '+%Y%m%d-%H%M%S').tar.gz"
    
    echo -e "${YELLOW}[*] Creating backup...${NC}"
    
    tar -czf "$backup_file" "$CONFIG_DIR" "$LOG_FILE" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Backup created: $backup_file${NC}"
        echo "Size: $(du -h "$backup_file" | cut -f1)"
        log_action "Backup created: $backup_file"
    else
        echo -e "${RED}[✗] Backup failed!${NC}"
    fi
    
    sleep 2
}

restore_backup() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}            RESTORE BACKUP${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | nl
    
    read -p "Enter backup number to restore (or 0 to cancel): " backup_num
    
    [ "$backup_num" = "0" ] && return
    
    backup_file=$(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | sed -n "${backup_num}p")
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}[✗] Invalid selection!${NC}"
        sleep 2
        return 1
    fi
    
    read -p "Restore from $backup_file? (yes/no): " confirm
    
    [ "$confirm" != "yes" ] && return
    
    echo -e "${YELLOW}[*] Restoring backup...${NC}"
    tar -xzf "$backup_file" -C / 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[✓] Backup restored successfully!${NC}"
        log_action "Backup restored from: $backup_file"
    else
        echo -e "${RED}[✗] Restore failed!${NC}"
    fi
    
    sleep 2
}

# ============================================================================
# PROTOCOL MANAGEMENT
# ============================================================================

install_all_protocols() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}            PROTOCOL INSTALLATION${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    
    local protocols=("openssh-server" "dropbear" "openssl" "openvpn" "nginx" "squid" "stunnel4")
    
    for protocol in "${protocols[@]}"; do
        echo -e "${YELLOW}[*] Installing $protocol...${NC}"
        apt-get install -y "$protocol" >/dev/null 2>&1 && echo -e "${GREEN}[✓] $protocol installed${NC}" || echo -e "${YELLOW}[*] $protocol skipped${NC}"
    done
    
    echo -e "${YELLOW}[*] Installing V2Ray...${NC}"
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) >/dev/null 2>&1
    
    echo -e "${YELLOW}[*] Installing ZiVPN...${NC}"
    install_zivpn_binary
    
    echo -e "${GREEN}[✓] All protocols installed successfully!${NC}"
    log_action "All protocols installed"
    
    sleep 3
}

manage_protocols() {
    while true; do
        clear
        echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}            PROTOCOL MANAGEMENT${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
        echo ""
        echo "1) Install all protocols"
        echo "2) Start service"
        echo "3) Stop service"
        echo "4) Restart service"
        echo "5) Check service status"
        echo "6) Back to main menu"
        echo ""
        read -p "Select option (1-6): " choice
        
        case $choice in
            1) install_all_protocols ;;
            2) 
                read -p "Enter service name: " service
                systemctl start "$service" && echo -e "${GREEN}[✓] $service started${NC}" || echo -e "${RED}[✗] Failed to start $service${NC}"
                sleep 2
                ;;
            3)
                read -p "Enter service name: " service
                systemctl stop "$service" && echo -e "${GREEN}[✓] $service stopped${NC}" || echo -e "${RED}[✗] Failed to stop $service${NC}"
                sleep 2
                ;;
            4)
                read -p "Enter service name: " service
                systemctl restart "$service" && echo -e "${GREEN}[✓] $service restarted${NC}" || echo -e "${RED}[✗] Failed to restart $service${NC}"
                sleep 2
                ;;
            5)
                read -p "Enter service name: " service
                systemctl status "$service" --no-pager
                sleep 2
                ;;
            6) return ;;
            *) echo -e "${RED}[✗] Invalid selection!${NC}"; sleep 2 ;;
        esac
    done
}

# ============================================================================
# MAIN MENU
# ============================================================================

show_main_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}    ${BLUE}SSH-PANEL-PRO v2.1 - VPS Management System${NC}    ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}           ${YELLOW}All Protocols & ZiVPN Ready${NC}           ${CYAN}║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}┌─ USER MANAGEMENT ─────────────────────────────────────┐${NC}"
        echo -e "${YELLOW}│${NC} 1)  Add New User                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC} 2)  Delete User                                     ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC} 3)  Extend User Expiry                              ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC} 4)  List All Users                                  ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC} 5)  Check Expired Users                             ${YELLOW}│${NC}"
        echo -e "${YELLOW}└────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -e "${GREEN}┌─ SYSTEM MANAGEMENT ────────────────────────────────────┐${NC}"
        echo -e "${GREEN}│${NC} 6)  System Status & Monitoring                     ${GREEN}│${NC}"
        echo -e "${GREEN}│${NC} 7)  Protocol Management                            ${GREEN}│${NC}"
        echo -e "${GREEN}│${NC} 8)  Domain Management                              ${GREEN}│${NC}"
        echo -e "${GREEN}│${NC} 9)  Telegram Bot Setup                             ${GREEN}│${NC}"
        echo -e "${GREEN}└────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -e "${BLUE}┌─ BACKUP & MAINTENANCE ─────────────────────────────────┐${NC}"
        echo -e "${BLUE}│${NC} 10) Backup System                                  ${BLUE}│${NC}"
        echo -e "${BLUE}│${NC} 11) Restore Backup                                 ${BLUE}│${NC}"
        echo -e "${BLUE}│${NC} 12) View System Logs                               ${BLUE}│${NC}"
        echo -e "${BLUE}│${NC} 13) Binary & Dependency Check                      ${BLUE}│${NC}"
        echo -e "${BLUE}└────────────────────────────────────────────────────────┘${NC}"
        echo ""
        echo -e "${RED}┌─ OTHER ───────────────────────────────────────────────────┐${NC}"
        echo -e "${RED}│${NC} 14) Settings                                         ${RED}│${NC}"
        echo -e "${RED}│${NC} 0)  Exit${RED}                                          ${RED}│${NC}"
        echo -e "${RED}└────────────────────────────────────────────────────────┘${NC}"
        echo ""
        read -p "Select option (0-14): " menu_choice
        
        case $menu_choice in
            1) add_user ;;
            2) delete_user ;;
            3) extend_user ;;
            4) list_users ;;
            5) check_expired_users ;;
            6) system_status ;;
            7) manage_protocols ;;
            8) setup_domain; sleep 2 ;;
            9) setup_telegram ;;
            10) backup_data ;;
            11) restore_backup ;;
            12) less "$LOG_FILE" ;;
            13) check_all_binaries ;;
            14) settings_menu ;;
            0) 
                echo -e "${YELLOW}[*] Thank you for using SSH-Panel-Pro!${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}[✗] Invalid selection!${NC}"
                sleep 2
                ;;
        esac
    done
}

settings_menu() {
    while true; do
        clear
        echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}            SETTINGS${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
        echo ""
        echo "1) Change SSH port"
        echo "2) Enable/Disable Telegram notifications"
        echo "3) Edit user database"
        echo "4) Clear logs"
        echo "5) Install ZiVPN Binary"
        echo "6) Back to main menu"
        echo ""
        read -p "Select option (1-6): " choice
        
        case $choice in
            1)
                read -p "Enter new SSH port: " new_port
                if [[ "$new_port" =~ ^[0-9]+$ ]]; then
                    sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config
                    systemctl restart ssh
                    echo -e "${GREEN}[✓] SSH port changed to $new_port${NC}"
                    log_action "SSH port changed to $new_port"
                else
                    echo -e "${RED}[✗] Invalid port number!${NC}"
                fi
                sleep 2
                ;;
            2)
                if [ -f "$TELEGRAM_CONFIG" ]; then
                    source "$TELEGRAM_CONFIG"
                    if [ "$ENABLED" = "true" ]; then
                        sed -i 's/ENABLED=.*/ENABLED=false/' "$TELEGRAM_CONFIG"
                        echo -e "${YELLOW}[*] Telegram notifications disabled${NC}"
                    else
                        sed -i 's/ENABLED=.*/ENABLED=true/' "$TELEGRAM_CONFIG"
                        echo -e "${GREEN}[✓] Telegram notifications enabled${NC}"
                    fi
                    log_action "Telegram notification status changed"
                else
                    echo -e "${YELLOW}[*] Telegram not configured yet${NC}"
                fi
                sleep 2
                ;;
            3)
                nano "$USERS_DB"
                log_action "User database edited manually"
                ;;
            4)
                read -p "Clear all logs? (yes/no): " confirm
                if [ "$confirm" = "yes" ]; then
                    > "$LOG_FILE"
                    echo -e "${GREEN}[✓] Logs cleared${NC}"
                fi
                sleep 2
                ;;
            5)
                install_zivpn_binary
                sleep 2
                ;;
            6) return ;;
            *) echo -e "${RED}[✗] Invalid selection!${NC}"; sleep 2 ;;
        esac
    done
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[✗] This script must be run as root!${NC}"
        exit 1
    fi
    
    setup_environment
    show_main_menu
}

main "$@"
