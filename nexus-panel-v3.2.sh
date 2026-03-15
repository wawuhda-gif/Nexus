#!/bin/bash
# =================================================================
#   OGH-PANELL VPS MANAGER v3.2
#   SSH + UDP Custom + ZIVPN + VMess + VLess + Trojan
#   Support: Debian 10/11/12 & Ubuntu 20.04/22.04/24.04
#   Xray-core v26.2.6 | TLS & nTLS
# =================================================================

# ── Warna (semua tema diganti FULL BLUE) ─────────────────────────
BL='\033[0;34m'    # blue
BLB='\033[1;34m'   # bold blue
CB='\033[0;36m'    # cyan (aksen)
CBB='\033[1;36m'   # bold cyan
W='\033[1;37m'     # white
D='\033[0;90m'     # dark/gray
GB='\033[1;32m'    # green (status aktif)
R='\033[0;31m'     # red (status mati/error)
Y='\033[1;33m'     # yellow (highlight)
NC='\033[0m'       # reset
BOLD='\033[1m'

# Alias pendek supaya sub-menu tidak perlu diubah semua
HC="$BLB" AC="$CBB" SC="$CB"

# Garis dekorasi full-blue
bl_line(){
  echo -e "${BLB}══════════════════════════════════════════════════════════════${NC}"
}
bl_line2(){
  echo -e "${BL}──────────────────────────────────────────────────────────────${NC}"
}

# ── Path & URL konstanta ──────────────────────────────────────────
PANEL_DIR="/etc/nexus-panel"
XRAY_DIR="/usr/local/etc/xray"
XRAY_BIN="/usr/local/bin/xray"
XRAY_CFG="$XRAY_DIR/config.json"
XRAY_DB="$PANEL_DIR/xray_users.db"
LOG_FILE="/var/log/nexus-panel.log"
DOMAIN_FILE="$PANEL_DIR/domain.conf"
USERS_DB="$PANEL_DIR/users.db"
UDPC_DB="$PANEL_DIR/udpc_users.db"
ZIVPN_DB="$PANEL_DIR/zivpn_users.db"
INSTALLED_FLAG="$PANEL_DIR/.installed"

XRAY_VER="v26.2.6"
XRAY_ZIP_AMD64="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/Xray-linux-64.zip"
XRAY_ZIP_ARM64="https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/Xray-linux-arm64-v8a.zip"
XRAY_INSTALL_URL="https://github.com/XTLS/Xray-install/raw/main/install-release.sh"
UDPC_BIN_AMD64="https://raw.githubusercontent.com/feely666/udp-custom/main/udp-custom-linux-amd64"
UDPC_CFG_URL="https://raw.githubusercontent.com/feely666/udp-custom/main/config.json"
ZIVPN_AMD64="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
ZIVPN_ARM64="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
BADVPN_AMD64="https://github.com/idtunnel/UDPGW-SSH/raw/master/badvpn-udpgw64"
BADVPN_ARM="https://github.com/idtunnel/UDPGW-SSH/raw/master/badvpn-udpgw"

# ── Helper dasar ──────────────────────────────────────────────────
check_root(){ [[ $EUID -ne 0 ]] && echo -e "${R}[ERROR] Harus dijalankan sebagai root!${NC}" && exit 1; }
log(){ echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null; }
get_ip(){ curl -s --max-time 5 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}'; }
get_dom(){ [[ -f "$DOMAIN_FILE" ]] && cat "$DOMAIN_FILE" || get_ip; }
get_arch(){ uname -m | grep -qE "aarch64|arm64" && echo "arm64" || echo "amd64"; }
gen_uuid(){ cat /proc/sys/kernel/random/uuid 2>/dev/null || python3 -c "import uuid; print(uuid.uuid4())"; }
ok()  { echo -e "  ${GB}[✔]${NC} $*"; }
err() { echo -e "  ${R}[✘]${NC} $*"; }
info(){ echo -e "  ${CBB}[•]${NC} $*"; }
warn(){ echo -e "  ${Y}[!]${NC} $*"; }
press_enter(){ echo ""; read -rp "$(echo -e "  ${CBB}Tekan ${W}[Enter]${CBB} untuk kembali...${NC}")"; }
svc_stat(){ systemctl is-active --quiet "$1" 2>/dev/null && echo -e "${GB}● AKTIF${NC}" || echo -e "${R}● MATI${NC}"; }

# ── Deteksi OS ────────────────────────────────────────────────────
detect_os(){
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS_NAME="$ID"
    OS_VER="$VERSION_ID"
  else
    OS_NAME="unknown"
    OS_VER="unknown"
  fi
}

check_os_support(){
  detect_os
  case "$OS_NAME" in
    debian|ubuntu) return 0 ;;
    *)
      echo -e "${R}[ERROR] OS tidak didukung: $OS_NAME${NC}"
      echo -e "${Y}Script ini hanya untuk Debian 10/11/12 dan Ubuntu 20.04/22.04/24.04${NC}"
      exit 1 ;;
  esac
}

# =================================================================
#   INSTALL OTOMATIS SEMUA LAYANAN (pertama kali jalan)
# =================================================================

