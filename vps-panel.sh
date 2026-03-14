#!/bin/bash
# ================================================================
#   VPS PANEL - ALL SSH + ALL UDP + SPEEDTEST
#   Oleh: Claude | Untuk Ubuntu 20.04 / 22.04 / Debian 10 / 11
# ================================================================
#  LAYANAN:
#   SSH  : OpenSSH (22), Dropbear (109,143), Websocket (80,8880)
#          SSH SSL/Stunnel4 (443,777), OHP SSH (6967)
#   UDP  : BadVPN-UDPGW (7100,7200,7300), ZIVPN UDP (5667)
#   PROXY: Squid (3128,8080)
#   EXTRA: Nginx, Speedtest, Info Akun, Monitoring
# ================================================================

# ── WARNA ───────────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m'
B='\033[0;34m' M='\033[0;35m' W='\033[1;37m' NC='\033[0m'
BOLD='\033[1m'

# ── DIREKTORI & FILE ─────────────────────────────────────────────
USERS_DB="/etc/vpn-panel/users.db"
LOG_FILE="/var/log/vpn-panel.log"
PANEL_DIR="/etc/vpn-panel"

# ── FUNGSI UMUM ──────────────────────────────────────────────────
check_root() {
    [[ $EUID -ne 0 ]] && echo -e "${R}[ERROR] Harus root!${NC}" && exit 1
}

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null; }

get_ip() {
    curl -s https://api.ipify.org 2>/dev/null || \
    curl -s https://checkip.amazonaws.com 2>/dev/null | tr -d '\n' || \
    hostname -I | awk '{print $1}'
}

press_enter() {
    echo ""; read -rp "$(echo -e "${C}  Tekan [Enter] untuk lanjut...${NC}")"
}

sep() { echo -e "${B}══════════════════════════════════════════════════════${NC}"; }

header() {
    clear; sep
    echo -e "${C}${BOLD}"
    echo "  ██╗   ██╗██████╗ ███████╗    ██████╗  █████╗ ███╗   ██╗███████╗██╗     "
    echo "  ██║   ██║██╔══██╗██╔════╝    ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║     "
    echo "  ██║   ██║██████╔╝███████╗    ██████╔╝███████║██╔██╗ ██║█████╗  ██║     "
    echo "  ╚██╗ ██╔╝██╔═══╝ ╚════██║    ██╔═══╝ ██╔══██║██║╚██╗██║██╔══╝  ██║     "
    echo "   ╚████╔╝ ██║     ███████║    ██║     ██║  ██║██║ ╚████║███████╗███████╗"
    echo "    ╚═══╝  ╚═╝     ╚══════╝    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝"
    echo -e "${NC}"
    echo -e "${W}${BOLD}           ALL SSH + ALL UDP + SPEEDTEST PANEL${NC}"
    sep
    echo -e "  ${W}IP Publik :${NC} ${C}$(get_ip)${NC}  |  ${W}OS:${NC} ${C}$(lsb_release -ds 2>/dev/null | tr -d '"')${NC}"
    sep; echo ""
}

service_status() {
    local name=$1
    systemctl is-active --quiet "$name" 2>/dev/null && \
        echo -e "${G}● ON${NC}" || echo -e "${R}● OFF${NC}"
}

port_status() {
    local port=$1 proto=${2:-tcp}
    ss -tlnp 2>/dev/null | grep -q ":$port " && \
        echo -e "${G}[OPEN]${NC}" || echo -e "${R}[CLOSED]${NC}"
}

# ================================================================
#   BAGIAN 1: INSTALL SEMUA LAYANAN
# ================================================================

install_all() {
    header
    echo -e "${G}${BOLD}  [ INSTALL SEMUA LAYANAN ]${NC}"
    sep
    echo -e "  Akan menginstall:"
    echo -e "  ${W}✦ OpenSSH${NC} (port 22, 2222)"
    echo -e "  ${W}✦ Dropbear${NC} (port 109, 143)"
    echo -e "  ${W}✦ SSH Websocket${NC} (port 80, 8880)"
    echo -e "  ${W}✦ Stunnel4 SSL${NC} (port 443, 777)"
    echo -e "  ${W}✦ BadVPN-UDPGW${NC} (port 7100, 7200, 7300)"
    echo -e "  ${W}✦ ZIVPN UDP${NC} (port 5667)"
    echo -e "  ${W}✦ Squid Proxy${NC} (port 3128, 8080)"
    echo -e "  ${W}✦ Nginx${NC} (port 81)"
    echo ""
    read -rp "  Lanjutkan? (y/N): " CONF
    [[ "$CONF" != "y" && "$CONF" != "Y" ]] && return

    mkdir -p "$PANEL_DIR" "$PANEL_DIR/backup"
    touch "$USERS_DB" "$LOG_FILE"

    echo -e "\n${C}[1/9] Update sistem...${NC}"
    apt-get update -y > /dev/null 2>&1
    apt-get upgrade -y > /dev/null 2>&1
    apt-get install -y wget curl openssl net-tools iptables ufw \
        screen python3 python3-pip bc jq zip unzip \
        build-essential cmake git > /dev/null 2>&1

    _install_openssh
    _install_dropbear
    _install_websocket
    _install_stunnel
    _install_badvpn
    _install_zivpn
    _install_squid
    _install_nginx
    _install_speedtest

    _setup_firewall
    _save_ports_info

    echo ""
    sep
    echo -e "${G}${BOLD}  SEMUA LAYANAN BERHASIL DIINSTALL!${NC}"
    sep
    show_server_info
    log "Install semua layanan selesai"
    press_enter
}

_install_openssh() {
    echo -e "${C}[2/9] Install OpenSSH...${NC}"
    apt-get install -y openssh-server > /dev/null 2>&1
    # Aktifkan port 2222 tambahan
    grep -q "Port 2222" /etc/ssh/sshd_config || echo "Port 2222" >> /etc/ssh/sshd_config
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    # Banner
    cat > /etc/ssh/banner.txt <<'EOF'
╔══════════════════════════════════════════╗
║        WELCOME TO VPS PANEL             ║
║    Unauthorized access is prohibited    ║
╚══════════════════════════════════════════╝
EOF
    grep -q "Banner /etc/ssh/banner.txt" /etc/ssh/sshd_config || \
        echo "Banner /etc/ssh/banner.txt" >> /etc/ssh/sshd_config
    systemctl restart ssh > /dev/null 2>&1
    echo -e "    OpenSSH ${G}✓${NC}"
}