do_install_all(){
  clear
  echo -e "${BLB}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLB}║${NC}  ${W}INSTALL PERTAMA KALI — OGH-PANELL v3.2${NC}               ${BLB}║${NC}"
  echo -e "${BLB}║${NC}  ${CB}Support: Debian 10/11/12 | Ubuntu 20.04/22.04/24.04${NC}   ${BLB}║${NC}"
  echo -e "${BLB}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""
  info "Mendeteksi OS: ${Y}$(. /etc/os-release && echo "$PRETTY_NAME")${NC}"
  info "Arsitektur   : ${Y}$(get_arch)${NC}"
  echo ""

  # ── Update sistem ─────────────────────────────────────────────
  info "Update & upgrade paket sistem..."
  apt-get update -qq && apt-get upgrade -y -qq
  ok "Sistem diperbarui."

  # ── Paket dasar ───────────────────────────────────────────────
  info "Install paket dasar..."
  apt-get install -y -qq \
    curl wget unzip zip tar git \
    openssl ca-certificates gnupg \
    python3 python3-pip \
    lsb-release net-tools iproute2 \
    iptables iptables-persistent \
    cron ufw fail2ban \
    screenfetch neofetch htop \
    socat netcat-openbsd \
    nginx squid
  ok "Paket dasar terinstall."

  # ── SSH & Dropbear ────────────────────────────────────────────
  info "Konfigurasi SSH..."
  apt-get install -y -qq openssh-server dropbear
  # SSH port 22 & 2222
  if ! grep -q "^Port 2222" /etc/ssh/sshd_config; then
    echo "Port 2222" >> /etc/ssh/sshd_config
  fi
  sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
  sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
  # Dropbear port 109, 143, 69
  cat > /etc/default/dropbear <<'EOF'
NO_START=0
DROPBEAR_PORT=109
DROPBEAR_EXTRA_ARGS="-p 143 -p 69"
DROPBEAR_BANNER="/etc/issue.net"
EOF
  systemctl enable ssh dropbear > /dev/null 2>&1
  systemctl restart ssh dropbear > /dev/null 2>&1
  ok "SSH & Dropbear aktif."

  # ── Stunnel4 (SSL) ────────────────────────────────────────────
  info "Install & konfigurasi Stunnel4 (SSL)..."
  apt-get install -y -qq stunnel4
  openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=US/ST=CA/L=LA/O=OGH/CN=ogh-panel" \
    -keyout /etc/stunnel/stunnel.key \
    -out /etc/stunnel/stunnel.crt > /dev/null 2>&1
  cat /etc/stunnel/stunnel.crt /etc/stunnel/stunnel.key > /etc/stunnel/stunnel.pem
  cat > /etc/stunnel/stunnel.conf <<'EOF'
cert = /etc/stunnel/stunnel.pem
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
[dropbear-ssl]
accept = 443
connect = 127.0.0.1:22
[dropbear-ssl2]
accept = 444
connect = 127.0.0.1:109
[dropbear-ssl3]
accept = 777
connect = 127.0.0.1:143
EOF
  sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/stunnel4
  systemctl enable stunnel4 > /dev/null 2>&1
  systemctl restart stunnel4 > /dev/null 2>&1
  ok "Stunnel4 SSL aktif (443/444/777)."

  # ── WebSocket SSH (ws-ssh) ─────────────────────────────────────
  info "Install WebSocket SSH (port 80 & 8880)..."
  apt-get install -y -qq python3-websockify 2>/dev/null || pip3 install websockify -q
  # Service ws-ssh port 80
  cat > /etc/systemd/system/ws-ssh-80.service <<'EOF'
[Unit]
Description=WebSocket SSH Port 80
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 -m websockify 80 127.0.0.1:22 --ssl-only=0 --web=/var/www/html
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
  # Service ws-ssh port 8880
  cat > /etc/systemd/system/ws-ssh-8880.service <<'EOF'
[Unit]
Description=WebSocket SSH Port 8880
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/python3 -m websockify 8880 127.0.0.1:22 --ssl-only=0
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable ws-ssh-80 ws-ssh-8880 > /dev/null 2>&1
  systemctl restart ws-ssh-80 ws-ssh-8880 > /dev/null 2>&1
  ok "WebSocket SSH aktif (80/8880)."

  # ── BadVPN UDPGW ──────────────────────────────────────────────
  info "Install BadVPN UDPGW (7100/7200/7300)..."
  local ARCH=$(get_arch)
  if [[ "$ARCH" == "amd64" ]]; then
    wget -q "$BADVPN_AMD64" -O /usr/local/bin/badvpn-udpgw
  else
    wget -q "$BADVPN_ARM" -O /usr/local/bin/badvpn-udpgw
  fi
  chmod +x /usr/local/bin/badvpn-udpgw 2>/dev/null
  for PORT in 7100 7200 7300; do
    cat > /etc/systemd/system/badvpn-${PORT}.service <<EOF
[Unit]
Description=BadVPN UDPGW Port $PORT
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:$PORT --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
  done
  systemctl daemon-reload
  systemctl enable badvpn-7100 badvpn-7200 badvpn-7300 > /dev/null 2>&1
  systemctl restart badvpn-7100 badvpn-7200 badvpn-7300 > /dev/null 2>&1
  ok "BadVPN UDPGW aktif (7100/7200/7300)."

  # ── UDP Custom ────────────────────────────────────────────────
  info "Install UDP Custom (port 25525)..."
  mkdir -p /etc/udp-custom
  if [[ "$ARCH" == "amd64" ]]; then
    wget -q "$UDPC_BIN_AMD64" -O /usr/local/bin/udp-custom
    chmod +x /usr/local/bin/udp-custom
  fi
  wget -q "$UDPC_CFG_URL" -O /etc/udp-custom/config.json 2>/dev/null || \
  cat > /etc/udp-custom/config.json <<'EOF'
{
  "listen": ":25525",
  "stream": "udp",
  "remote_addr": "127.0.0.1:22",
  "auth": {"mode": "passwords", "config": []},
  "speed_limit": 0,
  "read_buf_size": 4096,
  "write_buf_size": 4096
}
EOF
  cat > /etc/systemd/system/udp-custom.service <<'EOF'
[Unit]
Description=UDP Custom Service
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/udp-custom server -c /etc/udp-custom/config.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable udp-custom > /dev/null 2>&1
  systemctl restart udp-custom > /dev/null 2>&1
  ok "UDP Custom aktif (25525)."

  # ── ZIVPN UDP ─────────────────────────────────────────────────
  info "Install ZIVPN UDP (port 5667)..."
  mkdir -p /etc/zivpn
  if [[ "$ARCH" == "amd64" ]]; then
    wget -q "$ZIVPN_AMD64" -O /usr/local/bin/zivpn
  else
    wget -q "$ZIVPN_ARM64" -O /usr/local/bin/zivpn
  fi
  chmod +x /usr/local/bin/zivpn 2>/dev/null
  cat > /etc/zivpn/config.json <<'EOF'
{
  "listen": ":5667",
  "protocol": "udp",
  "obfs": "zivpn",
  "auth": {"mode": "passwords", "config": []},
  "remote_addr": "127.0.0.1:22"
}
EOF
  cat > /etc/systemd/system/zivpn.service <<'EOF'
[Unit]
Description=ZIVPN UDP Service
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/zivpn -c /etc/zivpn/config.json
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable zivpn > /dev/null 2>&1
  systemctl restart zivpn > /dev/null 2>&1
  # iptables redirect udp 5000-9999 ke zivpn
  local IFACE=$(ip -4 route ls 2>/dev/null | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
  iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 5000:9999 -j DNAT --to-destination :5667 2>/dev/null
  ok "ZIVPN UDP aktif (5667, range 5000-9999)."

  # ── Xray (VMess/VLess/Trojan TLS+nTLS) ───────────────────────
  info "Install Xray-core ${XRAY_VER}..."
  _inst_xray

  # ── Squid Proxy ───────────────────────────────────────────────
  info "Konfigurasi Squid Proxy (3128/8080)..."
  cat > /etc/squid/squid.conf <<'EOF'
http_port 3128
http_port 8080
http_port 8000
acl localnet src 0.0.0.1-0.255.255.255
acl localnet src 10.0.0.0/8
acl localnet src 100.64.0.0/10
acl localnet src 169.254.0.0/16
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl localnet src fc00::/7
acl localnet src fe80::/10
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
http_access allow all
http_reply_access allow all
icp_access allow all
forwarded_for off
request_header_access Allow allow all
request_header_access Authorization allow all
request_header_access WWW-Authenticate allow all
request_header_access Proxy-Authorization allow all
request_header_access Proxy-Authenticate allow all
request_header_access Cache-Control allow all
request_header_access Content-Encoding allow all
request_header_access Content-Length allow all
request_header_access Content-Type allow all
request_header_access Date allow all
request_header_access Expires allow all
request_header_access Host allow all
request_header_access If-Modified-Since allow all
request_header_access Last-Modified allow all
request_header_access Location allow all
request_header_access Pragma allow all
request_header_access Accept allow all
request_header_access Accept-Charset allow all
request_header_access Accept-Encoding allow all
request_header_access Accept-Language allow all
request_header_access Content-Language allow all
request_header_access Mime-Version allow all
request_header_access Retry-After allow all
request_header_access Title allow all
request_header_access Connection allow all
request_header_access Proxy-Connection allow all
request_header_access User-Agent allow all
request_header_access Cookie allow all
request_header_access All deny all
EOF
  systemctl enable squid > /dev/null 2>&1
  systemctl restart squid > /dev/null 2>&1
  ok "Squid Proxy aktif (3128/8080/8000)."

  # ── UFW Firewall ──────────────────────────────────────────────
  info "Konfigurasi UFW Firewall..."
  ufw --force disable > /dev/null 2>&1
  ufw --force reset > /dev/null 2>&1
  ufw default deny incoming > /dev/null 2>&1
  ufw default allow outgoing > /dev/null 2>&1
  for P in 22 69 80 109 143 443 444 554 777 1194 2083 2222 \
           3128 5667 7100 7200 7300 8000 8008 8080 8443 8444 \
           8445 8446 8553 8554 8880 25525; do
    ufw allow "$P" > /dev/null 2>&1
  done
  ufw allow 5000:9999/udp > /dev/null 2>&1
  ufw --force enable > /dev/null 2>&1
  ok "UFW Firewall aktif."

  # ── Simpan iptables ───────────────────────────────────────────
  netfilter-persistent save > /dev/null 2>&1

  # ── Setup pemanggil menu (ketik 'menu') ───────────────────────
  _setup_menu_cmd

  # ── Tandai sudah terinstall ───────────────────────────────────
  mkdir -p "$PANEL_DIR"
  date > "$INSTALLED_FLAG"
  echo "$(. /etc/os-release && echo "$PRETTY_NAME")" >> "$INSTALLED_FLAG"

  echo ""
  bl_line
  echo -e "  ${BLB}${BOLD}INSTALASI SELESAI!${NC}"
  bl_line
  echo -e "  ${CB}Semua layanan berhasil diinstall & dikonfigurasi.${NC}"
  echo -e "  ${W}Ketik ${Y}menu${W} untuk membuka panel kapan saja.${NC}"
  bl_line
  echo ""
  press_enter
}

# ── Setup alias 'menu' ────────────────────────────────────────────
_setup_menu_cmd(){
  local SCRIPT_PATH=$(realpath "$0" 2>/dev/null || echo "/usr/local/bin/nexus-panel")
  # Salin ke /usr/local/bin jika belum ada
  if [[ ! -f "/usr/local/bin/nexus-panel" ]]; then
    cp "$SCRIPT_PATH" /usr/local/bin/nexus-panel 2>/dev/null
    chmod +x /usr/local/bin/nexus-panel
  fi
  # Buat symlink 'menu'
  ln -sf /usr/local/bin/nexus-panel /usr/local/bin/menu 2>/dev/null
  chmod +x /usr/local/bin/menu 2>/dev/null

  # Tambah ke .bashrc & /etc/profile untuk semua user
  local ENTRY='alias menu="sudo nexus-panel"'
  for F in /root/.bashrc /etc/skel/.bashrc; do
    grep -q "alias menu=" "$F" 2>/dev/null || echo "$ENTRY" >> "$F"
  done

  # Tambah ke /etc/profile.d/ agar berlaku global
  cat > /etc/profile.d/nexus-menu.sh <<'MENUEOF'
#!/bin/bash
alias menu='nexus-panel'
MENUEOF
  chmod +x /etc/profile.d/nexus-menu.sh
  ok "Pemanggil menu terdaftar. Ketik ${Y}menu${NC} untuk membuka panel."
}

# =================================================================
#   INSTALL XRAY — VMess/VLess/Trojan TLS & nTLS
# =================================================================
_inst_xray(){
  apt-get install -y -qq openssl nginx > /dev/null 2>&1

  if ! bash -c "$(curl -Ls "$XRAY_INSTALL_URL")" @ install -u root > /dev/null 2>&1; then
    local ARCH=$(get_arch)
    apt-get install -y -qq unzip > /dev/null 2>&1
    [[ "$ARCH" == "amd64" ]] && wget -q "$XRAY_ZIP_AMD64" -O /tmp/xray.zip || \
      wget -q "$XRAY_ZIP_ARM64" -O /tmp/xray.zip
    unzip -q /tmp/xray.zip -d /tmp/xb && cp /tmp/xb/xray "$XRAY_BIN" && chmod +x "$XRAY_BIN"
    rm -rf /tmp/xray.zip /tmp/xb
  fi

  mkdir -p "$XRAY_DIR" /var/log/xray
  local UUID=$(gen_uuid)
  echo "$UUID" > "$PANEL_DIR/xray_master_uuid"

  openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=US/ST=CA/L=LA/O=OGH/CN=$(get_dom)" \
    -keyout "$XRAY_DIR/xray.key" \
    -out "$XRAY_DIR/xray.crt" > /dev/null 2>&1

  cat > "$XRAY_CFG" <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "tag": "vmess-ws-ntls",
      "port": 8443,
      "protocol": "vmess",
      "settings": { "clients": [{"id":"$UUID","alterId":0,"email":"default@ogh"}] },
      "streamSettings": {"network": "ws","wsSettings": {"path": "/vmess-ntls"}}
    },
    {
      "tag": "vmess-ws-tls",
      "port": 8553,
      "protocol": "vmess",
      "settings": { "clients": [{"id":"$UUID","alterId":0,"email":"default@ogh"}] },
      "streamSettings": {
        "network": "ws","security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile":"$XRAY_DIR/xray.crt","keyFile":"$XRAY_DIR/xray.key"}]},
        "wsSettings": {"path": "/vmess-tls"}
      }
    },
    {
      "tag": "vmess-tcp-ntls",
      "port": 1194,
      "protocol": "vmess",
      "settings": { "clients": [{"id":"$UUID","alterId":0,"email":"default@ogh"}] },
      "streamSettings": {"network": "tcp"}
    },
    {
      "tag": "vmess-tcp-tls",
      "port": 2083,
      "protocol": "vmess",
      "settings": { "clients": [{"id":"$UUID","alterId":0,"email":"default@ogh"}] },
      "streamSettings": {
        "network": "tcp","security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile":"$XRAY_DIR/xray.crt","keyFile":"$XRAY_DIR/xray.key"}]}
      }
    },
    {
      "tag": "vless-ws-ntls",
      "port": 8444,
      "protocol": "vless",
      "settings": { "clients": [{"id":"$UUID","email":"default@ogh"}], "decryption":"none" },
      "streamSettings": {"network": "ws","wsSettings": {"path": "/vless-ntls"}}
    },
    {
      "tag": "vless-ws-tls",
      "port": 8554,
      "protocol": "vless",
      "settings": { "clients": [{"id":"$UUID","email":"default@ogh"}], "decryption":"none" },
      "streamSettings": {
        "network": "ws","security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile":"$XRAY_DIR/xray.crt","keyFile":"$XRAY_DIR/xray.key"}]},
        "wsSettings": {"path": "/vless-tls"}
      }
    },
    {
      "tag": "trojan-ntls",
      "port": 8445,
      "protocol": "trojan",
      "settings": { "clients": [{"password":"ogh-trojan","email":"default@ogh"}] },
      "streamSettings": {"network": "tcp"}
    },
    {
      "tag": "trojan-tls",
      "port": 8446,
      "protocol": "trojan",
      "settings": { "clients": [{"password":"ogh-trojan","email":"default@ogh"}] },
      "streamSettings": {
        "network": "tcp","security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile":"$XRAY_DIR/xray.crt","keyFile":"$XRAY_DIR/xray.key"}]}
      }
    }
  ],
  "outbounds": [
    {"protocol":"freedom","tag":"direct"},
    {"protocol":"blackhole","tag":"block"}
  ],
  "routing": {
    "rules": [{"type":"field","ip":["geoip:private"],"outboundTag":"block"}]
  }
}
EOF

  cat > /etc/systemd/system/xray.service <<'EOF'
[Unit]
Description=Xray Service - VMess/VLess/Trojan TLS & nTLS
After=network.target nss-lookup.target
[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now xray > /dev/null 2>&1
  ok "Xray ${XRAY_VER} — 8 inbound aktif."
}

# =================================================================
#   HEADER PANEL
# =================================================================
header(){
  clear
  local IP=$(get_ip)
  local DOM=$(get_dom)
  local NOW=$(date '+%d/%m/%Y %H:%M:%S')
  local OS=$(lsb_release -ds 2>/dev/null | tr -d '"' || grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
  local UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
  local CPU=$(top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{printf "%.1f", $2+$4}')
  local RAM_USED=$(free -h 2>/dev/null | awk '/^Mem:/{print $3}')
  local RAM_TOTAL=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}')
  local DISK=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}')
  local IFACE=$(ip -4 route ls 2>/dev/null | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
  local LOAD=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null)
  local CONN=$(ss -tnp 2>/dev/null | grep -c ESTAB || echo "0")
  local XSTAT=""; systemctl is-active --quiet xray 2>/dev/null && XSTAT="${GB}ON${NC}" || XSTAT="${R}OFF${NC}"
  local SSTAT=""; systemctl is-active --quiet ssh 2>/dev/null && SSTAT="${GB}ON${NC}" || SSTAT="${R}OFF${NC}"
  local USTAT=""; systemctl is-active --quiet udp-custom 2>/dev/null && USTAT="${GB}ON${NC}" || USTAT="${R}OFF${NC}"
  local ZSTAT=""; systemctl is-active --quiet zivpn 2>/dev/null && ZSTAT="${GB}ON${NC}" || ZSTAT="${R}OFF${NC}"

  # ══ LOGO OGH-PANELL (gaya /|\ _ slant) ══════════════════════
  echo -e "${BLB}┌──────────────────────────────────────────────────────────────┐${NC}"
  echo -e "${BL}  ___    ____  _   _         ____    ___   _   _  _____  _      _    ${NC}"
  echo -e "${BLB} /   \\  / ___|| | | |       |  _ \\  / _ \\ | \\ | ||  ___|| |    | |   ${NC}"
  echo -e "${CBB}| | | || |  _ | |_| | ----- | |_) |/ /_\\ \\|  \\| || |__  | |    | |   ${NC}"
  echo -e "${CB}| |_| || |_| ||  _  |       |  __/ /  _  \\| |\\  ||  __| | |___ | |___${NC}"
  echo -e "${BL} \\___/  \\____||_| |_|       |_|    \\_/ \\_/|_| \\_||_____||_____||_____|${NC}"
  echo -e "${BLB}├──────────────────────────────────────────────────────────────┤${NC}"
  echo -e "${BLB}│${NC}  ${W}${BOLD}  VPS Manager v3.2   SSH+UDP+VMess+VLess+Trojan${NC}              ${BLB}│${NC}"
  echo -e "${BLB}│${NC}  ${CB}  Debian 10/11/12  |  Ubuntu 20.04 / 22.04 / 24.04${NC}          ${BLB}│${NC}"
  echo -e "${BLB}├──────────────────────────────────────────────────────────────┤${NC}"

  # ── INFO SERVER ───────────────────────────────────────────────
  printf "${BLB}│${NC}  ${BL}%-12s${NC}${W}%-20s${NC}  ${BL}%-12s${NC}${W}%-14s${NC}  ${BLB}│${NC}\n" \
    "IP Publik :" "$IP" "Domain    :" "$DOM"
  printf "${BLB}│${NC}  ${BL}%-12s${NC}${CB}%-20s${NC}  ${BL}%-12s${NC}${CB}%-14s${NC}  ${BLB}│${NC}\n" \
    "OS        :" "${OS:0:20}" "Uptime    :" "${UPTIME:0:14}"
  printf "${BLB}│${NC}  ${BL}%-12s${NC}${Y}%-20s${NC}  ${BL}%-12s${NC}${Y}%-14s${NC}  ${BLB}│${NC}\n" \
    "CPU Usage :" "${CPU}%" "Load Avg  :" "$LOAD"
  printf "${BLB}│${NC}  ${BL}%-12s${NC}${GB}%-20s${NC}  ${BL}%-12s${NC}${GB}%-14s${NC}  ${BLB}│${NC}\n" \
    "RAM       :" "${RAM_USED}/${RAM_TOTAL}" "Disk /    :" "${DISK:0:14}"
  printf "${BLB}│${NC}  ${BL}%-12s${NC}${W}%-20s${NC}  ${BL}%-12s${NC}${W}%-14s${NC}  ${BLB}│${NC}\n" \
    "Interface :" "$IFACE" "Koneksi   :" "${CONN} aktif"
  echo -e "${BLB}├──────────────────────────────────────────────────────────────┤${NC}"
  printf "${BLB}│${NC}  ${BL}%-10s${NC}${W}%-22s${NC}  ${BL}%-12s${NC}${CB}%-12s${NC}       ${BLB}│${NC}\n" \
    "Waktu   :" "$NOW" "Panel v   :" "3.2 (Blue)"
  echo -e "${BLB}├──────────────────────────────────────────────────────────────┤${NC}"
  printf "${BLB}│${NC}  ${BL}SSH :${NC}%b   ${BL}Xray :${NC}%b   ${BL}UDP-Custom :${NC}%b   ${BL}ZIVPN :${NC}%b      ${BLB}│${NC}\n" \
    "$SSTAT" "$XSTAT" "$USTAT" "$ZSTAT"
  echo -e "${BLB}└──────────────────────────────────────────────────────────────┘${NC}"
  echo ""
}

sub_hdr(){
  bl_line2
  echo -e "  ${BLB}${BOLD}▌ ${1}${NC}"
  bl_line2
  echo ""
}

# =================================================================
#   MAIN MENU
# =================================================================
main_menu(){
  check_root
  check_os_support
  mkdir -p "$PANEL_DIR/backup" "$XRAY_DIR"
  touch "$USERS_DB" "$UDPC_DB" "$ZIVPN_DB" "$XRAY_DB" "$LOG_FILE" 2>/dev/null

  # ── Cek apakah pertama kali jalan ────────────────────────────
  if [[ ! -f "$INSTALLED_FLAG" ]]; then
    echo ""
    echo -e "${BLB}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLB}║${NC}  ${W}${BOLD}  SELAMAT DATANG DI OGH-PANELL v3.2${NC}               ${BLB}║${NC}"
    echo -e "${BLB}║${NC}  ${CB}  Script ini belum pernah diinstall.${NC}               ${BLB}║${NC}"
    echo -e "${BLB}║${NC}  ${Y}  Install otomatis semua layanan sekarang?${NC}          ${BLB}║${NC}"
    echo -e "${BLB}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -rp "$(echo -e "  ${CBB}Install sekarang? ${W}[y/N]${NC}: ")" CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      do_install_all
    else
      warn "Instalasi dilewati. Beberapa fitur mungkin tidak berfungsi."
      sleep 2
    fi
  fi

  while true; do
    header
    # Status service
    printf "  ${BL}%-24s${NC}%b  ${BL}%-24s${NC}%b\n" \
      "SSH / Dropbear"    "$(svc_stat ssh)" \
      "UDP Custom"        "$(svc_stat udp-custom)"
    printf "  ${BL}%-24s${NC}%b  ${BL}%-24s${NC}%b\n" \
      "WebSocket (80)"    "$(svc_stat ws-ssh-80)" \
      "ZIVPN UDP"         "$(svc_stat zivpn)"
    printf "  ${BL}%-24s${NC}%b  ${BL}%-24s${NC}%b\n" \
      "Stunnel4 SSL"      "$(svc_stat stunnel4)" \
      "Xray (V2Ray)"      "$(svc_stat xray)"
    echo ""
    bl_line

    echo -e "  ${BLB}[${W}1${BLB}]${NC}  ${W}Manajemen SSH${NC}              ${D}│${NC}  ${BLB}[${W}7${BLB}]${NC}  ${W}Monitor Server${NC}"
    echo -e "  ${BLB}[${W}2${BLB}]${NC}  ${W}Manajemen UDP Custom${NC}       ${D}│${NC}  ${BLB}[${W}8${BLB}]${NC}  ${W}Info Server & Port${NC}"
    echo -e "  ${BLB}[${W}3${BLB}]${NC}  ${W}Manajemen ZIVPN UDP${NC}        ${D}│${NC}  ${BLB}[${W}9${BLB}]${NC}  ${W}Log & Riwayat${NC}"
    echo -e "  ${BLB}[${W}4${BLB}]${NC}  ${W}Manajemen Xray${NC}             ${D}│${NC}  ${BLB}[${W}10${BLB}]${NC} ${W}Pengaturan Panel${NC}"
    echo -e "  ${D}      ${W}└─ VMess/VLess/Trojan TLS+nTLS${NC} ${D}│${NC}  ${BLB}[${W}11${BLB}]${NC} ${W}Install Ulang Layanan${NC}"
    echo -e "  ${BLB}[${W}5${BLB}]${NC}  ${W}Kelola Service${NC}             ${D}│${NC}  ${BLB}[${W}12${BLB}]${NC} ${W}Info Sumber Binary${NC}"
    echo -e "  ${BLB}[${W}6${BLB}]${NC}  ${W}Speedtest VPS${NC}              ${D}│${NC}  ${BLB}[${W}13${BLB}]${NC} ${W}Update Script${NC}"

    bl_line
    echo -e "  ${BL}[${W}0${BL}]${NC}  ${W}Keluar${NC}"
    bl_line
    echo ""
    read -rp "$(echo -e "  ${CBB}Pilih Menu ${W}[0-13]${CBB} : ${NC}")" MENU

    case "$MENU" in
      1)  menu_ssh ;;
      2)  menu_udpc ;;
      3)  menu_zivpn ;;
      4)  menu_xray ;;
      5)  menu_service ;;
      6)  menu_speedtest ;;
      7)  menu_monitor ;;
      8)  header; _show_all_info; press_enter ;;
      9)  menu_log ;;
      10) menu_setting ;;
      11) rm -f "$INSTALLED_FLAG"; do_install_all ;;
      12) _info_bin ;;
      13) _update_script ;;
      0)  clear
          echo -e "${BLB}╔══════════════════════════════════════╗${NC}"
          echo -e "${BLB}║${NC}  ${W}Terima kasih, sampai jumpa!${NC}         ${BLB}║${NC}"
          echo -e "${BLB}║${NC}  ${CB}OGH-PANELL v3.2 — Debian & Ubuntu${NC}  ${BLB}║${NC}"
          echo -e "${BLB}╚══════════════════════════════════════╝${NC}"
          echo ""
          exit 0 ;;
      *) err "Pilihan tidak valid!"; sleep 1 ;;
    esac
  done
}