_install_dropbear() {
    echo -e "${C}[3/9] Install Dropbear...${NC}"
    apt-get install -y dropbear > /dev/null 2>&1
    cat > /etc/default/dropbear <<'EOF'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143"
DROPBEAR_BANNER="/etc/ssh/banner.txt"
DROPBEAR_RECEIVE_WINDOW=65536
EOF
    systemctl restart dropbear > /dev/null 2>&1
    echo -e "    Dropbear ${G}✓${NC}"
}

_install_websocket() {
    echo -e "${C}[4/9] Install SSH Websocket...${NC}"
    # Python websocket proxy untuk SSH
    cat > /usr/local/bin/ws-ssh.py <<'PYEOF'
#!/usr/bin/env python3
import socket, threading, select, sys

LISTEN_PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 80
SSH_HOST    = '127.0.0.1'
SSH_PORT    = 22
BUFFER      = 65535
TIMEOUT     = 60

HTTP_RESP   = b"HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n"
HTTP_RESP2  = b"HTTP/1.1 200 Connection Established\r\n\r\n"

def forward(src, dst, event):
    try:
        while not event.is_set():
            r, _, _ = select.select([src], [], [], 5)
            if r:
                data = src.recv(BUFFER)
                if not data: break
                dst.sendall(data)
    except: pass
    finally: event.set()

def handle(client):
    try:
        req = client.recv(BUFFER).decode('utf-8', errors='ignore')
        if 'HTTP' in req:
            if 'CONNECT' in req:
                client.sendall(HTTP_RESP2)
            else:
                client.sendall(HTTP_RESP)
        ssh = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        ssh.connect((SSH_HOST, SSH_PORT))
        ev = threading.Event()
        threading.Thread(target=forward, args=(client, ssh, ev), daemon=True).start()
        forward(ssh, client, ev)
    except: pass
    finally:
        try: client.close()
        except: pass

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(('0.0.0.0', LISTEN_PORT))
server.listen(512)
while True:
    try:
        c, _ = server.accept()
        c.settimeout(TIMEOUT)
        threading.Thread(target=handle, args=(c,), daemon=True).start()
    except: pass
PYEOF
    chmod +x /usr/local/bin/ws-ssh.py

    # Service websocket port 80
    cat > /etc/systemd/system/ws-ssh-80.service <<EOF
[Unit]
Description=SSH Websocket Port 80
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/ws-ssh.py 80
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

    # Service websocket port 8880
    cat > /etc/systemd/system/ws-ssh-8880.service <<EOF
[Unit]
Description=SSH Websocket Port 8880
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/ws-ssh.py 8880
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now ws-ssh-80.service ws-ssh-8880.service > /dev/null 2>&1
    echo -e "    SSH Websocket (80, 8880) ${G}✓${NC}"
}

_install_stunnel() {
    echo -e "${C}[5/9] Install Stunnel4 SSL...${NC}"
    apt-get install -y stunnel4 > /dev/null 2>&1

    # Buat self-signed cert
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=CA/L=LA/O=VPS/CN=vpspanel" \
        -keyout /etc/stunnel/stunnel.key \
        -out /etc/stunnel/stunnel.crt > /dev/null 2>&1
    cat /etc/stunnel/stunnel.crt /etc/stunnel/stunnel.key > /etc/stunnel/stunnel.pem
    chmod 600 /etc/stunnel/stunnel.pem

    cat > /etc/stunnel/stunnel.conf <<'EOF'
pid = /var/run/stunnel4/stunnel4.pid
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[openssh-443]
accept  = 443
connect = 127.0.0.1:22

[openssh-777]
accept  = 777
connect = 127.0.0.1:22

[dropbear-ssl]
accept  = 444
connect = 127.0.0.1:109
EOF

    sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4 2>/dev/null
    systemctl restart stunnel4 > /dev/null 2>&1
    echo -e "    Stunnel4 SSL (443, 444, 777) ${G}✓${NC}"
}

_install_badvpn() {
    echo -e "${C}[6/9] Install BadVPN-UDPGW...${NC}"
    ARCH=$(uname -m)

    # Download prebuilt binary
    if [[ "$ARCH" == "x86_64" ]]; then
        wget -q "https://github.com/idtunnel/UDPGW-SSH/raw/master/badvpn-udpgw64" \
            -O /usr/bin/badvpn-udpgw 2>/dev/null
    else
        wget -q "https://github.com/idtunnel/UDPGW-SSH/raw/master/badvpn-udpgw" \
            -O /usr/bin/badvpn-udpgw 2>/dev/null
    fi

    # Fallback: compile dari source
    if [[ ! -s /usr/bin/badvpn-udpgw ]]; then
        apt-get install -y cmake make gcc > /dev/null 2>&1
        cd /tmp
        git clone --depth=1 https://github.com/ambrop72/badvpn.git badvpn-src > /dev/null 2>&1
        mkdir -p badvpn-src/build && cd badvpn-src/build
        cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
        make -j$(nproc) > /dev/null 2>&1
        [[ -f udpgw/badvpn-udpgw ]] && cp udpgw/badvpn-udpgw /usr/bin/badvpn-udpgw
        cd / && rm -rf /tmp/badvpn-src
    fi

    chmod +x /usr/bin/badvpn-udpgw 2>/dev/null

    # Buat service systemd untuk tiap port
    for PORT in 7100 7200 7300; do
        cat > /etc/systemd/system/badvpn-${PORT}.service <<EOF
[Unit]
Description=BadVPN UDPGW Port $PORT
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/badvpn-udpgw --listen-addr 127.0.0.1:$PORT --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
    done

    systemctl daemon-reload
    systemctl enable --now badvpn-7100 badvpn-7200 badvpn-7300 > /dev/null 2>&1
    echo -e "    BadVPN-UDPGW (7100, 7200, 7300) ${G}✓${NC}"
}