# ── Update script ─────────────────────────────────────────────────
_update_script(){
  header; sub_hdr "UPDATE SCRIPT"
  warn "Fitur update otomatis — salin script terbaru ke /usr/local/bin/nexus-panel"
  echo ""
  read -rp "$(echo -e "  ${CBB}URL script baru (kosong=skip): ${NC}")" URL
  if [[ -n "$URL" ]]; then
    wget -q "$URL" -O /usr/local/bin/nexus-panel && chmod +x /usr/local/bin/nexus-panel
    ok "Script diperbarui. Jalankan ulang."; exit 0
  else
    info "Update dilewati."
  fi
  press_enter
}

# =================================================================
#   MENU XRAY
# =================================================================
menu_xray(){
  while true; do
    header; sub_hdr "MANAJEMEN XRAY — VMess / VLess / Trojan (TLS & nTLS)"
    local XSTAT=$(svc_stat xray)
    local MUUID=$([[ -f "$PANEL_DIR/xray_master_uuid" ]] && cat "$PANEL_DIR/xray_master_uuid" || echo "-")
    echo -e "  ${BL}Status:${NC} $XSTAT   ${BL}Master UUID:${NC} ${CB}${MUUID:0:24}...${NC}"
    echo ""; bl_line2

    echo -e "  ${BLB}[${W}01${BLB}]${NC} ${W}Tambah VMess nTLS (WS:8443)${NC}    ${D}│${NC}  ${BLB}[${W}10${BLB}]${NC} ${W}Tambah VMess TLS (WS:8553)${NC}"
    echo -e "  ${BLB}[${W}02${BLB}]${NC} ${W}Tambah VMess nTLS (TCP:1194)${NC}   ${D}│${NC}  ${BLB}[${W}11${BLB}]${NC} ${W}Tambah VMess TLS (TCP:2083)${NC}"
    bl_line2
    echo -e "  ${BLB}[${W}03${BLB}]${NC} ${W}Tambah VLess nTLS (WS:8444)${NC}    ${D}│${NC}  ${BLB}[${W}12${BLB}]${NC} ${W}Tambah VLess TLS (WS:8554)${NC}"
    bl_line2
    echo -e "  ${BLB}[${W}04${BLB}]${NC} ${W}Tambah Trojan nTLS (TCP:8445)${NC}  ${D}│${NC}  ${BLB}[${W}13${BLB}]${NC} ${W}Tambah Trojan TLS (TCP:8446)${NC}"
    bl_line2
    echo -e "  ${BLB}[${W}05${BLB}]${NC} ${W}Daftar Semua User Xray${NC}         ${D}│${NC}  ${BLB}[${W}14${BLB}]${NC} ${W}Hapus User Xray${NC}"
    echo -e "  ${BLB}[${W}06${BLB}]${NC} ${W}Info Koneksi VMess nTLS${NC}        ${D}│${NC}  ${BLB}[${W}15${BLB}]${NC} ${W}Info Koneksi VMess TLS${NC}"
    echo -e "  ${BLB}[${W}07${BLB}]${NC} ${W}Info Koneksi VLess nTLS${NC}        ${D}│${NC}  ${BLB}[${W}16${BLB}]${NC} ${W}Info Koneksi VLess TLS${NC}"
    echo -e "  ${BLB}[${W}08${BLB}]${NC} ${W}Info Koneksi Trojan nTLS${NC}       ${D}│${NC}  ${BLB}[${W}17${BLB}]${NC} ${W}Info Koneksi Trojan TLS${NC}"
    echo -e "  ${BLB}[${W}09${BLB}]${NC} ${W}Ubah Port Xray${NC}                 ${D}│${NC}  ${BLB}[${W}18${BLB}]${NC} ${W}Renew SSL Cert Xray${NC}"
    bl_line2
    echo -e "  ${BLB}[${W}19${BLB}]${NC} ${W}Restart Xray${NC}  ${BLB}[${W}20${BLB}]${NC} ${W}Lihat Config${NC}  ${BLB}[${W}21${BLB}]${NC} ${W}Log Xray${NC}"
    bl_line2
    echo -e "  ${BL}[${W}00${BL}]${NC} ${W}Kembali${NC}"; bl_line2; echo ""
    read -rp "$(echo -e "  ${CBB}Pilih [00-21] : ${NC}")" CH

    case "$CH" in
      01|1)  _xray_add "vmess" "ntls" "ws"  "8443" "/vmess-ntls" ;;
      02|2)  _xray_add "vmess" "ntls" "tcp" "1194" "" ;;
      03|3)  _xray_add "vless" "ntls" "ws"  "8444" "/vless-ntls" ;;
      04|4)  _xray_add_trojan "ntls" "8445" ;;
      05|5)  _xray_list ;;
      06|6)  _xray_info_detail "vmess"  "ntls" "8443" "ws"  "/vmess-ntls" ;;
      07|7)  _xray_info_detail "vless"  "ntls" "8444" "ws"  "/vless-ntls" ;;
      08|8)  _xray_info_detail "trojan" "ntls" "8445" "tcp" "" ;;
      09|9)  _xray_ubah_port ;;
      10)    _xray_add "vmess" "tls" "ws"  "8553" "/vmess-tls" ;;
      11)    _xray_add "vmess" "tls" "tcp" "2083" "" ;;
      12)    _xray_add "vless" "tls" "ws"  "8554" "/vless-tls" ;;
      13)    _xray_add_trojan "tls" "8446" ;;
      14)    _xray_del ;;
      15)    _xray_info_detail "vmess"  "tls" "8553" "ws"  "/vmess-tls" ;;
      16)    _xray_info_detail "vless"  "tls" "8554" "ws"  "/vless-tls" ;;
      17)    _xray_info_detail "trojan" "tls" "8446" "tcp" "" ;;
      18)    _xray_renew_ssl ;;
      19)    systemctl restart xray > /dev/null 2>&1 && ok "Xray di-restart." && sleep 1 ;;
      20)    cat "$XRAY_CFG" 2>/dev/null; press_enter ;;
      21)    tail -50 /var/log/xray/access.log 2>/dev/null; journalctl -u xray -n 30 --no-pager; press_enter ;;
      00|0)  return ;;
      *)     warn "Tidak valid"; sleep 1 ;;
    esac
  done
}

_xray_add(){
  local PROTO="$1" TLSMODE="$2" NET="$3" PORT="$4" PATH_WS="$5"
  local LABEL_TLS=""; [[ "$TLSMODE" == "tls" ]] && LABEL_TLS=" (TLS)" || LABEL_TLS=" (nTLS/Plain)"
  local PNAME="${PROTO^^}${LABEL_TLS} — ${NET^^}:${PORT}"

  header; sub_hdr "TAMBAH USER $PNAME"
  read -rp "$(echo -e "  ${CBB}Email/nama user : ${NC}")" EMAIL
  read -rp "$(echo -e "  ${CBB}Expired (hari)  : ${NC}")" DAYS
  [[ -z "$EMAIL" ]] && err "Email wajib!" && press_enter && return

  local UUID=$(gen_uuid)
  local EXP=$(date -d "+${DAYS:-30} days" +"%Y-%m-%d")

  local TAG=""
  if   [[ "$PROTO" == "vmess" && "$TLSMODE" == "ntls" && "$NET" == "ws"  ]]; then TAG="vmess-ws-ntls"
  elif [[ "$PROTO" == "vmess" && "$TLSMODE" == "ntls" && "$NET" == "tcp" ]]; then TAG="vmess-tcp-ntls"
  elif [[ "$PROTO" == "vmess" && "$TLSMODE" == "tls"  && "$NET" == "ws"  ]]; then TAG="vmess-ws-tls"
  elif [[ "$PROTO" == "vmess" && "$TLSMODE" == "tls"  && "$NET" == "tcp" ]]; then TAG="vmess-tcp-tls"
  elif [[ "$PROTO" == "vless" && "$TLSMODE" == "ntls" ]]; then TAG="vless-ws-ntls"
  elif [[ "$PROTO" == "vless" && "$TLSMODE" == "tls"  ]]; then TAG="vless-ws-tls"
  fi

  python3 - <<PYEOF
import json
try:
    with open('$XRAY_CFG','r') as f: c=json.load(f)
    for ib in c.get('inbounds',[]):
        if ib.get('tag')=='$TAG':
            entry={'id':'$UUID','alterId':0,'email':'$EMAIL'} if '$PROTO'=='vmess' else {'id':'$UUID','email':'$EMAIL'}
            ib['settings']['clients'].append(entry)
    with open('$XRAY_CFG','w') as f: json.dump(c,f,indent=2)
    print("OK")
except Exception as e: print(f"ERR:{e}")
PYEOF

  echo "$EMAIL|$PROTO|$TLSMODE|$NET|$UUID|$EXP|$(date +%Y-%m-%d)" >> "$XRAY_DB"
  systemctl restart xray > /dev/null 2>&1

  local IP=$(get_ip) DOM=$(get_dom)
  echo ""; bl_line; ok "User ${PNAME} berhasil ditambah!"; bl_line
  echo -e "  ${BL}Email   :${NC} ${CB}$EMAIL${NC}"
  echo -e "  ${BL}UUID    :${NC} ${CB}$UUID${NC}"
  echo -e "  ${BL}Expired :${NC} ${Y}$EXP${NC}"
  echo -e "  ${BL}Server  :${NC} ${W}$IP${NC}"
  echo -e "  ${BL}Port    :${NC} ${W}$PORT${NC}"
  echo -e "  ${BL}Network :${NC} ${W}$NET${NC}"
  [[ -n "$PATH_WS" ]] && echo -e "  ${BL}Path    :${NC} ${W}$PATH_WS${NC}"
  echo -e "  ${BL}TLS     :${NC} ${W}$TLSMODE${NC}"
  bl_line
  if [[ "$PROTO" == "vmess" ]]; then
    local TLS_VAL=""; [[ "$TLSMODE" == "tls" ]] && TLS_VAL="tls"
    local JSON_OBJ="{\"v\":\"2\",\"ps\":\"$EMAIL\",\"add\":\"$IP\",\"port\":\"$PORT\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"$NET\",\"path\":\"$PATH_WS\",\"type\":\"none\",\"tls\":\"$TLS_VAL\"}"
    local B64=$(echo -n "$JSON_OBJ" | base64 -w0)
    echo -e "  ${CBB}VMess Link:${NC}"
    echo -e "  ${Y}vmess://${B64}${NC}"
  elif [[ "$PROTO" == "vless" ]]; then
    local TLS_PARAM=""; [[ "$TLSMODE" == "tls" ]] && TLS_PARAM="&security=tls" || TLS_PARAM="&security=none"
    echo -e "  ${CBB}VLess Link:${NC}"
    echo -e "  ${Y}vless://${UUID}@${IP}:${PORT}?type=${NET}&path=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$PATH_WS'))")${TLS_PARAM}#${EMAIL}${NC}"
  fi
  bl_line; press_enter
}

_xray_add_trojan(){
  local TLSMODE="$1" PORT="$2"
  local LABEL=""; [[ "$TLSMODE" == "tls" ]] && LABEL="TLS" || LABEL="nTLS/Plain"
  local TAG=""; [[ "$TLSMODE" == "tls" ]] && TAG="trojan-tls" || TAG="trojan-ntls"

  header; sub_hdr "TAMBAH USER TROJAN ${LABEL} (TCP:${PORT})"
  read -rp "$(echo -e "  ${CBB}Email/nama user : ${NC}")" EMAIL
  read -rp "$(echo -e "  ${CBB}Password Trojan : ${NC}")" TPASS
  read -rp "$(echo -e "  ${CBB}Expired (hari)  : ${NC}")" DAYS
  [[ -z "$EMAIL" || -z "$TPASS" ]] && err "Wajib diisi!" && press_enter && return

  local EXP=$(date -d "+${DAYS:-30} days" +"%Y-%m-%d")

  python3 - <<PYEOF
import json
try:
    with open('$XRAY_CFG','r') as f: c=json.load(f)
    for ib in c.get('inbounds',[]):
        if ib.get('tag')=='$TAG':
            ib['settings']['clients'].append({'password':'$TPASS','email':'$EMAIL'})
    with open('$XRAY_CFG','w') as f: json.dump(c,f,indent=2)
    print("OK")
except Exception as e: print(f"ERR:{e}")
PYEOF

  echo "$EMAIL|trojan|$TLSMODE|tcp|$TPASS|$EXP|$(date +%Y-%m-%d)" >> "$XRAY_DB"
  systemctl restart xray > /dev/null 2>&1

  local IP=$(get_ip)
  echo ""; bl_line; ok "User Trojan ${LABEL} berhasil ditambah!"; bl_line
  echo -e "  ${BL}Email    :${NC} ${CB}$EMAIL${NC}"
  echo -e "  ${BL}Password :${NC} ${CB}$TPASS${NC}"
  echo -e "  ${BL}Port     :${NC} ${W}$PORT${NC}"
  echo -e "  ${BL}TLS      :${NC} ${W}$TLSMODE${NC}"
  echo -e "  ${BL}Expired  :${NC} ${Y}$EXP${NC}"
  bl_line
  echo -e "  ${CBB}Trojan Link:${NC}"
  local TLS_PARAM=""; [[ "$TLSMODE" == "tls" ]] && TLS_PARAM="?security=tls&allowInsecure=1" || TLS_PARAM=""
  echo -e "  ${Y}trojan://${TPASS}@${IP}:${PORT}${TLS_PARAM}#${EMAIL}${NC}"
  bl_line; press_enter
}

_xray_info_detail(){
  local PROTO="$1" TLSMODE="$2" PORT="$3" NET="$4" PATHWS="$5"
  local LABEL=""; [[ "$TLSMODE" == "tls" ]] && LABEL="${GB}[TLS — Terenkripsi]${NC}" || LABEL="${Y}[nTLS — Plain/Tanpa Enkripsi]${NC}"
  local IP=$(get_ip)

  header; sub_hdr "INFO KONEKSI ${PROTO^^} ${TLSMODE^^}"
  echo ""; bl_line
  echo -e "  $LABEL"; bl_line
  echo -e "  ${BL}Protokol  :${NC} ${W}${PROTO^^}${NC}"
  echo -e "  ${BL}Server/IP :${NC} ${CB}$IP${NC}"
  echo -e "  ${BL}Port      :${NC} ${CB}$PORT${NC}"
  echo -e "  ${BL}Network   :${NC} ${W}$NET${NC}"
  [[ -n "$PATHWS" ]] && echo -e "  ${BL}Path      :${NC} ${W}$PATHWS${NC}"
  if [[ "$TLSMODE" == "tls" ]]; then
    echo -e "  ${BL}TLS       :${NC} ${GB}Aktif (self-signed cert)${NC}"
    echo -e "  ${BL}allowInsecure :${NC} ${Y}true${NC}  ${D}(self-signed)${NC}"
  else
    echo -e "  ${BL}TLS       :${NC} ${R}Tidak aktif (plain/non-TLS)${NC}"
  fi
  bl_line
  echo -e "  ${CBB}Users ${PROTO^^} ${TLSMODE^^}:${NC}"
  grep "|${PROTO}|${TLSMODE}|" "$XRAY_DB" 2>/dev/null | while IFS='|' read -r em pr tls net uid exp cr; do
    if [[ "$PROTO" == "trojan" ]]; then
      echo -e "  ${D}•${NC} ${W}$em${NC}  Pass: ${CB}$uid${NC}  Exp: ${Y}$exp${NC}"
    else
      echo -e "  ${D}•${NC} ${W}$em${NC}  UUID: ${CB}${uid:0:22}...${NC}  Exp: ${Y}$exp${NC}"
    fi
  done || echo -e "  ${D}(belum ada user)${NC}"
  bl_line; press_enter
}

_xray_list(){
  header; sub_hdr "SEMUA USER XRAY"
  printf "  ${Y}%-18s %-7s %-5s %-4s %-26s %-12s %s${NC}\n" \
    "EMAIL" "PROTO" "TLS" "NET" "UUID/PASS" "EXPIRED" "DIBUAT"
  bl_line2
  if [[ ! -s "$XRAY_DB" ]]; then echo -e "  ${D}(Belum ada user)${NC}"
  else
    while IFS='|' read -r em pr tls net uid exp cr; do
      local TCOL=""; [[ "$tls" == "tls" ]] && TCOL="${GB}TLS${NC}" || TCOL="${Y}nTLS${NC}"
      printf "  ${W}%-18s${NC} ${CBB}%-7s${NC} %b  ${CB}%-4s${NC} ${D}%-26s${NC} ${Y}%-12s${NC} ${D}%s${NC}\n" \
        "${em:0:18}" "$pr" "$TCOL" "$net" "${uid:0:24}" "$exp" "${cr:-?}"
    done < "$XRAY_DB"
  fi
  bl_line2; press_enter
}

_xray_del(){
  header; sub_hdr "HAPUS USER XRAY"; _xray_list; echo ""
  read -rp "$(echo -e "  ${CBB}Email user : ${NC}")" EMAIL
  local LINE=$(grep "^$EMAIL|" "$XRAY_DB" | head -1)
  [[ -z "$LINE" ]] && err "User tidak ditemukan!" && press_enter && return
  IFS='|' read -r em pr tls net uid _ <<< "$LINE"

  python3 - <<PYEOF
import json
try:
    with open('$XRAY_CFG','r') as f: c=json.load(f)
    for ib in c.get('inbounds',[]):
        proto=ib.get('protocol','')
        if proto in ('vmess','vless'):
            ib['settings']['clients']=[x for x in ib['settings']['clients']
                if x.get('email')!='$EMAIL' and x.get('id')!='$uid']
        elif proto=='trojan':
            ib['settings']['clients']=[x for x in ib['settings']['clients']
                if x.get('email')!='$EMAIL' and x.get('password')!='$uid']
    with open('$XRAY_CFG','w') as f: json.dump(c,f,indent=2)
    print("OK")
except Exception as e: print(f"ERR:{e}")
PYEOF

  sed -i "/^$EMAIL|/d" "$XRAY_DB"
  systemctl restart xray > /dev/null 2>&1
  ok "User ${W}$EMAIL${NC} dihapus dari Xray."; press_enter
}

_xray_ubah_port(){
  header; sub_hdr "UBAH PORT XRAY"; echo ""
  echo -e "  ${BLB}[1]${NC} VMess nTLS WS  : ${Y}8443${NC}   ${BLB}[5]${NC} VMess TLS WS  : ${Y}8553${NC}"
  echo -e "  ${BLB}[2]${NC} VMess nTLS TCP : ${Y}1194${NC}   ${BLB}[6]${NC} VMess TLS TCP : ${Y}2083${NC}"
  echo -e "  ${BLB}[3]${NC} VLess nTLS WS  : ${Y}8444${NC}   ${BLB}[7]${NC} VLess TLS WS  : ${Y}8554${NC}"
  echo -e "  ${BLB}[4]${NC} Trojan nTLS    : ${Y}8445${NC}   ${BLB}[8]${NC} Trojan TLS    : ${Y}8446${NC}"
  echo -e "  ${BLB}[0]${NC} Kembali"; echo ""
  read -rp "$(echo -e "  ${CBB}Pilih : ${NC}")" C2
  local TAGS=("" "vmess-ws-ntls" "vmess-tcp-ntls" "vless-ws-ntls" "trojan-ntls" "vmess-ws-tls" "vmess-tcp-tls" "vless-ws-tls" "trojan-tls")
  [[ "$C2" == "0" ]] && return
  [[ "$C2" -ge 1 && "$C2" -le 8 ]] || { warn "Tidak valid"; press_enter; return; }
  local SEL_TAG="${TAGS[$C2]}"
  read -rp "$(echo -e "  ${CBB}Port baru untuk ${SEL_TAG} : ${NC}")" NP
  [[ ! "$NP" =~ ^[0-9]+$ ]] && err "Port tidak valid!" && press_enter && return
  python3 - <<PYEOF
import json
with open('$XRAY_CFG','r') as f: c=json.load(f)
for ib in c['inbounds']:
    if ib.get('tag')=='$SEL_TAG': ib['port']=$NP
with open('$XRAY_CFG','w') as f: json.dump(c,f,indent=2)
PYEOF
  ufw allow "$NP" > /dev/null 2>&1
  systemctl restart xray > /dev/null 2>&1
  ok "Port ${SEL_TAG} → ${Y}$NP${NC}"; press_enter
}

_xray_renew_ssl(){
  header; sub_hdr "RENEW SSL CERT XRAY"
  info "Membuat ulang sertifikat self-signed..."
  openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
    -subj "/C=US/ST=CA/L=LA/O=OGH/CN=$(get_dom)" \
    -keyout "$XRAY_DIR/xray.key" \
    -out "$XRAY_DIR/xray.crt" > /dev/null 2>&1
  systemctl restart xray > /dev/null 2>&1
  ok "SSL cert Xray diperbarui (3650 hari)."; press_enter
}