_install_zivpn() {
    echo -e "${C}[7/9] Install ZIVPN UDP...${NC}"
    ARCH=$(uname -m)
    mkdir -p /etc/zivpn

    if [[ "$ARCH" == "x86_64" ]]; then
        wget -q "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64" \
            -O /usr/local/bin/zivpn
    else
        wget -q "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64" \
            -O /usr/local/bin/zivpn
    fi
    chmod +x /usr/local/bin/zivpn 2>/dev/null

    cat > /etc/zivpn/config.json <<'EOF'
{
  "listen": ":5667",
  "cert": "/etc/zivpn/zivpn.crt",
  "key": "/etc/zivpn/zivpn.key",
  "obfs": "zivpn",
  "auth": {
    "mode": "passwords",
    "config": ["zivpn"]
  }
}
EOF

    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
        -subj "/C=US/ST=CA/L=LA/O=Zivpn/CN=zivpn" \
        -keyout /etc/zivpn/zivpn.key -out /etc/zivpn/zivpn.crt > /dev/null 2>&1

    cat > /etc/systemd/system/zivpn.service <<'EOF'
[Unit]
Description=ZIVPN UDP Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/zivpn server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now zivpn.service > /dev/null 2>&1
    # DNAT port range
    IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 6000:19999 \
        -j DNAT --to-destination :5667 2>/dev/null
    echo -e "    ZIVPN UDP (5667) ${G}✓${NC}"
}

_install_squid() {
    echo -e "${C}[8/9] Install Squid Proxy...${NC}"
    apt-get install -y squid > /dev/null 2>&1
    cat > /etc/squid/squid.conf <<'EOF'
http_port 3128
http_port 8080
acl all src 0.0.0.0/0
acl localhost src 127.0.0.1/32
http_access allow all
forwarded_for off
via off
request_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access Cache-Control deny all
EOF
    systemctl restart squid > /dev/null 2>&1
    echo -e "    Squid Proxy (3128, 8080) ${G}✓${NC}"
}

_install_nginx() {
    echo -e "${C}[9/9] Install Nginx...${NC}"
    apt-get install -y nginx > /dev/null 2>&1
    cat > /etc/nginx/sites-available/vpspanel <<'EOF'
server {
    listen 81;
    root /var/www/html;
    index index.html;
    location / { try_files $uri $uri/ =404; }
}
EOF
    ln -sf /etc/nginx/sites-available/vpspanel /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t > /dev/null 2>&1 && systemctl restart nginx > /dev/null 2>&1
    echo -e "    Nginx (port 81) ${G}✓${NC}"
}

_install_speedtest() {
    echo -e "${C}[+]  Install Speedtest CLI...${NC}"
    # speedtest-cli python
    pip3 install speedtest-cli > /dev/null 2>&1 || \
    apt-get install -y speedtest-cli > /dev/null 2>&1
    # Juga coba install Ookla speedtest
    if ! command -v speedtest &>/dev/null; then
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash > /dev/null 2>&1
        apt-get install -y speedtest > /dev/null 2>&1
    fi
    echo -e "    Speedtest CLI ${G}✓${NC}"
}

_setup_firewall() {
    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 2222/tcp > /dev/null 2>&1
    ufw allow 80/tcp > /dev/null 2>&1
    ufw allow 81/tcp > /dev/null 2>&1
    ufw allow 109/tcp > /dev/null 2>&1
    ufw allow 143/tcp > /dev/null 2>&1
    ufw allow 443/tcp > /dev/null 2>&1
    ufw allow 444/tcp > /dev/null 2>&1
    ufw allow 777/tcp > /dev/null 2>&1
    ufw allow 3128/tcp > /dev/null 2>&1
    ufw allow 8080/tcp > /dev/null 2>&1
    ufw allow 8880/tcp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    ufw allow 6000:19999/udp > /dev/null 2>&1
    ufw allow 7100/tcp > /dev/null 2>&1
    ufw allow 7200/tcp > /dev/null 2>&1
    ufw allow 7300/tcp > /dev/null 2>&1
    ufw --force enable > /dev/null 2>&1
    sysctl -w net.core.rmem_max=16777216 > /dev/null 2>&1
    sysctl -w net.core.wmem_max=16777216 > /dev/null 2>&1
}

_save_ports_info() {
    cat > "$PANEL_DIR/ports.info" <<EOF
OPENSSH=22,2222
DROPBEAR=109,143
WEBSOCKET=80,8880
STUNNEL=443,444,777
BADVPN=7100,7200,7300
ZIVPN=5667
SQUID=3128,8080
NGINX=81
EOF
}

# ================================================================
#   BAGIAN 2: MANAJEMEN AKUN SSH
# ================================================================

menu_ssh_user() {
    while true; do
        header
        echo -e "${W}${BOLD}  [ MANAJEMEN AKUN SSH ]${NC}"
        sep
        echo -e "  ${W}[1]${NC} Buat Akun SSH Baru"
        echo -e "  ${W}[2]${NC} Hapus Akun SSH"
        echo -e "  ${W}[3]${NC} Daftar Akun SSH Aktif"
        echo -e "  ${W}[4]${NC} Cek User Login Sekarang"
        echo -e "  ${W}[5]${NC} Perpanjang Expired Akun"
        echo -e "  ${W}[6]${NC} Ganti Password Akun"
        echo -e "  ${W}[7]${NC} Kick / Putuskan User"
        echo -e "  ${W}[0]${NC} Kembali"
        echo ""; read -rp "  Pilih: " CH
        case "$CH" in
            1) create_ssh_user ;;
            2) delete_ssh_user ;;
            3) list_ssh_users ;;
            4) check_login_users ;;
            5) extend_ssh_user ;;
            6) change_ssh_pass ;;
            7) kick_user ;;
            0) return ;;
        esac
    done
}