# =================================================================
#   INFO SERVER LENGKAP
# =================================================================
_show_all_info(){
  local IP=$(get_ip) DOM=$(get_dom)
  echo ""; bl_line
  echo -e "  ${BLB}${BOLD}═══ INFO LENGKAP SERVER & PORT ═══${NC}"; bl_line
  echo -e "\n  ${W}━━━ SSH & DROPBEAR ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  OpenSSH    : ${CB}$IP${NC}:${BLB}22${NC} / ${BLB}2222${NC}"
  echo -e "  Dropbear   : ${CB}$IP${NC}:${BLB}109${NC} / ${BLB}143${NC} / ${BLB}69${NC}"
  echo -e "  Websocket  : ${CB}$IP${NC}:${BLB}80${NC} / ${BLB}8880${NC} / ${BLB}8008${NC}"
  echo -e "  SSL/Stunnel: ${CB}$IP${NC}:${BLB}443${NC} / ${BLB}444${NC} / ${BLB}554${NC} / ${BLB}777${NC}"
  echo -e "\n  ${W}━━━ XRAY — nTLS (Plain) ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${Y}VMess WS nTLS ${NC}: ${CB}$IP${NC}:${BLB}8443${NC}  path:/vmess-ntls  ws"
  echo -e "  ${Y}VMess TCP nTLS${NC} : ${CB}$IP${NC}:${BLB}1194${NC}  tcp"
  echo -e "  ${Y}VLess WS nTLS ${NC}: ${CB}$IP${NC}:${BLB}8444${NC}  path:/vless-ntls  ws"
  echo -e "  ${Y}Trojan nTLS   ${NC}: ${CB}$IP${NC}:${BLB}8445${NC}  tcp"
  echo -e "\n  ${W}━━━ XRAY — TLS (Terenkripsi self-signed) ━━━━━━━━━━━━━━${NC}"
  echo -e "  ${GB}VMess WS TLS  ${NC}: ${CB}$IP${NC}:${BLB}8553${NC}  path:/vmess-tls  ws  tls:on"
  echo -e "  ${GB}VMess TCP TLS ${NC}: ${CB}$IP${NC}:${BLB}2083${NC}  tcp  tls:on"
  echo -e "  ${GB}VLess WS TLS  ${NC}: ${CB}$IP${NC}:${BLB}8554${NC}  path:/vless-tls  ws  tls:on"
  echo -e "  ${GB}Trojan TLS    ${NC}: ${CB}$IP${NC}:${BLB}8446${NC}  tcp  tls:on"
  echo -e "  ${D}(TLS menggunakan self-signed cert — aktifkan allowInsecure di client)${NC}"
  echo -e "\n  ${W}━━━ UDP ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  BadVPN     : ${BLB}127.0.0.1:7100${NC} / ${BLB}7200${NC} / ${BLB}7300${NC}"
  local UP=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(d.get('listen',':25525').lstrip(':'))" 2>/dev/null || echo "25525")
  echo -e "  UDP Custom : ${CB}$IP${NC}:${BLB}$UP${NC}  (all UDP)"
  local ZP=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(d.get('listen',':5667').lstrip(':'))" 2>/dev/null || echo "5667")
  echo -e "  ZIVPN UDP  : ${CB}$IP${NC}:${BLB}$ZP${NC}  (range 5000-9999)  obfs:zivpn"
  echo -e "\n  ${W}━━━ PROXY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  Squid      : ${CB}$IP${NC}:${BLB}3128${NC} / ${BLB}8080${NC} / ${BLB}8000${NC}"
  bl_line
}

# =================================================================
#   MENU SSH
# =================================================================
menu_ssh(){
  while true; do
    header; sub_hdr "MANAJEMEN AKUN SSH"
    local TOT=$(wc -l < "$USERS_DB" 2>/dev/null || echo 0)
    echo -e "  ${BL}Total akun :${NC} ${Y}${TOT}${NC}"; echo ""
    bl_line2
    echo -e "  ${BLB}[${W}01${BLB}]${NC} Buat Akun SSH    ${D}│${NC}  ${BLB}[${W}06${BLB}]${NC} Ganti Password"
    echo -e "  ${BLB}[${W}02${BLB}]${NC} Hapus Akun SSH   ${D}│${NC}  ${BLB}[${W}07${BLB}]${NC} Cek User Online"
    echo -e "  ${BLB}[${W}03${BLB}]${NC} Daftar Akun SSH  ${D}│${NC}  ${BLB}[${W}08${BLB}]${NC} Kick User"
    echo -e "  ${BLB}[${W}04${BLB}]${NC} Info Akun SSH    ${D}│${NC}  ${BLB}[${W}09${BLB}]${NC} Lock Akun"
    echo -e "  ${BLB}[${W}05${BLB}]${NC} Perpanjang Akun  ${D}│${NC}  ${BLB}[${W}10${BLB}]${NC} Unlock Akun"
    bl_line2; echo -e "  ${BL}[${W}00${BL}]${NC} Kembali"; bl_line2; echo ""
    read -rp "$(echo -e "  ${CBB}Pilih [00-10] : ${NC}")" CH
    case "$CH" in
      01|1) _ssh_buat ;;   02|2) _ssh_hapus ;;   03|3) _ssh_daftar ;;
      04|4) _ssh_info ;;   05|5) _ssh_panjang ;;  06|6) _ssh_pass ;;
      07|7) _ssh_online ;; 08|8) _ssh_kick ;;     09|9) _ssh_lock ;;
      10)   _ssh_unlock ;; 00|0) return ;;
      *) warn "Tidak valid"; sleep 1 ;;
    esac
  done
}

_ssh_buat(){
  header; sub_hdr "BUAT AKUN SSH"
  read -rp "$(echo -e "  ${CBB}Username       : ${NC}")" USR
  read -rsp "$(echo -e "  ${CBB}Password       : ${NC}")" PASS; echo ""
  read -rp "$(echo -e "  ${CBB}Expired (hari) : ${NC}")" DAYS
  read -rp "$(echo -e "  ${CBB}Limit IP (0=∞) : ${NC}")" LIM
  [[ -z "$USR" || -z "$PASS" || -z "$DAYS" ]] && err "Kolom wajib!" && press_enter && return
  id "$USR" &>/dev/null && err "Username sudah ada!" && press_enter && return
  local EXP=$(date -d "+${DAYS} days" +"%Y-%m-%d")
  useradd -e "$EXP" -s /bin/false -M "$USR" 2>/dev/null
  echo "$USR:$PASS" | chpasswd
  echo "$USR|$PASS|$EXP|$(date +%Y-%m-%d)|${LIM:-0}" >> "$USERS_DB"
  log "Buat SSH: $USR"
  local IP=$(get_ip)
  echo ""; bl_line; ok "Akun SSH dibuat!"; bl_line
  echo -e "  ${BL}Username :${NC} ${CB}$USR${NC}"
  echo -e "  ${BL}Password :${NC} ${CB}$PASS${NC}"
  echo -e "  ${BL}Expired  :${NC} ${Y}$EXP${NC}"
  echo -e "  ${BL}Server   :${NC} ${W}$IP${NC}"
  bl_line; press_enter
}

_ssh_hapus(){
  header; sub_hdr "HAPUS AKUN SSH"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CBB}Username : ${NC}")" USR
  ! id "$USR" &>/dev/null && err "Tidak ada!" && press_enter && return
  pkill -u "$USR" 2>/dev/null; userdel -r "$USR" 2>/dev/null
  sed -i "/^$USR|/d" "$USERS_DB"; ok "$USR dihapus."; press_enter
}

_ssh_daftar(){
  header; sub_hdr "DAFTAR AKUN SSH"
  printf "  ${Y}%-16s %-12s %-12s %-8s %s${NC}\n" "USERNAME" "EXPIRED" "DIBUAT" "LIMIT" "STATUS"
  bl_line2
  [[ ! -s "$USERS_DB" ]] && echo -e "  ${D}(kosong)${NC}" || {
    local TODAY=$(date +%Y-%m-%d)
    while IFS='|' read -r u p exp cr lim; do
      local SISA ST
      [[ "$exp" < "$TODAY" ]] && ST="${R}EXPIRED${NC}" && SISA=0 || {
        SISA=$(( ($(date -d "$exp" +%s)-$(date +%s))/86400 )); ST="${GB}AKTIF${NC}"; }
      printf "  ${W}%-16s${NC} ${Y}%-12s${NC} ${D}%-12s${NC} ${CB}%-8s${NC} %b ${D}(sisa: ${SISA}h)${NC}\n" \
        "$u" "$exp" "${cr:-?}" "${lim:-0}" "$ST"
    done < "$USERS_DB"; }
  bl_line2; press_enter
}

_ssh_info(){
  header; sub_hdr "INFO AKUN SSH"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CBB}Username : ${NC}")" USR
  ! id "$USR" &>/dev/null && err "Tidak ada!" && press_enter && return
  local LINE=$(grep "^$USR|" "$USERS_DB")
  IFS='|' read -r u p exp cr lim <<< "$LINE"
  local SISA=$(( ($(date -d "$exp" +%s)-$(date +%s))/86400 ))
  echo ""; bl_line
  echo -e "  ${BL}Username :${NC} ${CB}$u${NC}"
  echo -e "  ${BL}Password :${NC} ${CB}$p${NC}"
  echo -e "  ${BL}Expired  :${NC} ${Y}$exp${NC}  ${D}(sisa ${SISA} hari)${NC}"
  bl_line; press_enter
}

_ssh_panjang(){
  header; sub_hdr "PERPANJANG AKUN"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CBB}Username      : ${NC}")" USR
  read -rp "$(echo -e "  ${CBB}Tambah (hari) : ${NC}")" DAYS
  ! id "$USR" &>/dev/null && err "Tidak ada!" && press_enter && return
  local NE=$(date -d "+${DAYS} days" +"%Y-%m-%d")
  chage -E "$NE" "$USR" 2>/dev/null
  sed -i "s/^$USR|\([^|]*\)|\([^|]*\)|/$USR|\1|$NE|/" "$USERS_DB"
  ok "Diperpanjang → $NE"; press_enter
}

_ssh_pass(){
  header; sub_hdr "GANTI PASSWORD"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CBB}Username     : ${NC}")" USR
  read -rsp "$(echo -e "  ${CBB}Password baru: ${NC}")" NP; echo ""
  ! id "$USR" &>/dev/null && err "Tidak ada!" && press_enter && return
  echo "$USR:$NP" | chpasswd
  sed -i "s/^$USR|[^|]*|/$USR|$NP|/" "$USERS_DB"
  ok "Password $USR diubah."; press_enter
}

_ssh_online(){
  header; sub_hdr "USER ONLINE"
  printf "  ${Y}%-16s %-12s %-22s %s${NC}\n" "USER" "TERMINAL" "WAKTU" "IP"; bl_line2
  who | while read u t d1 d2 rest; do
    printf "  ${W}%-16s${NC} ${CB}%-12s${NC} ${D}%-22s${NC} ${GB}%s${NC}\n" \
      "$u" "$t" "$d1 $d2" "$(echo "$rest"|tr -d '()')"
  done; bl_line2; press_enter
}