create_ssh_user() {
    header
    echo -e "${G}${BOLD}  [ BUAT AKUN SSH BARU ]${NC}"; sep; echo ""
    read -rp "  Username   : " USR
    read -rsp "  Password   : " PASS; echo ""
    read -rp "  Expired (hari, cth: 30): " DAYS

    if [[ -z "$USR" || -z "$PASS" || -z "$DAYS" ]]; then
        echo -e "${R}  Semua kolom wajib diisi!${NC}"; press_enter; return
    fi
    if id "$USR" &>/dev/null; then
        echo -e "${R}  Username sudah ada!${NC}"; press_enter; return
    fi

    EXP_DATE=$(date -d "+${DAYS} days" +"%Y-%m-%d")
    useradd -e "$EXP_DATE" -s /bin/false -M "$USR"
    echo "$USR:$PASS" | chpasswd

    # Simpan ke DB
    echo "$USR|$PASS|$EXP_DATE|$(date +%Y-%m-%d)" >> "$USERS_DB"
    log "Buat akun: $USR | Exp: $EXP_DATE"

    IP=$(get_ip)
    echo ""; sep
    echo -e "${G}  Akun berhasil dibuat!${NC}"
    sep
    echo -e "  ${W}Username    :${NC} ${C}$USR${NC}"
    echo -e "  ${W}Password    :${NC} ${C}$PASS${NC}"
    echo -e "  ${W}Expired     :${NC} ${C}$EXP_DATE ($DAYS hari)${NC}"
    echo -e "  ${W}IP Server   :${NC} ${C}$IP${NC}"
    sep
    echo -e "${Y}  Info Koneksi:${NC}"
    echo -e "  SSH Direct    : ssh $USR@$IP -p 22"
    echo -e "  Dropbear      : $IP:109 / $IP:143"
    echo -e "  WS (HTTP)     : $IP:80 / $IP:8880"
    echo -e "  SSL/Stunnel   : $IP:443 / $IP:777"
    echo -e "  BadVPN UDPGW  : 127.0.0.1:7100 / 7200 / 7300"
    sep
    press_enter
}

delete_ssh_user() {
    header
    echo -e "${R}${BOLD}  [ HAPUS AKUN SSH ]${NC}"; sep; echo ""
    list_ssh_users_simple
    echo ""; read -rp "  Username yang akan dihapus: " USR
    if ! id "$USR" &>/dev/null; then
        echo -e "${R}  User tidak ditemukan!${NC}"; press_enter; return
    fi
    pkill -u "$USR" 2>/dev/null
    userdel -r "$USR" 2>/dev/null
    sed -i "/^$USR|/d" "$USERS_DB" 2>/dev/null
    log "Hapus akun: $USR"
    echo -e "${G}  User $USR berhasil dihapus.${NC}"
    press_enter
}

list_ssh_users() {
    header
    echo -e "${C}${BOLD}  [ DAFTAR AKUN SSH ]${NC}"; sep
    printf "  %-18s %-12s %-12s %-10s\n" "USERNAME" "EXPIRED" "DIBUAT" "STATUS"
    sep
    if [[ ! -s "$USERS_DB" ]]; then
        echo -e "  ${Y}Belum ada akun.${NC}"
    else
        while IFS='|' read -r u p exp created; do
            TODAY=$(date +%Y-%m-%d)
            if [[ "$exp" < "$TODAY" ]]; then
                STATUS="${R}EXPIRED${NC}"
            else
                REMAIN=$(( ( $(date -d "$exp" +%s) - $(date +%s) ) / 86400 ))
                STATUS="${G}AKTIF ($REMAIN hr)${NC}"
            fi
            printf "  %-18s %-12s %-12s " "$u" "$exp" "$created"
            echo -e "$STATUS"
        done < "$USERS_DB"
    fi
    sep; press_enter
}

list_ssh_users_simple() {
    echo -e "  ${W}Akun yang ada:${NC}"
    if [[ -s "$USERS_DB" ]]; then
        while IFS='|' read -r u p exp _; do
            echo -e "  - ${C}$u${NC} (exp: $exp)"
        done < "$USERS_DB"
    else
        echo -e "  ${Y}(Belum ada akun)${NC}"
    fi
}

check_login_users() {
    header
    echo -e "${C}${BOLD}  [ USER YANG SEDANG LOGIN ]${NC}"; sep
    echo ""
    who | awk '{print "  User: "$1 "  |  Terminal: "$2 "  |  Waktu: "$3" "$4}'
    echo ""
    echo -e "${Y}  Jumlah koneksi SSH aktif:${NC}"
    ss -tnp | grep ':22' | grep ESTAB | awk '{print "  "$5}' | sort | uniq -c | \
        awk '{print "  "$2 " -> "$1 " koneksi"}'
    sep; press_enter
}

extend_ssh_user() {
    header
    echo -e "${G}${BOLD}  [ PERPANJANG EXPIRED AKUN ]${NC}"; sep; echo ""
    list_ssh_users_simple
    echo ""; read -rp "  Username: " USR
    read -rp "  Tambah berapa hari: " DAYS
    if ! id "$USR" &>/dev/null; then
        echo -e "${R}  User tidak ditemukan!${NC}"; press_enter; return
    fi
    NEW_EXP=$(date -d "+${DAYS} days" +"%Y-%m-%d")
    chage -E "$NEW_EXP" "$USR"
    sed -i "s/^$USR|\([^|]*\)|\([^|]*\)|/$USR|\1|$NEW_EXP|/" "$USERS_DB"
    log "Perpanjang akun $USR hingga $NEW_EXP"
    echo -e "${G}  Akun $USR diperpanjang hingga $NEW_EXP${NC}"
    press_enter
}

change_ssh_pass() {
    header
    echo -e "${C}${BOLD}  [ GANTI PASSWORD AKUN ]${NC}"; sep; echo ""
    list_ssh_users_simple
    echo ""; read -rp "  Username: " USR
    read -rsp "  Password baru: " NEWPASS; echo ""
    if ! id "$USR" &>/dev/null; then
        echo -e "${R}  User tidak ditemukan!${NC}"; press_enter; return
    fi
    echo "$USR:$NEWPASS" | chpasswd
    sed -i "s/^$USR|[^|]*|/$USR|$NEWPASS|/" "$USERS_DB"
    echo -e "${G}  Password $USR berhasil diubah.${NC}"
    press_enter
}

kick_user() {
    header
    echo -e "${R}${BOLD}  [ KICK / PUTUSKAN USER ]${NC}"; sep; echo ""
    check_login_users
    echo ""; read -rp "  Username yang akan di-kick: " USR
    pkill -u "$USR" && echo -e "${G}  User $USR berhasil diputuskan.${NC}" || \
        echo -e "${Y}  Tidak ada sesi aktif untuk $USR${NC}"
    press_enter
}

# ================================================================
#   BAGIAN 3: MANAJEMEN UDP ZIVPN
# ================================================================

menu_udp_zivpn() {
    while true; do
        header
        echo -e "${W}${BOLD}  [ MANAJEMEN UDP ZIVPN ]${NC}"; sep
        echo -e "  ${W}[1]${NC} Buat Akun ZIVPN"
        echo -e "  ${W}[2]${NC} Hapus Akun ZIVPN"
        echo -e "  ${W}[3]${NC} Daftar Akun ZIVPN"
        echo -e "  ${W}[4]${NC} Ganti Port ZIVPN"
        echo -e "  ${W}[0]${NC} Kembali"
        echo ""; read -rp "  Pilih: " CH
        case "$CH" in
            1) create_zivpn_user ;;
            2) delete_zivpn_user ;;
            3) list_zivpn_users ;;
            4) change_zivpn_port ;;
            0) return ;;
        esac
    done
}

create_zivpn_user() {
    header
    echo -e "${G}${BOLD}  [ BUAT AKUN ZIVPN ]${NC}"; sep; echo ""
    read -rp "  Password ZIVPN baru: " PASS
    [[ -z "$PASS" ]] && echo -e "${R}  Password tidak boleh kosong!${NC}" && press_enter && return

    CFG=$(cat /etc/zivpn/config.json 2>/dev/null)
    NEW_CFG=$(echo "$CFG" | python3 -c "
import json,sys
d=json.load(sys.stdin)
d['auth']['config'].append('$PASS')
print(json.dumps(d,indent=2))
")
    echo "$NEW_CFG" > /etc/zivpn/config.json
    systemctl restart zivpn.service > /dev/null 2>&1

    IP=$(get_ip)
    PORT=$(grep -oP '"listen":.*":\K[0-9]+' /etc/zivpn/config.json)
    echo ""; sep
    echo -e "${G}  Akun ZIVPN berhasil ditambahkan!${NC}"; sep
    echo -e "  ${W}Server    :${NC} ${C}$IP${NC}"
    echo -e "  ${W}Port      :${NC} ${C}$PORT${NC}"
    echo -e "  ${W}Password  :${NC} ${C}$PASS${NC}"
    echo -e "  ${W}Obfs      :${NC} ${C}zivpn${NC}"
    sep; press_enter
}

delete_zivpn_user() {
    header
    echo -e "${R}${BOLD}  [ HAPUS AKUN ZIVPN ]${NC}"; sep
    list_zivpn_users
    echo ""; read -rp "  Password yang akan dihapus: " PASS
    CFG=$(cat /etc/zivpn/config.json 2>/dev/null)
    NEW_CFG=$(echo "$CFG" | python3 -c "
import json,sys
d=json.load(sys.stdin)
d['auth']['config']=[p for p in d['auth']['config'] if p!='$PASS']
print(json.dumps(d,indent=2))
")
    echo "$NEW_CFG" > /etc/zivpn/config.json
    systemctl restart zivpn.service > /dev/null 2>&1
    echo -e "${G}  Password $PASS dihapus dari ZIVPN.${NC}"
    press_enter
}

list_zivpn_users() {
    echo -e "\n  ${W}Password ZIVPN aktif:${NC}"
    python3 -c "
import json
try:
    d=json.load(open('/etc/zivpn/config.json'))
    for i,p in enumerate(d['auth']['config'],1):
        print(f'  {i}. {p}')
except: print('  (tidak ada / file tidak ditemukan)')
" 2>/dev/null
}

change_zivpn_port() {
    header
    echo -e "${C}${BOLD}  [ GANTI PORT ZIVPN ]${NC}"; sep; echo ""
    OLD=$(grep -oP '"listen":.*":\K[0-9]+' /etc/zivpn/config.json 2>/dev/null)
    echo -e "  Port saat ini: ${Y}$OLD${NC}"
    read -rp "  Port baru: " NEW
    [[ ! "$NEW" =~ ^[0-9]+$ ]] && echo -e "${R}  Port tidak valid!${NC}" && press_enter && return
    sed -i "s/\":$OLD/\":$NEW/" /etc/zivpn/config.json
    IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    iptables -t nat -D PREROUTING -i "$IFACE" -p udp --dport 6000:19999 \
        -j DNAT --to-destination :"$OLD" 2>/dev/null
    iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 6000:19999 \
        -j DNAT --to-destination :"$NEW" 2>/dev/null
    systemctl restart zivpn.service > /dev/null 2>&1
    echo -e "${G}  Port ZIVPN diubah ke $NEW.${NC}"
    press_enter
}

# ================================================================
#   BAGIAN 4: KELOLA SERVICE
# ================================================================

menu_services() {
    while true; do
        header
        echo -e "${W}${BOLD}  [ KELOLA SERVICE ]${NC}"; sep
        echo ""
        printf "  %-25s %s\n" "Service" "Status"
        sep
        printf "  %-25s %b\n" "OpenSSH (22,2222)"    "$(service_status ssh)"
        printf "  %-25s %b\n" "Dropbear (109,143)"   "$(service_status dropbear)"
        printf "  %-25s %b\n" "WS-SSH port 80"       "$(service_status ws-ssh-80)"
        printf "  %-25s %b\n" "WS-SSH port 8880"     "$(service_status ws-ssh-8880)"
        printf "  %-25s %b\n" "Stunnel4 (443,777)"   "$(service_status stunnel4)"
        printf "  %-25s %b\n" "BadVPN-UDPGW 7100"    "$(service_status badvpn-7100)"
        printf "  %-25s %b\n" "BadVPN-UDPGW 7200"    "$(service_status badvpn-7200)"
        printf "  %-25s %b\n" "BadVPN-UDPGW 7300"    "$(service_status badvpn-7300)"
        printf "  %-25s %b\n" "ZIVPN UDP (5667)"     "$(service_status zivpn)"
        printf "  %-25s %b\n" "Squid Proxy (3128)"   "$(service_status squid)"
        printf "  %-25s %b\n" "Nginx (81)"           "$(service_status nginx)"
        sep; echo ""
        echo -e "  ${W}[1]${NC} Restart Semua Service"
        echo -e "  ${W}[2]${NC} Restart SSH (openssh+dropbear+ws)"
        echo -e "  ${W}[3]${NC} Restart UDP (badvpn+zivpn)"
        echo -e "  ${W}[4]${NC} Restart Service Tertentu"
        echo -e "  ${W}[5]${NC} Stop Service Tertentu"
        echo -e "  ${W}[0]${NC} Kembali"
        echo ""; read -rp "  Pilih: " CH
        case "$CH" in
            1)
                for SVC in ssh dropbear ws-ssh-80 ws-ssh-8880 stunnel4 \
                    badvpn-7100 badvpn-7200 badvpn-7300 zivpn squid nginx; do
                    systemctl restart "$SVC" > /dev/null 2>&1
                done
                echo -e "${G}  Semua service di-restart.${NC}"; sleep 1 ;;
            2)
                systemctl restart ssh dropbear ws-ssh-80 ws-ssh-8880 stunnel4 > /dev/null 2>&1
                echo -e "${G}  Service SSH di-restart.${NC}"; sleep 1 ;;
            3)
                systemctl restart badvpn-7100 badvpn-7200 badvpn-7300 zivpn > /dev/null 2>&1
                echo -e "${G}  Service UDP di-restart.${NC}"; sleep 1 ;;
            4)
                read -rp "  Nama service: " SVC
                systemctl restart "$SVC" > /dev/null 2>&1 && \
                    echo -e "${G}  $SVC di-restart.${NC}" || \
                    echo -e "${R}  Gagal restart $SVC${NC}"; sleep 1 ;;
            5)
                read -rp "  Nama service: " SVC
                systemctl stop "$SVC" > /dev/null 2>&1 && \
                    echo -e "${Y}  $SVC di-stop.${NC}" || \
                    echo -e "${R}  Gagal stop $SVC${NC}"; sleep 1 ;;
            0) return ;;
        esac
    done
}