_ssh_kick(){
  header; sub_hdr "KICK USER"; _ssh_online; echo ""
  read -rp "$(echo -e "  ${CBB}Username : ${NC}")" USR
  pkill -u "$USR" && ok "$USR diputuskan." || warn "Tidak ada sesi."; press_enter
}

_ssh_lock(){
  header; sub_hdr "LOCK AKUN"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CBB}Username : ${NC}")" USR
  usermod -e 1 "$USR" 2>/dev/null; ok "$USR di-LOCK."; press_enter
}

_ssh_unlock(){
  header; sub_hdr "UNLOCK AKUN"; _ssh_list_s; echo ""
  read -rp "$(echo -e "  ${CBB}Username : ${NC}")" USR
  local EXP=$(grep "^$USR|" "$USERS_DB" | cut -d'|' -f3)
  usermod -e "$EXP" "$USR" 2>/dev/null; ok "$USR di-UNLOCK."; press_enter
}

_ssh_list_s(){
  echo -e "  ${Y}Daftar Akun:${NC}"
  [[ -s "$USERS_DB" ]] && while IFS='|' read -r u p exp _; do
    echo -e "  ${D}•${NC} ${W}$u${NC}  ${BL}exp:${NC} ${CB}$exp${NC}"
  done < "$USERS_DB" || echo -e "  ${D}(kosong)${NC}"
}

# =================================================================
#   MENU UDP CUSTOM
# =================================================================
menu_udpc(){
  while true; do
    header; sub_hdr "MANAJEMEN UDP CUSTOM"
    local UPORT=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(d.get('listen',':25525').lstrip(':'))" 2>/dev/null||echo "25525")
    echo -e "  ${BL}Status:${NC} $(svc_stat udp-custom)  ${BL}Port:${NC} ${Y}$UPORT${NC}"; echo ""; bl_line2
    echo -e "  ${BLB}[1]${NC} Buat  ${BLB}[2]${NC} Hapus  ${BLB}[3]${NC} Daftar  ${BLB}[4]${NC} Info  ${BLB}[5]${NC} Ganti Port  ${BL}[0]${NC} Kembali"
    bl_line2; echo ""
    read -rp "$(echo -e "  ${CBB}Pilih : ${NC}")" CH
    case "$CH" in
      1) _udpc_buat ;;  2) _udpc_hapus ;; 3) _udpc_daftar ;;
      4) _udpc_info ;;  5) _udpc_port ;;  0) return ;;
    esac
  done
}

_udpc_buat(){
  read -rp "$(echo -e "  ${CBB}Password       : ${NC}")" PASS
  read -rp "$(echo -e "  ${CBB}Expired (hari) : ${NC}")" DAYS
  python3 -c "
import json
with open('/etc/udp-custom/config.json','r') as f: d=json.load(f)
if 'auth' not in d: d['auth']={'mode':'passwords','config':[]}
if '$PASS' not in d['auth']['config']: d['auth']['config'].append('$PASS')
with open('/etc/udp-custom/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  local EXP=$(date -d "+${DAYS:-30} days" +"%Y-%m-%d")
  echo "$PASS|$EXP|$(date +%Y-%m-%d)" >> "$UDPC_DB"
  systemctl restart udp-custom > /dev/null 2>&1
  ok "Akun UDP Custom: ${CB}$PASS${NC}  exp: ${Y}$EXP${NC}"; press_enter
}

_udpc_hapus(){
  _udpc_list_s; echo ""
  read -rp "$(echo -e "  ${CBB}Password : ${NC}")" PASS
  python3 -c "
import json
with open('/etc/udp-custom/config.json','r') as f: d=json.load(f)
d['auth']['config']=[p for p in d['auth']['config'] if p!='$PASS']
with open('/etc/udp-custom/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  sed -i "/^$PASS|/d" "$UDPC_DB"
  systemctl restart udp-custom > /dev/null 2>&1; ok "$PASS dihapus."; press_enter
}

_udpc_daftar(){
  header; sub_hdr "DAFTAR UDP CUSTOM"
  local i=1
  python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));[print(p) for p in d['auth']['config']]" 2>/dev/null | while read P; do
    local E=$(grep "^$P|" "$UDPC_DB" | cut -d'|' -f2||echo "-")
    printf "  ${W}%-3s${NC} ${CB}%-22s${NC} ${Y}%s${NC}\n" "$i." "$P" "$E"; ((i++))
  done; press_enter
}

_udpc_info(){
  local IP=$(get_ip)
  local PORT=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(d.get('listen',':25525').lstrip(':'))" 2>/dev/null)
  local PASS=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(', '.join(d['auth']['config']))" 2>/dev/null)
  echo ""; bl_line
  echo -e "  ${CBB}UDP CUSTOM${NC}: ${CB}$IP:$PORT${NC}  Pass: ${Y}$PASS${NC}  Range: all UDP"
  bl_line; press_enter
}

_udpc_port(){
  local OLD=$(python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));print(d.get('listen',':25525').lstrip(':'))" 2>/dev/null)
  read -rp "$(echo -e "  ${CBB}Port baru (sekarang: $OLD): ${NC}")" NEW
  python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));d['listen']=f':$NEW';json.dump(d,open('/etc/udp-custom/config.json','w'),indent=2)" 2>/dev/null
  local IFACE=$(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1)
  iptables -t nat -D PREROUTING -i "$IFACE" -p udp --dport 1:65535 -j DNAT --to-destination :"$OLD" 2>/dev/null
  iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 1:65535 -j DNAT --to-destination :"$NEW" 2>/dev/null
  systemctl restart udp-custom > /dev/null 2>&1; ok "Port → $NEW"; press_enter
}

_udpc_list_s(){
  python3 -c "import json;d=json.load(open('/etc/udp-custom/config.json'));[print(f'  • {p}') for p in d['auth']['config']]" 2>/dev/null
}

# =================================================================
#   MENU ZIVPN
# =================================================================
menu_zivpn(){
  while true; do
    header; sub_hdr "MANAJEMEN ZIVPN UDP"
    local ZPORT=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(d.get('listen',':5667').lstrip(':'))" 2>/dev/null||echo "5667")
    echo -e "  ${BL}Status:${NC} $(svc_stat zivpn)  ${BL}Port:${NC} ${Y}$ZPORT${NC}"; echo ""; bl_line2
    echo -e "  ${BLB}[1]${NC} Buat  ${BLB}[2]${NC} Hapus  ${BLB}[3]${NC} Daftar  ${BLB}[4]${NC} Info  ${BLB}[5]${NC} Ganti Port  ${BL}[0]${NC} Kembali"
    bl_line2; echo ""
    read -rp "$(echo -e "  ${CBB}Pilih : ${NC}")" CH
    case "$CH" in
      1) _zivpn_buat ;; 2) _zivpn_hapus ;; 3) _zivpn_daftar ;;
      4) _zivpn_info ;; 5) _zivpn_port ;;  0) return ;;
    esac
  done
}

_zivpn_buat(){
  read -rp "$(echo -e "  ${CBB}Password       : ${NC}")" PASS
  read -rp "$(echo -e "  ${CBB}Expired (hari) : ${NC}")" DAYS
  python3 -c "
import json
with open('/etc/zivpn/config.json','r') as f: d=json.load(f)
if '$PASS' not in d['auth']['config']: d['auth']['config'].append('$PASS')
with open('/etc/zivpn/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  local EXP=$(date -d "+${DAYS:-30} days" +"%Y-%m-%d")
  echo "$PASS|$EXP|$(date +%Y-%m-%d)" >> "$ZIVPN_DB"
  systemctl restart zivpn > /dev/null 2>&1; ok "ZIVPN: ${CB}$PASS${NC}  exp: ${Y}$EXP${NC}"; press_enter
}

_zivpn_hapus(){
  _zivpn_list_s; echo ""
  read -rp "$(echo -e "  ${CBB}Password : ${NC}")" PASS
  python3 -c "
import json
with open('/etc/zivpn/config.json','r') as f: d=json.load(f)
d['auth']['config']=[p for p in d['auth']['config'] if p!='$PASS']
with open('/etc/zivpn/config.json','w') as f: json.dump(d,f,indent=2)
" 2>/dev/null
  sed -i "/^$PASS|/d" "$ZIVPN_DB"; systemctl restart zivpn > /dev/null 2>&1
  ok "$PASS dihapus."; press_enter
}

_zivpn_daftar(){
  header; sub_hdr "DAFTAR ZIVPN"
  local i=1
  python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));[print(p) for p in d['auth']['config']]" 2>/dev/null | while read P; do
    local E=$(grep "^$P|" "$ZIVPN_DB"|cut -d'|' -f2||echo "-")
    printf "  ${W}%-3s${NC} ${CBB}%-22s${NC} ${Y}%s${NC}\n" "$i." "$P" "$E"; ((i++))
  done; press_enter
}

_zivpn_info(){
  local IP=$(get_ip)
  local PORT=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(d.get('listen',':5667').lstrip(':'))" 2>/dev/null)
  local PASS=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(', '.join(d['auth']['config']))" 2>/dev/null)
  echo ""; bl_line
  echo -e "  ${CBB}ZIVPN${NC}: ${CB}$IP:$PORT${NC}  Pass: ${Y}$PASS${NC}  Obfs: zivpn"
  echo -e "  Range port: 5000-9999 → $PORT"
  bl_line; press_enter
}

_zivpn_port(){
  local OLD=$(python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));print(d.get('listen',':5667').lstrip(':'))" 2>/dev/null)
  read -rp "$(echo -e "  ${CBB}Port baru (sekarang: $OLD): ${NC}")" NEW
  python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));d['listen']=f':$NEW';json.dump(d,open('/etc/zivpn/config.json','w'),indent=2)" 2>/dev/null
  local IFACE=$(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1)
  iptables -t nat -D PREROUTING -i "$IFACE" -p udp --dport 5000:9999 -j DNAT --to-destination :"$OLD" 2>/dev/null
  iptables -t nat -A PREROUTING -i "$IFACE" -p udp --dport 5000:9999 -j DNAT --to-destination :"$NEW" 2>/dev/null
  systemctl restart zivpn > /dev/null 2>&1; ok "Port → $NEW"; press_enter
}

_zivpn_list_s(){
  python3 -c "import json;d=json.load(open('/etc/zivpn/config.json'));[print(f'  • {p}') for p in d['auth']['config']]" 2>/dev/null
}