# ================================================================
#   BAGIAN 5: SPEEDTEST
# ================================================================

run_speedtest() {
    header
    echo -e "${M}${BOLD}  [ SPEEDTEST VPS ]${NC}"; sep; echo ""
    echo -e "${Y}  Pilih metode speedtest:${NC}"
    echo -e "  ${W}[1]${NC} speedtest-cli (Python)"
    echo -e "  ${W}[2]${NC} Ookla Speedtest (Official)"
    echo -e "  ${W}[3]${NC} Fast.com via curl"
    echo -e "  ${W}[4]${NC} Test bandwidth manual (download test)"
    echo -e "  ${W}[0]${NC} Kembali"
    echo ""; read -rp "  Pilih: " CH

    case "$CH" in
        1)
            echo -e "\n${C}  Menjalankan speedtest-cli...${NC}\n"
            if command -v speedtest-cli &>/dev/null; then
                speedtest-cli --simple
            else
                pip3 install speedtest-cli -q && speedtest-cli --simple
            fi ;;
        2)
            echo -e "\n${C}  Menjalankan Ookla speedtest...${NC}\n"
            if command -v speedtest &>/dev/null; then
                speedtest
            else
                echo -e "${R}  Ookla speedtest belum terinstall.${NC}"
                echo -e "  Install dengan: curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash && apt install speedtest"
            fi ;;
        3)
            echo -e "\n${C}  Testing kecepatan download via fast.com...${NC}\n"
            curl -s https://raw.githubusercontent.com/nicowillis/speedtest/master/speedtest.sh | bash 2>/dev/null || \
            (echo -e "${C}  Download 100MB test file...${NC}"
             START=$(date +%s%N)
             wget -q -O /dev/null http://speedtest.tele2.net/100MB.zip
             END=$(date +%s%N)
             ELAPSED=$(echo "scale=2; ($END - $START) / 1000000000" | bc)
             SPEED=$(echo "scale=2; 100 / $ELAPSED * 8" | bc)
             echo -e "  Waktu   : ${C}${ELAPSED}s${NC}"
             echo -e "  Kecepatan: ${G}${SPEED} Mbps${NC}") ;;
        4)
            echo -e "\n${C}  Download test (100MB)...${NC}\n"
            wget -O /dev/null --progress=dot:mega \
                http://speedtest.tele2.net/100MB.zip 2>&1 | \
                grep -o '[0-9.]*\s*[KM]B/s' | tail -1 | \
                xargs -I{} echo -e "  Kecepatan: ${G}{}${NC}"
            echo "" ;;
        0) return ;;
    esac
    press_enter
}

# ================================================================
#   BAGIAN 6: MONITORING
# ================================================================

show_monitor() {
    header
    echo -e "${C}${BOLD}  [ MONITORING SERVER ]${NC}"; sep; echo ""

    # System Info
    echo -e "  ${W}━━━ SISTEM ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  OS       : $(lsb_release -ds 2>/dev/null | tr -d '"')"
    echo -e "  Kernel   : $(uname -r)"
    echo -e "  Uptime   : $(uptime -p)"
    echo -e "  CPU      : $(grep -c processor /proc/cpuinfo) Core @ $(grep 'cpu MHz' /proc/cpuinfo | head -1 | awk '{print $4}') MHz"
    CPU_USAGE=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2+$4}')
    echo -e "  CPU Load : ${C}${CPU_USAGE}%${NC}"
    echo -e "  RAM      : $(free -h | awk '/^Mem/{print $3"/"$2" (Used/Total)"}')"
    echo -e "  Disk     : $(df -h / | awk 'NR==2{print $3"/"$2" ("$5" used)"}')"
    echo ""

    # Network
    echo -e "  ${W}━━━ JARINGAN ━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  IP Publik : $(get_ip)"
    echo -e "  IP Lokal  : $(hostname -I | awk '{print $1}')"
    IFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null)
    TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null)
    echo -e "  Interface : $IFACE"
    echo -e "  RX Total  : $(echo "scale=2; $RX/1024/1024" | bc) MB"
    echo -e "  TX Total  : $(echo "scale=2; $TX/1024/1024" | bc) MB"
    echo ""

    # Port Status
    echo -e "  ${W}━━━ STATUS PORT ━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for P in 22 2222 80 109 143 443 777 8880 3128 5667; do
        ss -tlnp | grep -q ":$P " && \
            printf "  Port %-6s: %b\n" "$P" "${G}[OPEN]${NC}" || \
            printf "  Port %-6s: %b\n" "$P" "${R}[CLOSED]${NC}"
    done
    echo ""

    # Koneksi aktif
    CONN=$(ss -tnp | grep ESTAB | wc -l)
    echo -e "  ${W}━━━ KONEKSI AKTIF ━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Total     : ${C}$CONN koneksi${NC}"
    echo -e "  SSH (22)  : $(ss -tnp | grep ':22' | grep ESTAB | wc -l) koneksi"
    echo -e "  WS (80)   : $(ss -tnp | grep ':80' | grep ESTAB | wc -l) koneksi"
    echo -e "  SSL (443) : $(ss -tnp | grep ':443' | grep ESTAB | wc -l) koneksi"

    sep; press_enter
}