# =================================================================
#   MENU SERVICE / MONITOR / SPEEDTEST / LOG / SETTING
# =================================================================
menu_service(){
  while true; do
    header; sub_hdr "KELOLA SERVICE"; echo ""
    for SVC in ssh dropbear ws-ssh-80 ws-ssh-8880 stunnel4 badvpn-7100 badvpn-7200 badvpn-7300 udp-custom zivpn xray squid nginx; do
      printf "  ${BL}%-32s${NC} %b\n" "$SVC" "$(svc_stat $SVC)"
    done
    echo ""; bl_line2
    echo -e "  ${BLB}[1]${NC} Restart Semua  ${BLB}[2]${NC} Restart SSH  ${BLB}[3]${NC} Restart UDP  ${BLB}[4]${NC} Restart Xray  ${BL}[0]${NC} Kembali"
    bl_line2; echo ""
    read -rp "$(echo -e "  ${CBB}Pilih : ${NC}")" CH
    case "$CH" in
      1) for S in ssh dropbear ws-ssh-80 ws-ssh-8880 ws-ssh-8008 stunnel4 \
           badvpn-7100 badvpn-7200 badvpn-7300 udp-custom zivpn xray squid nginx; do
           systemctl restart "$S" > /dev/null 2>&1; done; ok "Semua di-restart."; sleep 1 ;;
      2) systemctl restart ssh dropbear ws-ssh-80 ws-ssh-8880 stunnel4 > /dev/null 2>&1; ok "SSH di-restart."; sleep 1 ;;
      3) systemctl restart badvpn-7100 badvpn-7200 badvpn-7300 udp-custom zivpn > /dev/null 2>&1; ok "UDP di-restart."; sleep 1 ;;
      4) systemctl restart xray > /dev/null 2>&1; ok "Xray di-restart."; sleep 1 ;;
      0) return ;;
    esac
  done
}

menu_speedtest(){
  header; sub_hdr "SPEEDTEST VPS"; echo ""
  echo -e "  ${BLB}[1]${NC} speedtest-cli  ${BLB}[2]${NC} Ookla Speedtest  ${BLB}[3]${NC} Download Test  ${BL}[0]${NC} Kembali"
  bl_line2; echo ""
  read -rp "$(echo -e "  ${CBB}Pilih : ${NC}")" CH
  case "$CH" in
    1) command -v speedtest-cli &>/dev/null && speedtest-cli --simple || \
         (pip3 install speedtest-cli -q && speedtest-cli --simple) ;;
    2) command -v speedtest &>/dev/null && speedtest || warn "Ookla belum install." ;;
    3) wget -O /dev/null --progress=dot:mega http://speedtest.tele2.net/100MB.zip 2>&1 | \
         grep -Eo '[0-9]+(\.[0-9]+)? [KMG]B/s' | tail -1 | \
         xargs -I{} echo -e "  ${GB}Kecepatan: {}${NC}" ;;
    0) return ;;
  esac; press_enter
}

menu_monitor(){
  header; sub_hdr "MONITORING SERVER"
  local IP=$(get_ip) IFACE=$(ip -4 route ls|grep default|grep -Po '(?<=dev )(\S+)'|head -1)
  echo -e "  ${BL}OS     :${NC} $(lsb_release -ds 2>/dev/null|tr -d '"')  Kernel: $(uname -r)"
  echo -e "  ${BL}Uptime :${NC} $(uptime -p)"
  echo -e "  ${BL}CPU    :${NC} ${Y}$(top -bn1|grep 'Cpu(s)'|awk '{printf "%.1f",$2+$4}')%${NC}  RAM: ${Y}$(free -h|awk '/^Mem:/{print $3"/"$2}')${NC}"
  echo -e "  ${BL}IP     :${NC} ${CB}$IP${NC}  Koneksi: ${Y}$(ss -tnp 2>/dev/null|grep -c ESTAB)${NC}"
  echo ""
  echo -e "  ${CBB}Status Port:${NC}"
  bl_line2
  for P in 22 80 443 8443 8444 8445 8446 8553 8554 1194 2083 25525 5667; do
    ss -tlnp 2>/dev/null | grep -q ":$P " && \
      printf "  ${Y}%-6s${NC}:${GB}OPEN${NC}  " "$P" || printf "  ${Y}%-6s${NC}:${R}CLOS${NC}  " "$P"
  done; echo ""
  bl_line2; press_enter
}

menu_log(){
  while true; do
    header; sub_hdr "LOG & RIWAYAT"; echo ""
    echo -e "  ${BLB}[1]${NC} Log Panel  ${BLB}[2]${NC} Log SSH  ${BLB}[3]${NC} Log Xray  ${BLB}[4]${NC} Log ZIVPN  ${BLB}[5]${NC} Realtime  ${BL}[0]${NC} Kembali"
    bl_line2; echo ""
    read -rp "$(echo -e "  ${CBB}Pilih : ${NC}")" CH
    case "$CH" in
      1) tail -50 "$LOG_FILE" 2>/dev/null; press_enter ;;
      2) journalctl -u ssh -n 80 --no-pager; press_enter ;;
      3) tail -50 /var/log/xray/access.log 2>/dev/null; journalctl -u xray -n 30 --no-pager; press_enter ;;
      4) journalctl -u zivpn -n 50 --no-pager; press_enter ;;
      5) warn "Ctrl+C untuk keluar"; sleep 1; journalctl -f -u ssh -u xray -u zivpn -u udp-custom ;;
      0) return ;;
    esac
  done
}

menu_setting(){
  while true; do
    header; sub_hdr "PENGATURAN PANEL"; echo ""
    echo -e "  ${BLB}[1]${NC} Port SSH       ${BLB}[2]${NC} Port Dropbear   ${BLB}[3]${NC} Renew SSL"
    echo -e "  ${BLB}[4]${NC} Setup Domain   ${BLB}[5]${NC} Auto-Reboot     ${BLB}[6]${NC} Auto-Kill"
    echo -e "  ${BLB}[7]${NC} Backup Data    ${BLB}[8]${NC} Restore Backup"
    echo -e "  ${BL}[0]${NC} Kembali"; bl_line2; echo ""
    read -rp "$(echo -e "  ${CBB}Pilih : ${NC}")" CH
    case "$CH" in
      1) read -rp "  Port SSH baru: " P; sed -i "s/^Port [0-9]*/Port $P/" /etc/ssh/sshd_config
         systemctl restart ssh > /dev/null 2>&1; ok "Port SSH → $P"; press_enter ;;
      2) read -rp "  Port Dropbear baru: " P
         sed -i "s/^DROPBEAR_PORT=.*/DROPBEAR_PORT=$P/" /etc/default/dropbear
         systemctl restart dropbear > /dev/null 2>&1; ok "Port Dropbear → $P"; press_enter ;;
      3) openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
           -subj "/C=US/ST=CA/L=LA/O=OGH/CN=ogh-panel" \
           -keyout /etc/stunnel/stunnel.key -out /etc/stunnel/stunnel.crt > /dev/null 2>&1
         cat /etc/stunnel/stunnel.crt /etc/stunnel/stunnel.key > /etc/stunnel/stunnel.pem
         systemctl restart stunnel4 > /dev/null 2>&1; ok "SSL Stunnel diperbarui."; press_enter ;;
      4) read -rp "  Domain baru: " D; [[ -n "$D" ]] && echo "$D" > "$DOMAIN_FILE"; ok "Domain: $D"; press_enter ;;
      5) read -rp "  Jam reboot (00-23): " H
         (crontab -l 2>/dev/null|grep -v nexus-reboot; echo "0 $H * * * /sbin/reboot # nexus-reboot")|crontab -
         ok "Auto-reboot jam $H:00"; press_enter ;;
      6) read -rp "  Max login/user: " MAX
         cat > /usr/local/bin/nexus-autokill.sh <<AKEOF
#!/bin/bash
MAX=$MAX
who | awk '{print \$1}' | sort | uniq -c | while read C U; do
  [ "\$C" -gt "\$MAX" ] && pkill -u "\$U" -9 2>/dev/null && \
    echo "[\$(date)] AutoKill: \$U (\$C login)" >> /var/log/nexus-panel.log
done
AKEOF
         chmod +x /usr/local/bin/nexus-autokill.sh
         (crontab -l 2>/dev/null | grep -v nexus-autokill; \
          echo "*/1 * * * * /usr/local/bin/nexus-autokill.sh") | crontab -
         ok "Auto-kill aktif (max $MAX)"; press_enter ;;
      7) local BK="$PANEL_DIR/backup/bk_$(date +%Y%m%d_%H%M%S).tar.gz"
         mkdir -p "$PANEL_DIR/backup"
         tar -czf "$BK" /etc/ssh/sshd_config /etc/default/dropbear \
           /etc/udp-custom/config.json /etc/zivpn/config.json "$XRAY_CFG" \
           "$USERS_DB" "$UDPC_DB" "$ZIVPN_DB" "$XRAY_DB" 2>/dev/null
         ok "Backup: $BK"; press_enter ;;
      8) if ! ls "$PANEL_DIR/backup/"*.tar.gz > /dev/null 2>&1; then
            err "Tidak ada backup."; press_enter
         else
            ls "$PANEL_DIR/backup/"*.tar.gz 2>/dev/null
            read -rp "  Path file backup: " BK
            if [[ ! -f "$BK" ]]; then
               err "File tidak ditemukan!"; press_enter
            else
               tar -xzf "$BK" -C / > /dev/null 2>&1
               for S in ssh dropbear stunnel4 udp-custom zivpn xray; do
                 systemctl restart "$S" > /dev/null 2>&1
               done
               ok "Restore selesai."; press_enter
            fi
         fi ;;
      0) return ;;
    esac
  done
}

_info_bin(){
  header; sub_hdr "SUMBER BINARY (BIN)"; echo ""
  echo -e "  ${CBB}━━ XRAY-CORE ${XRAY_VER} — VMess/VLess/Trojan TLS & nTLS ━━━━━━━━${NC}"
  echo -e "  ${BL}Repo   :${NC} ${W}github.com/XTLS/Xray-core${NC}"
  echo -e "  ${BL}AMD64  :${NC} ${D}$XRAY_ZIP_AMD64${NC}"
  echo -e "  ${BL}ARM64  :${NC} ${D}$XRAY_ZIP_ARM64${NC}"
  echo -e "  ${BL}Install:${NC} ${D}$XRAY_INSTALL_URL${NC}"
  echo ""
  echo -e "  ${CBB}━━ UDP CUSTOM ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${BL}Repo   :${NC} ${W}github.com/feely666/udp-custom${NC}"
  echo -e "  ${BL}AMD64  :${NC} ${D}$UDPC_BIN_AMD64${NC}"
  echo ""
  echo -e "  ${CBB}━━ ZIVPN UDP v1.4.9 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${BL}Repo   :${NC} ${W}github.com/zahidbd2/udp-zivpn${NC}"
  echo -e "  ${BL}AMD64  :${NC} ${D}$ZIVPN_AMD64${NC}"
  echo -e "  ${BL}ARM64  :${NC} ${D}$ZIVPN_ARM64${NC}"
  echo ""
  echo -e "  ${CBB}━━ BADVPN UDPGW ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${BL}Repo   :${NC} ${W}github.com/idtunnel/UDPGW-SSH${NC}"
  echo -e "  ${BL}AMD64  :${NC} ${D}$BADVPN_AMD64${NC}"
  bl_line; press_enter
}

# =================================================================
#   ENTRY POINT
# =================================================================
main_menu