# ================================================================
#   BAGIAN 7: INFO SERVER
# ================================================================

show_server_info() {
    IP=$(get_ip)
    echo ""
    sep
    echo -e "${C}${BOLD}  INFO LENGKAP SERVER & PORT${NC}"
    sep
    echo -e "\n  ${W}═══ SSH ═══════════════════════════════════${NC}"
    echo -e "  OpenSSH Direct  : ${C}$IP:22${NC} / ${C}$IP:2222${NC}"
    echo -e "  Dropbear        : ${C}$IP:109${NC} / ${C}$IP:143${NC}"
    echo -e "  Websocket HTTP  : ${C}$IP:80${NC} / ${C}$IP:8880${NC}"
    echo -e "  SSL/Stunnel4    : ${C}$IP:443${NC} / ${C}$IP:777${NC}"
    echo -e "  Dropbear SSL    : ${C}$IP:444${NC}"
    echo -e "\n  ${W}═══ UDP ════════════════════════════════════${NC}"
    echo -e "  BadVPN UDPGW    : ${C}127.0.0.1:7100${NC}"
    echo -e "                    ${C}127.0.0.1:7200${NC}"
    echo -e "                    ${C}127.0.0.1:7300${NC}"
    ZPASS=$(python3 -c "import json; d=json.load(open('/etc/zivpn/config.json')); print(', '.join(d['auth']['config']))" 2>/dev/null)
    echo -e "  ZIVPN UDP       : ${C}$IP:5667${NC} | Pass: ${C}${ZPASS:-zivpn}${NC}"
    echo -e "  ZIVPN Range     : ${C}$IP:6000-19999${NC} (→5667)"
    echo -e "\n  ${W}═══ PROXY ══════════════════════════════════${NC}"
    echo -e "  Squid HTTP      : ${C}$IP:3128${NC} / ${C}$IP:8080${NC}"
    sep
}

menu_server_info() {
    header
    show_server_info
    press_enter
}

# ================================================================
#   BAGIAN 8: LOG
# ================================================================

menu_logs() {
    while true; do
        header
        echo -e "${W}${BOLD}  [ LOG & MONITORING ]${NC}"; sep
        echo -e "  ${W}[1]${NC} Log Panel VPS"
        echo -e "  ${W}[2]${NC} Log SSH (auth.log)"
        echo -e "  ${W}[3]${NC} Log BadVPN UDPGW"
        echo -e "  ${W}[4]${NC} Log ZIVPN UDP"
        echo -e "  ${W}[5]${NC} Log Nginx"
        echo -e "  ${W}[6]${NC} Log Realtime (live)"
        echo -e "  ${W}[0]${NC} Kembali"
        echo ""; read -rp "  Pilih: " CH
        case "$CH" in
            1) tail -50 "$LOG_FILE" 2>/dev/null || echo "(kosong)"; press_enter ;;
            2) tail -50 /var/log/auth.log 2>/dev/null || journalctl -u ssh -n 50 --no-pager; press_enter ;;
            3) journalctl -u badvpn-7300 -n 50 --no-pager; press_enter ;;
            4) journalctl -u zivpn -n 50 --no-pager; press_enter ;;
            5) tail -50 /var/log/nginx/access.log 2>/dev/null || echo "(kosong)"; press_enter ;;
            6) echo -e "${Y}  Ctrl+C untuk keluar${NC}"; sleep 1
               journalctl -f -u ssh -u zivpn -u badvpn-7300 ;;
            0) return ;;
        esac
    done
}

# ================================================================
#   BAGIAN 9: PENGATURAN
# ================================================================

menu_settings() {
    while true; do
        header
        echo -e "${W}${BOLD}  [ PENGATURAN ]${NC}"; sep
        echo -e "  ${W}[1]${NC} Ganti Port OpenSSH"
        echo -e "  ${W}[2]${NC} Ganti Port Dropbear"
        echo -e "  ${W}[3]${NC} Ganti Port Websocket"
        echo -e "  ${W}[4]${NC} Renew Sertifikat SSL Stunnel"
        echo -e "  ${W}[5]${NC} Setup Auto-Reboot Harian"
        echo -e "  ${W}[6]${NC} Auto-Kill Multi Login"
        echo -e "  ${W}[7]${NC} Backup Konfigurasi"
        echo -e "  ${W}[8]${NC} Restore Konfigurasi"
        echo -e "  ${W}[0]${NC} Kembali"
        echo ""; read -rp "  Pilih: " CH
        case "$CH" in
            1) change_ssh_port ;;
            2) change_dropbear_port ;;
            3) change_ws_port ;;
            4) renew_ssl_cert ;;
            5) setup_autoreboot ;;
            6) setup_autokill ;;
            7) backup_config ;;
            8) restore_config ;;
            0) return ;;
        esac
    done
}

change_ssh_port() {
    read -rp "  Port OpenSSH baru: " P
    [[ ! "$P" =~ ^[0-9]+$ ]] && return
    sed -i "s/^Port .*/Port $P/" /etc/ssh/sshd_config
    systemctl restart ssh > /dev/null 2>&1
    echo -e "${G}  Port SSH diubah ke $P.${NC}"; press_enter
}

change_dropbear_port() {
    read -rp "  Port Dropbear baru (utama): " P
    [[ ! "$P" =~ ^[0-9]+$ ]] && return
    sed -i "s/^DROPBEAR_PORT=.*/DROPBEAR_PORT=$P/" /etc/default/dropbear
    systemctl restart dropbear > /dev/null 2>&1
    echo -e "${G}  Port Dropbear diubah ke $P.${NC}"; press_enter
}

change_ws_port() {
    read -rp "  Port Websocket baru: " P
    [[ ! "$P" =~ ^[0-9]+$ ]] && return
    systemctl stop ws-ssh-80 ws-ssh-8880 > /dev/null 2>&1
    sed -i "s|ExecStart=.*ws-ssh.py [0-9]*|ExecStart=/usr/bin/python3 /usr/local/bin/ws-ssh.py $P|" \
        /etc/systemd/system/ws-ssh-80.service
    systemctl daemon-reload
    systemctl start ws-ssh-80 > /dev/null 2>&1
    echo -e "${G}  Port Websocket utama diubah ke $P.${NC}"; press_enter
}

renew_ssl_cert() {
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=CA/L=LA/O=VPS/CN=vpspanel" \
        -keyout /etc/stunnel/stunnel.key \
        -out /etc/stunnel/stunnel.crt 2>/dev/null
    cat /etc/stunnel/stunnel.crt /etc/stunnel/stunnel.key > /etc/stunnel/stunnel.pem
    systemctl restart stunnel4 > /dev/null 2>&1
    echo -e "${G}  Sertifikat SSL diperbarui.${NC}"; press_enter
}

setup_autoreboot() {
    read -rp "  Jam auto-reboot (cth: 04 untuk jam 04:00): " HOUR
    (crontab -l 2>/dev/null | grep -v "vpspanel-reboot"; \
     echo "0 $HOUR * * * /sbin/reboot # vpspanel-reboot") | crontab -
    echo -e "${G}  Auto-reboot diset jam ${HOUR}:00 setiap hari.${NC}"; press_enter
}

setup_autokill() {
    read -rp "  Max login per user (cth: 2): " MAX
    cat > /etc/cron.d/autokill-vpn <<EOF
*/1 * * * * root /usr/local/bin/autokill-multi.sh $MAX
EOF
    cat > /usr/local/bin/autokill-multi.sh <<AKEOF
#!/bin/bash
MAX_LOGIN=\${1:-2}
who | awk '{print \$1}' | sort | uniq -c | while read COUNT USER; do
    if [[ \$COUNT -gt \$MAX_LOGIN ]]; then
        pkill -u "\$USER" -9 2>/dev/null
        echo "[\$(date)] AutoKill: \$USER (\$COUNT login)" >> /var/log/vpn-panel.log
    fi
done
AKEOF
    chmod +x /usr/local/bin/autokill-multi.sh
    echo -e "${G}  Auto-kill multi-login aktif (max $MAX per user).${NC}"; press_enter
}

backup_config() {
    TS=$(date +%Y%m%d_%H%M%S)
    BK="$PANEL_DIR/backup/backup_$TS.tar.gz"
    tar -czf "$BK" \
        /etc/ssh/sshd_config \
        /etc/default/dropbear \
        /etc/stunnel/stunnel.conf \
        /etc/zivpn/config.json \
        "$USERS_DB" 2>/dev/null
    echo -e "${G}  Backup disimpan: $BK${NC}"; press_enter
}

restore_config() {
    echo -e "  Daftar backup:"
    ls "$PANEL_DIR/backup/"*.tar.gz 2>/dev/null || { echo "  Tidak ada backup."; press_enter; return; }
    read -rp "  Path file backup: " BK
    [[ ! -f "$BK" ]] && echo -e "${R}  File tidak ditemukan!${NC}" && press_enter && return
    tar -xzf "$BK" -C / > /dev/null 2>&1
    for SVC in ssh dropbear stunnel4 zivpn; do
        systemctl restart "$SVC" > /dev/null 2>&1
    done
    echo -e "${G}  Config di-restore dan service di-restart.${NC}"; press_enter
}

# ================================================================
#   MAIN MENU
# ================================================================

main_menu() {
    check_root
    mkdir -p "$PANEL_DIR/backup"
    touch "$LOG_FILE" "$USERS_DB" 2>/dev/null

    while true; do
        header

        # Status ringkas
        printf "  %-22s %b   %-22s %b\n" \
            "SSH/Dropbear" "$(service_status ssh)" \
            "BadVPN-UDPGW" "$(service_status badvpn-7300)"
        printf "  %-22s %b   %-22s %b\n" \
            "WS-SSH (80)" "$(service_status ws-ssh-80)" \
            "ZIVPN UDP" "$(service_status zivpn)"
        printf "  %-22s %b   %-22s %b\n" \
            "Stunnel4 SSL" "$(service_status stunnel4)" \
            "Squid Proxy" "$(service_status squid)"
        echo ""
        sep

        echo -e "  ${W}[1]${NC}  Install Semua Layanan"
        echo -e "  ${W}[2]${NC}  Manajemen Akun SSH"
        echo -e "  ${W}[3]${NC}  Manajemen UDP ZIVPN"
        echo -e "  ${W}[4]${NC}  Kelola Service"
        echo -e "  ${W}[5]${NC}  Speedtest VPS"
        echo -e "  ${W}[6]${NC}  Monitor Server"
        echo -e "  ${W}[7]${NC}  Info Server & Port Lengkap"
        echo -e "  ${W}[8]${NC}  Log & History"
        echo -e "  ${W}[9]${NC}  Pengaturan Lanjutan"
        echo -e "  ${W}[0]${NC}  Keluar"
        echo ""
        sep
        read -rp "$(echo -e "${C}  Pilih menu [0-9]: ${NC}")" MENU

        case "$MENU" in
            1) install_all ;;
            2) menu_ssh_user ;;
            3) menu_udp_zivpn ;;
            4) menu_services ;;
            5) run_speedtest ;;
            6) show_monitor ;;
            7) header; show_server_info; press_enter ;;
            8) menu_logs ;;
            9) menu_settings ;;
            0) echo -e "${C}  Keluar dari panel.${NC}"; exit 0 ;;
            *) echo -e "${R}  Pilihan tidak valid.${NC}"; sleep 1 ;;
        esac
    done
}

main_menu
