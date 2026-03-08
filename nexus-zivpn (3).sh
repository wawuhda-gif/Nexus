#!/bin/bash
# ============================================================
#   NEXUS ZIVPN - UDP VPN Management Script
#   Creator: Nexus-Udp  |  Version: 2.0
# ============================================================

# ─── COLORS ───────────────────────────────────────────────
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; M='\033[0;35m'
W='\033[1;37m'; DIM='\033[2m'; NC='\033[0m'
BR='\033[1;31m'; BG='\033[1;32m'; BY='\033[1;33m'
BB='\033[1;34m'; BC='\033[1;36m'; BM='\033[1;35m'; BW='\033[1;37m'

# ─── PATHS ────────────────────────────────────────────────
ZIVPN_DIR="/etc/zivpn"
USERS_DB="$ZIVPN_DIR/users.db.json"
THEME_CONF="$ZIVPN_DIR/theme.conf"
DOMAIN_CONF="$ZIVPN_DIR/domain.conf"
TG_CONF="$ZIVPN_DIR/telegram.conf"
BIN_PATH="/usr/local/bin/zivpn-bin"
SERVICE_FILE="/etc/systemd/system/zivpn.service"
LICENSE_URL="https://github.com/wawuhda-gif/ijin/raw/main/ipvps"
SCRIPT_PATH="/usr/local/bin/nexus-zivpn.sh"

# ─── OS DETECTION & COMPATIBILITY ────────────────────────
detect_os() {
    # Ambil info distro
    OS_ID=""
    OS_VERSION_ID=""
    OS_CODENAME=""
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release 2>/dev/null
        OS_ID="${ID,,}"           # debian / ubuntu
        OS_VERSION_ID="$VERSION_ID"
        OS_CODENAME="${VERSION_CODENAME,,}"
        OS_PRETTY="$PRETTY_NAME"
    fi

    # Normalisasi: turunan Ubuntu/Debian juga diterima
    case "$OS_ID" in
        ubuntu|linuxmint|pop|elementary|zorin|kali|parrot)
            OS_FAMILY="ubuntu" ;;
        debian|raspbian|devuan|armbian)
            OS_FAMILY="debian" ;;
        *)
            OS_FAMILY="unknown" ;;
    esac
}

check_os_support() {
    detect_os

    if [[ "$OS_FAMILY" == "unknown" ]]; then
        echo -e ""
        echo -e "${BR}╔══════════════════════════════════════════════════╗${NC}"
        echo -e "${BR}║       ⛔  OS TIDAK DIDUKUNG  ⛔                 ║${NC}"
        echo -e "${BR}╠══════════════════════════════════════════════════╣${NC}"
        echo -e "${BR}║  Script ini hanya untuk:                        ║${NC}"
        echo -e "${BR}║  • Debian  7/8/9/10/11/12/13+                   ║${NC}"
        echo -e "${BR}║  • Ubuntu  14.04 / 16.04 / 18.04 / 20.04 /      ║${NC}"
        echo -e "${BR}║            22.04 / 24.04 dan versi lebih baru    ║${NC}"
        echo -e "${BR}║  • Turunan Debian/Ubuntu (Mint, Pop, dsb)        ║${NC}"
        echo -e "${BR}║                                                  ║${NC}"
        echo -e "${BR}║  OS Terdeteksi: ${BW}${OS_PRETTY:-Unknown}${BR}          ║${NC}"
        echo -e "${BR}╚══════════════════════════════════════════════════╝${NC}"
        exit 1
    fi

    # Cek apakah berjalan sebagai root
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${BR}[✗] Script harus dijalankan sebagai ROOT!${NC}"
        echo -e "${BY}    Coba: ${BW}sudo bash $0${NC}"
        exit 1
    fi

    # Cek apakah systemd tersedia
    if ! command -v systemctl &>/dev/null; then
        echo -e "${BR}[✗] systemd tidak ditemukan. Script membutuhkan systemd.${NC}"
        exit 1
    fi
}

# Deteksi package manager dan nama paket yang tepat per versi OS
get_pkg_list() {
    detect_os
    local ver="${OS_VERSION_ID%%.*}"   # ambil major version saja
    local pkgs="curl wget openssl bc net-tools jq"

    # iptables-persistent tersedia di semua Debian/Ubuntu modern
    pkgs="$pkgs iptables-persistent netfilter-persistent"

    # ufw tersedia di semua versi
    pkgs="$pkgs ufw"

    # speedtest: Debian 11+/Ubuntu 20.04+ punya speedtest-cli di repo
    # Versi lama: install manual via pip atau paket python3-speedtest-cli
    if [[ "$OS_FAMILY" == "ubuntu" ]]; then
        if (( ver >= 20 )); then
            pkgs="$pkgs speedtest-cli"
        else
            pkgs="$pkgs python3-speedtest-cli"
        fi
    elif [[ "$OS_FAMILY" == "debian" ]]; then
        if (( ver >= 11 )); then
            pkgs="$pkgs speedtest-cli"
        else
            pkgs="$pkgs python3-pip"
            NEED_SPEEDTEST_PIP=1
        fi
    fi

    echo "$pkgs"
}

# Konfigurasi DEBIAN_FRONTEND agar tidak ada prompt interaktif
export DEBIAN_FRONTEND=noninteractive

# ─── RAINBOW ENGINE ───────────────────────────────────────
# Urutan warna pelangi: Merah → Oranye/Kuning → Hijau → Cyan → Biru → Ungu
_RBC=("$BR" "$BY" '\033[38;5;214m' "$BG" "$BC" "$BB" "$BM")
_RBC_LEN=7
_rb_idx=0

rainbow_reset() { _rb_idx=0; }

# Cetak teks dengan setiap karakter berganti warna pelangi
rainbow_text() {
    local text="$1"
    local out=""
    for (( i=0; i<${#text}; i++ )); do
        local ch="${text:$i:1}"
        # Skip space agar tidak membuang index warna
        if [[ "$ch" == " " ]]; then
            out+=" "
        else
            out+="${_RBC[$_rb_idx]}${ch}"
            _rb_idx=$(( (_rb_idx + 1) % _RBC_LEN ))
        fi
    done
    echo -e "${out}${NC}"
}

# Fungsi cetak baris p_top/mid/bot/sep yang mendukung rainbow
rb_p_top() {
    if [[ "$IS_RAINBOW" == "1" ]]; then
        rainbow_text "╔══════════════════════════════════════════════════════╗"
    else p_top; fi
}
rb_p_mid() {
    if [[ "$IS_RAINBOW" == "1" ]]; then
        rainbow_text "╠══════════════════════════════════════════════════════╣"
    else p_mid; fi
}
rb_p_bot() {
    if [[ "$IS_RAINBOW" == "1" ]]; then
        rainbow_text "╚══════════════════════════════════════════════════════╝"
    else p_bot; fi
}
rb_p_sep() {
    if [[ "$IS_RAINBOW" == "1" ]]; then
        rainbow_text "╟──────────────────────────────────────────────────────╢"
    else p_sep; fi
}

# row dengan sisi border rainbow
rb_row() {
    if [[ "$IS_RAINBOW" == "1" ]]; then
        local c1="${_RBC[$_rb_idx]}"
        _rb_idx=$(( (_rb_idx + 1) % _RBC_LEN ))
        local c2="${_RBC[$_rb_idx]}"
        _rb_idx=$(( (_rb_idx + 1) % _RBC_LEN ))
        echo -e "${c1}${SIDE}${NC} $1 ${c2}${SIDE}${NC}"
    else
        row "$1"
    fi
}
rb_row_center() {
    if [[ "$IS_RAINBOW" == "1" ]]; then
        local c1="${_RBC[$_rb_idx]}"
        _rb_idx=$(( (_rb_idx + 1) % _RBC_LEN ))
        local c2="${_RBC[$_rb_idx]}"
        _rb_idx=$(( (_rb_idx + 1) % _RBC_LEN ))
        echo -e "${c1}${SIDE}${NC}$(pad_center "$1")${c2}${SIDE}${NC}"
    else
        row_center "$1"
    fi
}

# ─── THEME LOADER ─────────────────────────────────────────
load_theme() {
    THEME="rainbow"
    [[ -f "$THEME_CONF" ]] && THEME=$(cat "$THEME_CONF" 2>/dev/null)
    case "$THEME" in
        rainbow) H1=$BR; H2=$BG; H3=$BY; H4=$BC; H5=$BM; AC=$BW; IS_RAINBOW=1 ;;
        ocean)   H1=$BB; H2=$BC; H3=$BW; H4=$BG; H5=$BB; AC=$BC; IS_RAINBOW=0 ;;
        fire)    H1=$BR; H2=$BY; H3=$BR; H4=$BY; H5=$BR; AC=$BY; IS_RAINBOW=0 ;;
        night)   H1=$BM; H2=$BB; H3=$BC; H4=$BM; H5=$BB; AC=$BW; IS_RAINBOW=0 ;;
        neon)    H1=$BG; H2=$BM; H3=$BC; H4=$BY; H5=$BG; AC=$BM; IS_RAINBOW=0 ;;
        gold)    H1=$BY; H2=$BW; H3=$BY; H4=$BW; H5=$BY; AC=$BY; IS_RAINBOW=0 ;;
        *)       H1=$BR; H2=$BG; H3=$BY; H4=$BC; H5=$BM; AC=$BW; IS_RAINBOW=1 ;;
    esac
}
load_theme

# ─── BORDER / LAYOUT ──────────────────────────────────────
L_TOP="╔══════════════════════════════════════════════════════╗"
L_MID="╠══════════════════════════════════════════════════════╣"
L_BOT="╚══════════════════════════════════════════════════════╝"
L_SEP="╟──────────────────────────────────────────────────────╢"
SIDE="║"

p_top() { echo -e "${H1}${L_TOP}${NC}"; }
p_mid() { echo -e "${H1}${L_MID}${NC}"; }
p_bot() { echo -e "${H1}${L_BOT}${NC}"; }
p_sep() { echo -e "${H1}${L_SEP}${NC}"; }

pad_center() {
    local str="$1" width=54
    local clean=$(echo -e "$str" | sed 's/\x1b\[[0-9;]*m//g')
    local len=${#clean}
    local pad=$(( (width - len) / 2 ))
    local rpad=$(( width - len - pad ))
    printf "%${pad}s%b%${rpad}s" "" "$str" ""
}

row() { echo -e "${H1}${SIDE}${NC} $1 ${H1}${SIDE}${NC}"; }
row_center() { echo -e "${H1}${SIDE}${NC}$(pad_center "$1")${H1}${SIDE}${NC}"; }

# ─── VPS INFO ─────────────────────────────────────────────
get_vps_info() {
    IP_VPS=$(curl -s4 --connect-timeout 5 icanhazip.com 2>/dev/null || echo "N/A")
    HOSTNAME=$(hostname 2>/dev/null || echo "N/A")
    # Baca dari /etc/os-release untuk info OS lengkap
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release 2>/dev/null
        OS_INFO="${PRETTY_NAME:-Unknown}"
        _OS_FAMILY="${ID,,}"
        case "$_OS_FAMILY" in
            ubuntu|linuxmint|pop|elementary|zorin|kali|parrot) _OS_FAMILY="Ubuntu-based" ;;
            debian|raspbian|devuan|armbian)                     _OS_FAMILY="Debian-based" ;;
            *) _OS_FAMILY="Unknown" ;;
        esac
    else
        OS_INFO="Unknown"
        _OS_FAMILY="Unknown"
    fi
    CPU_CORES=$(nproc 2>/dev/null || echo "N/A")
    RAM_TOTAL=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}' || echo "N/A")
    RAM_USED=$(free -h 2>/dev/null | awk '/^Mem:/{print $3}' || echo "N/A")
    DISK_TOTAL=$(df -h / 2>/dev/null | awk 'NR==2{print $2}' || echo "N/A")
    DISK_USED=$(df -h / 2>/dev/null | awk 'NR==2{print $3}' || echo "N/A")
    UPTIME_INFO=$(uptime -p 2>/dev/null | sed 's/up //' || echo "N/A")
    ISP=$(curl -s --connect-timeout 5 "http://ip-api.com/line/$IP_VPS?fields=isp" 2>/dev/null | head -1 || echo "N/A")
    DOMAIN_VAL="N/A"; [[ -f "$DOMAIN_CONF" ]] && DOMAIN_VAL=$(cat "$DOMAIN_CONF")
    SVC_STATUS=$(systemctl is-active zivpn.service 2>/dev/null || echo "inactive")
    [[ "$SVC_STATUS" == "active" ]] && SVC_COLOR="$BG" || SVC_COLOR="$BR"
}

# ─── LOGO ─────────────────────────────────────────────────
show_logo() {
    clear
    load_theme
    rainbow_reset
    get_vps_info
    echo ""

    if [[ "$IS_RAINBOW" == "1" ]]; then
        # ── Rainbow mode ──
        rainbow_text "╔══════════════════════════════════════════════════════╗"
        rb_row_center ""
        rb_row_center "  _  _ ___ _  _ _   _ ____"
        rb_row_center "  |\ | |_  |  | |   | [__ "
        rb_row_center "  | \| |__ \__/ |__ | ___]"
        rb_row_center ""
        rb_row_center "  ___  _  _  _  _ ____  _  _"
        rb_row_center "   /  | |  \/  | |___] |\ |"
        rb_row_center "  /_  | |  /\  | |     | \|"
        rb_row_center ""
        rb_row_center "  -= U D P  V P N  S E R V E R =-"
        rb_row_center "${DIM}  --  by  N e x u s - U d p  --${NC}"
        rb_row_center ""
        rainbow_text "╠══════════════════════════════════════════════════════╣"
        rb_row "  ${BY}IP VPS   :${NC} ${BW}$IP_VPS${NC}"
        rb_row "  ${BY}Hostname :${NC} ${BW}$HOSTNAME${NC}"
        rb_row "  ${BY}Domain   :${NC} ${BW}$DOMAIN_VAL${NC}"
        rb_row "  ${BY}OS       :${NC} ${BW}$OS_INFO${NC}"
        rb_row "  ${BY}Platform :${NC} ${BC}$_OS_FAMILY${NC}"
        rb_row "  ${BY}CPU      :${NC} ${BW}${CPU_CORES} Core(s)${NC}"
        rb_row "  ${BY}RAM      :${NC} ${BW}${RAM_USED} / ${RAM_TOTAL}${NC}"
        rb_row "  ${BY}Disk     :${NC} ${BW}${DISK_USED} / ${DISK_TOTAL}${NC}"
        rb_row "  ${BY}Uptime   :${NC} ${BW}$UPTIME_INFO${NC}"
        rb_row "  ${BY}ISP      :${NC} ${BW}$ISP${NC}"
        rb_row "  ${BY}Service  :${NC} ${SVC_COLOR}${SVC_STATUS}${NC}"
        rainbow_text "╚══════════════════════════════════════════════════════╝"
    else
        # ── Normal / Tema mode ──
        p_top
        row_center ""
        row_center "${H1}  _  _ ___ _  _ _   _ ____${NC}"
        row_center "${H2}  |\ | |_  |  | |   | [__ ${NC}"
        row_center "${H3}  | \| |__ \__/ |__ | ___]${NC}"
        row_center ""
        row_center "${H4}  ___  _  _  _  _ ____  _  _${NC}"
        row_center "${H5}   /  | |  \/  | |___] |\ |${NC}"
        row_center "${H1}  /_  | |  /\  | |     | \|${NC}"
        row_center ""
        row_center "${AC}  -= U D P  V P N  S E R V E R =-${NC}"
        row_center "${DIM}  --  by  N e x u s - U d p  --${NC}"
        row_center ""
        p_mid
        row "  ${BY}IP VPS   :${NC} ${BW}$IP_VPS${NC}"
        row "  ${BY}Hostname :${NC} ${BW}$HOSTNAME${NC}"
        row "  ${BY}Domain   :${NC} ${BW}$DOMAIN_VAL${NC}"
        row "  ${BY}OS       :${NC} ${BW}$OS_INFO${NC}"
        row "  ${BY}Platform :${NC} ${BC}$_OS_FAMILY${NC}"
        row "  ${BY}CPU      :${NC} ${BW}${CPU_CORES} Core(s)${NC}"
        row "  ${BY}RAM      :${NC} ${BW}${RAM_USED} / ${RAM_TOTAL}${NC}"
        row "  ${BY}Disk     :${NC} ${BW}${DISK_USED} / ${DISK_TOTAL}${NC}"
        row "  ${BY}Uptime   :${NC} ${BW}$UPTIME_INFO${NC}"
        row "  ${BY}ISP      :${NC} ${BW}$ISP${NC}"
        row "  ${BY}Service  :${NC} ${SVC_COLOR}${SVC_STATUS}${NC}"
        p_bot
    fi
    echo ""
}

# ─── LICENSE CHECK ────────────────────────────────────────
check_license() {
    echo -e "\n${BY}[~] Memverifikasi lisensi...${NC}"
    local my_ip=$(curl -s4 --connect-timeout 10 icanhazip.com 2>/dev/null | tr -d '[:space:]')
    if [[ -z "$my_ip" ]]; then
        echo -e "${BR}[✗] Gagal mendapatkan IP VPS. Periksa koneksi internet.${NC}"
        exit 1
    fi
    echo -e "${BY}[~] IP VPS terdeteksi: ${BW}$my_ip${NC}"
    local allowed_ips=$(curl -s --connect-timeout 10 "$LICENSE_URL" 2>/dev/null)
    if [[ -z "$allowed_ips" ]]; then
        echo -e "${BR}[✗] Gagal mengambil daftar lisensi. Periksa koneksi.${NC}"
        exit 1
    fi
    if echo "$allowed_ips" | grep -qF "$my_ip"; then
        echo -e "${BG}[✔] Lisensi VALID — IP ${BW}$my_ip${BG} terdaftar.${NC}"
        sleep 1
    else
        echo -e ""
        p_top
        row_center "${BR}     ⛔  AKSES DITOLAK  ⛔${NC}"
        p_mid
        row "  ${BR}IP ${BW}$my_ip${BR} tidak terdaftar!${NC}"
        row "  ${BY}Hubungi admin untuk mendaftarkan IP Anda.${NC}"
        row "  ${BY}Lisensi: ${BW}$LICENSE_URL${NC}"
        p_bot
        exit 1
    fi
}

# ─── DB HELPERS ───────────────────────────────────────────
init_db()    { [[ ! -f "$USERS_DB" ]] && echo "[]" > "$USERS_DB"; }
get_users()  { init_db; cat "$USERS_DB"; }
save_users() { echo "$1" > "$USERS_DB"; }
user_exists(){ get_users | jq -e --arg u "$1" '.[] | select(.username==$u)' > /dev/null 2>&1; }

# ─── TELEGRAM ─────────────────────────────────────────────
send_tg() {
    [[ ! -f "$TG_CONF" ]] && return
    local BOT_TOKEN="" CHAT_ID=""
    source "$TG_CONF" 2>/dev/null
    [[ -z "$BOT_TOKEN" || -z "$CHAT_ID" ]] && return
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=$(echo -e "$1")" \
        -d "parse_mode=Markdown" > /dev/null 2>&1
}

# ─── SHORTCUT SETUP ───────────────────────────────────────
setup_shortcut() {
    # Buat symlink 'zivpn' dan 'menu' agar bisa dipanggil dari mana saja
    ln -sf "$SCRIPT_PATH" /usr/local/bin/zivpn   2>/dev/null
    ln -sf "$SCRIPT_PATH" /usr/local/bin/menu     2>/dev/null
    chmod +x /usr/local/bin/zivpn /usr/local/bin/menu 2>/dev/null

    # Tambahkan alias ke /root/.bashrc jika belum ada
    local bashrc="/root/.bashrc"
    if ! grep -q "alias zivpn=" "$bashrc" 2>/dev/null; then
        echo ""                                                    >> "$bashrc"
        echo "# ── NEXUS ZIVPN Shortcuts ──────────────────────" >> "$bashrc"
        echo "alias zivpn='$SCRIPT_PATH'"                         >> "$bashrc"
        echo "alias menu='$SCRIPT_PATH'"                          >> "$bashrc"
    fi

    # Juga tambahkan ke /root/.profile untuk sesi non-interactive
    local profile="/root/.profile"
    if ! grep -q "alias zivpn=" "$profile" 2>/dev/null; then
        echo ""                          >> "$profile"
        echo "alias zivpn='$SCRIPT_PATH'" >> "$profile"
        echo "alias menu='$SCRIPT_PATH'"  >> "$profile"
    fi

    echo -e "${BG}     ✔ Shortcut 'zivpn' dan 'menu' berhasil dibuat${NC}"
}

remove_shortcut() {
    rm -f /usr/local/bin/zivpn /usr/local/bin/menu
    # Hapus baris alias dari .bashrc dan .profile
    sed -i '/# ── NEXUS ZIVPN Shortcuts/d' /root/.bashrc  2>/dev/null
    sed -i '/alias zivpn=/d'               /root/.bashrc  2>/dev/null
    sed -i '/alias menu=/d'                /root/.bashrc  2>/dev/null
    sed -i '/alias zivpn=/d'               /root/.profile 2>/dev/null
    sed -i '/alias menu=/d'                /root/.profile 2>/dev/null
}

# ─── INSTALL ──────────────────────────────────────────────
install_zivpn() {
    check_os_support
    check_license
    show_logo
    echo -e "${H2}[ INSTALASI NEXUS ZIVPN UDP ]${NC}"
    echo -e "${DIM}  OS: $OS_PRETTY${NC}\n"

    echo -e "${BY}[1/9] Menginstall dependensi...${NC}"
    # Nonaktifkan prompt interaktif saat install
    export DEBIAN_FRONTEND=noninteractive
    # Siasati iptables-persistent yang minta konfirmasi interaktif
    echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections 2>/dev/null
    echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections 2>/dev/null

    apt-get update -qq > /dev/null 2>&1
    local PKG_LIST
    PKG_LIST=$(get_pkg_list)
    # shellcheck disable=SC2086
    apt-get install -y -qq $PKG_LIST > /dev/null 2>&1
    # Jika Debian lama, install speedtest via pip
    if [[ "${NEED_SPEEDTEST_PIP:-0}" == "1" ]]; then
        pip3 install speedtest-cli -q 2>/dev/null || true
    fi
    echo -e "${BG}     ✔ Dependensi terinstall${NC}"
    echo -e "${DIM}     Paket: $PKG_LIST${NC}"

    echo -e "${BY}[2/9] Menyiapkan direktori...${NC}"
    mkdir -p "$ZIVPN_DIR"

    echo -e "${BY}[3/9] Menghapus instalasi lama...${NC}"
    systemctl stop zivpn.service 2>/dev/null
    rm -f "$BIN_PATH"
    rm -f "$ZIVPN_DIR/config.json"
    rm -f "$ZIVPN_DIR/zivpn.key" "$ZIVPN_DIR/zivpn.crt"
    echo -e "${BG}     ✔ File lama dihapus${NC}"

    echo -e "${BY}[4/9] Mendownload binary ZIVPN...${NC}"
    wget -q --show-progress \
        https://github.com/fauzanihanipah/ziv-udp/releases/download/udp-zivpn/udp-zivpn-linux-amd64 \
        -O "$BIN_PATH"
    chmod +x "$BIN_PATH"
    echo -e "${BG}     ✔ Binary berhasil didownload${NC}"

    echo -e "${BY}[5/9] Mendownload konfigurasi...${NC}"
    wget -q https://raw.githubusercontent.com/fauzanihanipah/ziv-udp/main/config.json \
        -O "$ZIVPN_DIR/config.json"
    echo -e "${BG}     ✔ config.json berhasil didownload${NC}"

    echo -e "${BY}[6/9] Membuat sertifikat SSL (RSA 4096)...${NC}"
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=US/ST=California/L=Los Angeles/O=Nexus VPN/OU=IT/CN=nexuszivpn" \
        -keyout "$ZIVPN_DIR/zivpn.key" \
        -out "$ZIVPN_DIR/zivpn.crt" 2>/dev/null
    echo -e "${BG}     ✔ Sertifikat SSL dibuat${NC}"

    echo -e "${BY}[7/9] Membuat systemd service...${NC}"
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Nexus ZIVPN UDP Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$ZIVPN_DIR
ExecStart=$BIN_PATH server -c $ZIVPN_DIR/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable zivpn.service > /dev/null 2>&1
    systemctl start zivpn.service
    echo -e "${BG}     ✔ Service aktif${NC}"

    echo -e "${BY}[8/9] Mengkonfigurasi firewall & iptables...${NC}"
    INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    sysctl -w net.core.rmem_max=16777216 > /dev/null
    sysctl -w net.core.wmem_max=16777216 > /dev/null
    while iptables -t nat -D PREROUTING -i "$INTERFACE" -p udp --dport 6000:19999 \
        -j DNAT --to-destination :5667 2>/dev/null; do :; done
    iptables -t nat -A PREROUTING -i "$INTERFACE" -p udp --dport 6000:19999 \
        -j DNAT --to-destination :5667
    iptables -A FORWARD -p udp -d 127.0.0.1 --dport 5667 -j ACCEPT
    iptables -t nat -A POSTROUTING -s 127.0.0.1/32 -o "$INTERFACE" -j MASQUERADE
    netfilter-persistent save > /dev/null 2>&1
    ufw allow 6000:19999/udp > /dev/null 2>&1
    ufw allow 5667/udp > /dev/null 2>&1
    echo -e "${BG}     ✔ Firewall dikonfigurasi${NC}"

    echo -e "${BY}[9/9] Finalisasi...${NC}"
    echo "[]"       > "$USERS_DB"
    echo "rainbow"  > "$THEME_CONF"
    echo ""         > "$DOMAIN_CONF"
    # Auto cleanup cron job every 5 minutes
    (crontab -l 2>/dev/null | grep -v "nexus-zivpn"; \
     echo "*/5 * * * * $SCRIPT_PATH --auto-cleanup > /dev/null 2>&1") | crontab -
    # Install self to /usr/local/bin
    cp "$0" "$SCRIPT_PATH" 2>/dev/null || true
    chmod +x "$SCRIPT_PATH"
    echo -e "${BG}     ✔ Script terinstall di $SCRIPT_PATH${NC}"

    # Buat shortcut command 'zivpn' dan 'menu'
    setup_shortcut

    echo ""
    p_top
    row_center "${BG}  ✔  NEXUS ZIVPN BERHASIL DIINSTALL!  ✔${NC}"
    p_mid
    row "  ${BY}Jalankan  :${NC} ${BW}zivpn${NC}  ${DIM}atau${NC}  ${BW}menu${NC}"
    row "  ${BY}Port UDP  :${NC} ${BW}5667 / 6000-19999${NC}"
    row "  ${BY}Service   :${NC} ${BG}$(systemctl is-active zivpn.service)${NC}"
    p_sep
    row "  ${DIM}Shortcut aktif setelah: source ~/.bashrc${NC}"
    p_bot
    sleep 3
    main_menu
}

# ─── UNINSTALL ────────────────────────────────────────────
uninstall_zivpn() {
    show_logo
    p_top
    row_center "${BR}  ⚠   KONFIRMASI UNINSTALL ZIVPN   ⚠${NC}"
    p_mid
    row "  Semua file, akun, service akan dihapus!"
    p_bot
    echo -ne "\n${BR}Ketik ${BW}HAPUS${BR} untuk konfirmasi: ${NC}"; read -r confirm
    [[ "$confirm" != "HAPUS" ]] && { echo -e "${BY}[i] Dibatalkan.${NC}"; sleep 1; return; }

    echo -e "${BY}[~] Menghentikan service...${NC}"
    systemctl stop zivpn.service 2>/dev/null
    systemctl disable zivpn.service 2>/dev/null

    echo -e "${BY}[~] Menghapus file...${NC}"
    rm -f "$BIN_PATH"
    rm -rf "$ZIVPN_DIR"
    rm -f "$SERVICE_FILE"

    echo -e "${BY}[~] Membersihkan iptables...${NC}"
    INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    while iptables -t nat -D PREROUTING -i "$INTERFACE" -p udp --dport 6000:19999 \
        -j DNAT --to-destination :5667 2>/dev/null; do :; done
    iptables -D FORWARD -p udp -d 127.0.0.1 --dport 5667 -j ACCEPT 2>/dev/null
    iptables -t nat -D POSTROUTING -s 127.0.0.1/32 -o "$INTERFACE" -j MASQUERADE 2>/dev/null
    netfilter-persistent save > /dev/null 2>&1

    echo -e "${BY}[~] Menghapus cron job...${NC}"
    crontab -l 2>/dev/null | grep -v "nexus-zivpn" | crontab -

    echo -e "${BY}[~] Menghapus shortcut command...${NC}"
    remove_shortcut

    systemctl daemon-reload
    echo -e "${BY}[~] Menghapus script...${NC}"
    rm -f "$SCRIPT_PATH"

    echo -e "${BG}[✔] Uninstall selesai. Semua file dihapus.${NC}"
    exit 0
}

# ─── ADD USER ─────────────────────────────────────────────
add_user() {
    show_logo
    echo -e "${H2}[ TAMBAH AKUN UDP ZIVPN ]${NC}"
    p_top
    echo -ne " ${H1}${SIDE}${NC} ${BY}Username   : ${NC}"; read -r username
    if user_exists "$username"; then
        echo -e "${BR}[✗] Username sudah digunakan!${NC}"; sleep 2; return
    fi
    echo -ne " ${H1}${SIDE}${NC} ${BY}Password   : ${NC}"; read -r password
    echo -ne " ${H1}${SIDE}${NC} ${BY}Masa Aktif : ${NC}"; read -r days
    echo -ne " ${H1}${SIDE}${NC} ${BY}Max Login  : ${NC}"; read -r maxlogin
    p_bot

    local exp_date=$(date -d "+${days} days" +"%Y-%m-%d")
    local created=$(date +"%Y-%m-%d %H:%M:%S")
    local domain_val="N/A"; [[ -f "$DOMAIN_CONF" ]] && domain_val=$(cat "$DOMAIN_CONF")
    local my_ip=$(curl -s4 --connect-timeout 5 icanhazip.com 2>/dev/null || echo "N/A")

    local users new_user
    users=$(get_users)
    new_user=$(jq -n \
        --arg u "$username" --arg p "$password" \
        --arg e "$exp_date" --arg c "$created" \
        --argjson m "$maxlogin" \
        '{"username":$u,"password":$p,"expired":$e,"created":$c,"maxlogin":$m}')
    users=$(echo "$users" | jq ". + [$new_user]")
    save_users "$users"
    useradd -M -s /sbin/nologin "$username" 2>/dev/null
    echo "$username:$password" | chpasswd 2>/dev/null

    send_tg "✅ *Akun Baru Dibuat*
👤 User     : \`$username\`
🔑 Password : \`$password\`
📅 Expired  : $exp_date
🔢 MaxLogin : $maxlogin
📡 Host     : ${domain_val:-$my_ip}"

    echo ""
    echo -e " ${BW}╔══════════════════════════════════════════╗${NC}"
    echo -e " ${BW}║       ✅ AKUN BERHASIL DIBUAT            ║${NC}"
    echo -e " ${BW}╠══════════════════════════════════════════╣${NC}"
    printf  " ${BW}║${NC}  ${BY}Host    :${NC} ${BW}%-30s${NC} ${BW}║${NC}\n" "${domain_val:-$my_ip}"
    printf  " ${BW}║${NC}  ${BY}Port    :${NC} ${BW}%-30s${NC} ${BW}║${NC}\n" "5667 / 6000-19999"
    printf  " ${BW}║${NC}  ${BY}User    :${NC} ${BG}%-30s${NC} ${BW}║${NC}\n" "$username"
    printf  " ${BW}║${NC}  ${BY}Pass    :${NC} ${BG}%-30s${NC} ${BW}║${NC}\n" "$password"
    printf  " ${BW}║${NC}  ${BY}Expired :${NC} ${BR}%-30s${NC} ${BW}║${NC}\n" "$exp_date ($days hari)"
    printf  " ${BW}║${NC}  ${BY}MaxLogin:${NC} ${BC}%-30s${NC} ${BW}║${NC}\n" "$maxlogin sesi"
    echo -e " ${BW}╚══════════════════════════════════════════╝${NC}"
    echo -ne "\n${BY}[Enter] Kembali ke menu...${NC}"; read -r
}

# ─── DELETE USER ──────────────────────────────────────────
delete_user() {
    show_logo
    echo -e "${H2}[ HAPUS AKUN UDP ]${NC}"
    list_users_table
    echo -ne "\n${BY}▸ Username yang akan dihapus (0=batal): ${NC}"; read -r username
    [[ "$username" == "0" ]] && return
    if ! user_exists "$username"; then
        echo -e "${BR}[✗] User tidak ditemukan!${NC}"; sleep 2; return
    fi
    echo -ne "${BR}Konfirmasi hapus '${BW}$username${BR}'? [y/N]: ${NC}"; read -r conf
    [[ "$conf" != "y" && "$conf" != "Y" ]] && return

    local users
    users=$(get_users)
    users=$(echo "$users" | jq "del(.[] | select(.username==\"$username\"))")
    save_users "$users"
    userdel -f "$username" 2>/dev/null

    send_tg "🗑️ *Akun Dihapus (Manual)*
👤 User  : \`$username\`
🕐 Waktu : $(date '+%Y-%m-%d %H:%M:%S')"

    echo -e "${BG}[✔] Akun ${BW}$username${BG} berhasil dihapus.${NC}"; sleep 2
}

# ─── RENEW USER ───────────────────────────────────────────
renew_user() {
    show_logo
    echo -e "${H2}[ RENEW AKUN UDP ]${NC}"
    list_users_table
    echo -ne "\n${BY}▸ Username (0=batal): ${NC}"; read -r username
    [[ "$username" == "0" ]] && return
    if ! user_exists "$username"; then
        echo -e "${BR}[✗] User tidak ditemukan!${NC}"; sleep 2; return
    fi
    echo -ne "${BY}▸ Tambah berapa hari: ${NC}"; read -r days
    local new_exp
    new_exp=$(date -d "+${days} days" +"%Y-%m-%d")
    local users
    users=$(get_users)
    users=$(echo "$users" | jq --arg u "$username" --arg e "$new_exp" \
        '(.[] | select(.username==$u) | .expired) |= $e')
    save_users "$users"

    send_tg "♻️ *Akun Diperbarui*
👤 User     : \`$username\`
📅 Exp Baru : $new_exp (+$days hari)"

    echo -e "${BG}[✔] ${BW}$username${BG} diperpanjang hingga ${BW}$new_exp${NC}"; sleep 2
}

# ─── CHANGE PASSWORD ──────────────────────────────────────
change_password() {
    show_logo
    echo -e "${H2}[ GANTI PASSWORD ]${NC}"
    list_users_table
    echo -ne "\n${BY}▸ Username (0=batal): ${NC}"; read -r username
    [[ "$username" == "0" ]] && return
    if ! user_exists "$username"; then
        echo -e "${BR}[✗] User tidak ditemukan!${NC}"; sleep 2; return
    fi
    echo -ne "${BY}▸ Password baru: ${NC}"; read -r newpass
    local users
    users=$(get_users)
    users=$(echo "$users" | jq --arg u "$username" --arg p "$newpass" \
        '(.[] | select(.username==$u) | .password) |= $p')
    save_users "$users"
    echo "$username:$newpass" | chpasswd 2>/dev/null
    echo -e "${BG}[✔] Password berhasil diganti.${NC}"; sleep 2
}

# ─── SET MAX LOGIN ────────────────────────────────────────
set_max_login() {
    show_logo
    echo -e "${H2}[ SET MAX LOGIN ]${NC}"
    list_users_table
    echo -ne "\n${BY}▸ Username (0=batal): ${NC}"; read -r username
    [[ "$username" == "0" ]] && return
    if ! user_exists "$username"; then
        echo -e "${BR}[✗] User tidak ditemukan!${NC}"; sleep 2; return
    fi
    echo -ne "${BY}▸ Max Login baru: ${NC}"; read -r maxl
    local users
    users=$(get_users)
    users=$(echo "$users" | jq --arg u "$username" --argjson m "$maxl" \
        '(.[] | select(.username==$u) | .maxlogin) |= $m')
    save_users "$users"
    echo -e "${BG}[✔] Max login ${BW}$username${BG} → ${BW}$maxl sesi${NC}"; sleep 2
}

# ─── LIST USERS TABLE ─────────────────────────────────────
list_users_table() {
    local users today count
    users=$(get_users)
    today=$(date +%Y-%m-%d)
    count=$(echo "$users" | jq 'length')
    echo -e "${BY}Total Akun: ${BW}$count${NC}"
    p_top
    printf "${H1}${SIDE}${NC} ${BY}%-16s %-12s %-8s %-5s${NC} ${H1}${SIDE}${NC}\n" \
        "USERNAME" "EXPIRED" "STATUS" "MAX"
    p_sep
    echo "$users" | jq -r '.[] | "\(.username)|\(.expired)|\(.maxlogin)"' | \
    while IFS='|' read -r user exp maxl; do
        local status_txt status_col
        if [[ "$exp" < "$today" ]]; then status_txt="Expired"; status_col="$BR"
        else status_txt="Active "; status_col="$BG"; fi
        printf "${H1}${SIDE}${NC} ${BW}%-16s${NC} ${BC}%-12s${NC} ${status_col}%-8s${NC} ${BY}%-5s${NC} ${H1}${SIDE}${NC}\n" \
            "$user" "$exp" "$status_txt" "$maxl"
    done
    p_bot
}

list_users() {
    show_logo
    echo -e "${H2}[ DAFTAR AKUN UDP ]${NC}"
    list_users_table
    echo -ne "\n${BY}[Enter] Kembali...${NC}"; read -r
}

# ─── DETAIL USER ──────────────────────────────────────────
detail_user() {
    show_logo
    echo -e "${H2}[ DETAIL AKUN ]${NC}"
    list_users_table
    echo -ne "\n${BY}▸ Username (0=batal): ${NC}"; read -r username
    [[ "$username" == "0" ]] && return
    local udata
    udata=$(get_users | jq --arg u "$username" '.[] | select(.username==$u)')
    if [[ -z "$udata" ]]; then
        echo -e "${BR}[✗] User tidak ditemukan!${NC}"; sleep 2; return
    fi
    local pass exp created maxl domain_val today sisa sisa_color status
    pass=$(echo "$udata"    | jq -r '.password')
    exp=$(echo "$udata"     | jq -r '.expired')
    created=$(echo "$udata" | jq -r '.created')
    maxl=$(echo "$udata"    | jq -r '.maxlogin')
    domain_val="N/A"; [[ -f "$DOMAIN_CONF" ]] && domain_val=$(cat "$DOMAIN_CONF")
    today=$(date +%Y-%m-%d)
    sisa=$(( ($(date -d "$exp" +%s) - $(date -d "$today" +%s)) / 86400 ))
    if [[ "$exp" < "$today" ]]; then status="${BR}EXPIRED${NC}"; sisa_color="$BR"
    else status="${BG}AKTIF${NC}"; sisa_color="$BY"; fi

    echo ""
    p_top
    row_center "${BW}DETAIL AKUN ZIVPN UDP${NC}"
    p_sep
    row "  ${BY}Username :${NC} ${BW}$username${NC}"
    row "  ${BY}Password :${NC} ${BW}$pass${NC}"
    row "  ${BY}Host     :${NC} ${BW}$domain_val${NC}"
    row "  ${BY}Port     :${NC} ${BW}5667 / 6000-19999${NC}"
    row "  ${BY}MaxLogin :${NC} ${BC}$maxl sesi${NC}"
    row "  ${BY}Dibuat   :${NC} ${DIM}$created${NC}"
    row "  ${BY}Expired  :${NC} ${BR}$exp${NC}"
    row "  ${BY}Sisa     :${NC} ${sisa_color}${sisa} hari${NC}"
    row "  ${BY}Status   :${NC} $status"
    p_bot
    echo -ne "\n${BY}[Enter] Kembali...${NC}"; read -r
}

# ─── AUTO CLEANUP ─────────────────────────────────────────
auto_cleanup() {
    init_db
    local users today changed
    users=$(get_users)
    today=$(date +%Y-%m-%d)
    changed=0

    # Delete expired users
    local expired_list
    expired_list=$(echo "$users" | jq -r --arg t "$today" '.[] | select(.expired < $t) | .username')
    for u in $expired_list; do
        users=$(echo "$users" | jq "del(.[] | select(.username==\"$u\"))")
        userdel -f "$u" 2>/dev/null
        send_tg "⏰ *Auto Delete - Akun Expired*
👤 User : \`$u\`
📅 Tanggal : $today"
        changed=1
    done
    [[ $changed -eq 1 ]] && save_users "$users"

    # Check CPU usage and alert
    local cpu_usage
    cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d',' -f1)
    if [[ -n "$cpu_usage" ]] && (( $(echo "${cpu_usage:-0} > 85" | bc -l 2>/dev/null || echo 0) )); then
        send_tg "⚠️ *ALERT: vCPU Tinggi*
💻 CPU Usage : ${cpu_usage}%
📍 Host      : $(hostname)
🕐 Waktu     : $(date '+%Y-%m-%d %H:%M:%S')"
    fi
}

# ─── DOMAIN ───────────────────────────────────────────────
manage_domain() {
    show_logo
    echo -e "${H2}[ PENGATURAN DOMAIN ]${NC}"
    p_top
    local current=""
    [[ -f "$DOMAIN_CONF" ]] && current=$(cat "$DOMAIN_CONF")
    row "  ${BY}Domain aktif : ${BW}${current:-Belum diset}${NC}"
    p_sep
    echo -ne " ${H1}${SIDE}${NC} ${BY}Domain baru (kosong=batal): ${NC}"; read -r new_domain
    p_bot
    if [[ -n "$new_domain" ]]; then
        echo "$new_domain" > "$DOMAIN_CONF"
        echo -e "${BG}[✔] Domain disimpan: ${BW}$new_domain${NC}"
    else
        echo -e "${DIM}[i] Tidak ada perubahan.${NC}"
    fi
    sleep 2
}

# ─── TELEGRAM SETUP ───────────────────────────────────────
setup_telegram() {
    show_logo
    echo -e "${H2}[ KONFIGURASI TELEGRAM BOT ]${NC}"
    local BOT_TOKEN="" CHAT_ID=""
    [[ -f "$TG_CONF" ]] && source "$TG_CONF" 2>/dev/null
    p_top
    row "  ${BY}Bot Token : ${BW}${BOT_TOKEN:-Belum diset}${NC}"
    row "  ${BY}Chat ID   : ${BW}${CHAT_ID:-Belum diset}${NC}"
    p_sep
    echo -ne " ${H1}${SIDE}${NC} ${BY}Bot Token baru (kosong=skip): ${NC}"; read -r new_token
    echo -ne " ${H1}${SIDE}${NC} ${BY}Chat ID baru   (kosong=skip): ${NC}"; read -r new_chat
    p_bot
    [[ -n "$new_token" ]] && BOT_TOKEN="$new_token"
    [[ -n "$new_chat"  ]] && CHAT_ID="$new_chat"
    cat > "$TG_CONF" <<EOF
BOT_TOKEN="$BOT_TOKEN"
CHAT_ID="$CHAT_ID"
EOF
    echo -e "${BY}[~] Mengirim test notifikasi...${NC}"
    send_tg "✅ *NEXUS ZIVPN Bot Terhubung!*
📡 IP VPS : $(curl -s4 --connect-timeout 5 icanhazip.com || echo N/A)
🕐 Waktu  : $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${BG}[✔] Konfigurasi Telegram disimpan & test dikirim.${NC}"
    sleep 2
}

# ─── SPEEDTEST ────────────────────────────────────────────
run_speedtest() {
    show_logo
    echo -e "${H2}[ SPEEDTEST VPS ]${NC}"
    p_top
    row_center "${BY}  Menjalankan speedtest, harap tunggu...${NC}"
    p_bot
    echo ""
    if command -v speedtest-cli &>/dev/null; then
        speedtest-cli --simple 2>/dev/null
    elif command -v speedtest &>/dev/null; then
        speedtest 2>/dev/null
    else
        echo -e "${BY}[~] Menginstall speedtest-cli...${NC}"
        apt-get install -y -qq speedtest-cli > /dev/null 2>&1
        speedtest-cli --simple 2>/dev/null || echo -e "${BR}[✗] speedtest-cli gagal diinstall.${NC}"
    fi
    echo -ne "\n${BY}[Enter] Kembali...${NC}"; read -r
}

# ─── THEME MANAGER ────────────────────────────────────────
manage_theme() {
    while true; do
        show_logo
        rainbow_reset
        echo -e "${H2}[ TEMA TAMPILAN ]${NC}"
        local cur_theme="rainbow"
        [[ -f "$THEME_CONF" ]] && cur_theme=$(cat "$THEME_CONF")
        rb_p_top
        rb_row_center "${BY}Tema Aktif : ${BW}$cur_theme${NC}"
        rb_p_sep
        rb_row " ${BR}[1]${NC}  🌈  Rainbow   ${DIM}— Pelangi per-karakter (Default)${NC}"
        rb_row " ${BB}[2]${NC}  🌊  Ocean     ${DIM}— Biru & Tosca${NC}"
        rb_row " ${BR}[3]${NC}  🔥  Fire      ${DIM}— Merah & Kuning${NC}"
        rb_row " ${BM}[4]${NC}  🌙  Night     ${DIM}— Ungu & Biru Gelap${NC}"
        rb_row " ${BG}[5]${NC}  💡  Neon      ${DIM}— Hijau & Magenta${NC}"
        rb_row " ${BY}[6]${NC}  🏆  Gold      ${DIM}— Emas & Putih${NC}"
        rb_p_sep
        rb_row " ${DIM}[0]${NC}  ←  Kembali"
        rb_p_bot
        echo -ne "${BY}▸ Pilih tema: ${NC}"; read -r th
        case "$th" in
            1) echo "rainbow" > "$THEME_CONF" ;;
            2) echo "ocean"   > "$THEME_CONF" ;;
            3) echo "fire"    > "$THEME_CONF" ;;
            4) echo "night"   > "$THEME_CONF" ;;
            5) echo "neon"    > "$THEME_CONF" ;;
            6) echo "gold"    > "$THEME_CONF" ;;
            0) break ;;
            *) echo -e "${BR}Pilihan tidak valid.${NC}"; sleep 1; continue ;;
        esac
        load_theme
        echo -e "${BG}[✔] Tema berhasil diganti ke: ${BW}$(cat $THEME_CONF)${NC}"; sleep 1
    done
}

# ─── SERVICE MANAGEMENT ───────────────────────────────────
manage_service() {
    while true; do
        show_logo
        echo -e "${H2}[ MANAJEMEN SERVICE ]${NC}"
        local svc_status svc_color
        svc_status=$(systemctl is-active zivpn.service 2>/dev/null || echo "inactive")
        [[ "$svc_status" == "active" ]] && svc_color="$BG" || svc_color="$BR"
        p_top
        row "  ${BY}Status Service : ${svc_color}● $svc_status${NC}"
        p_sep
        row " ${BG}[1]${NC}  ▶  Start Service"
        row " ${BR}[2]${NC}  ■  Stop Service"
        row " ${BY}[3]${NC}  ↺  Restart Service"
        row " ${BC}[4]${NC}  ℹ  Status Detail"
        row " ${BM}[5]${NC}  📋  Lihat Log (50 baris)"
        p_sep
        row " ${DIM}[0]${NC}  ←  Kembali"
        p_bot
        echo -ne "${BY}▸ Pilih: ${NC}"; read -r opt
        case "$opt" in
            1) systemctl start   zivpn.service; echo -e "${BG}[✔] Service dimulai.${NC}";    sleep 1 ;;
            2) systemctl stop    zivpn.service; echo -e "${BY}[~] Service dihentikan.${NC}"; sleep 1 ;;
            3) systemctl restart zivpn.service; echo -e "${BG}[✔] Service di-restart.${NC}"; sleep 1 ;;
            4) systemctl status  zivpn.service; echo -ne "\n${BY}[Enter]...${NC}"; read -r ;;
            5) journalctl -u zivpn.service -n 50 --no-pager; echo -ne "\n${BY}[Enter]...${NC}"; read -r ;;
            0) break ;;
        esac
    done
}

# ─── vCPU MONITOR ─────────────────────────────────────────
monitor_vcpu() {
    show_logo
    echo -e "${H2}[ MONITOR vCPU & SISTEM ]${NC}"
    local cpu_usage
    cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d',' -f1)
    local threshold=80
    p_top
    row "  ${BY}CPU Usage  :${NC} ${BW}${cpu_usage:-N/A}%${NC}"
    row "  ${BY}RAM Used   :${NC} ${BW}$(free -h | awk '/^Mem:/{print $3}') / $(free -h | awk '/^Mem:/{print $2}')${NC}"
    row "  ${BY}Load Avg   :${NC} ${BW}$(uptime | awk -F'load average:' '{print $2}' | xargs)${NC}"
    if (( $(echo "${cpu_usage:-0} > $threshold" | bc -l 2>/dev/null || echo 0) )); then
        p_sep
        row "  ${BR}⚠  CPU melebihi batas ${threshold}%! Alert terkirim ke Telegram.${NC}"
        send_tg "⚠️ *ALERT: vCPU Melebihi Batas*
💻 CPU : ${cpu_usage}%
📍 Host: $(hostname)
🕐 Waktu: $(date '+%Y-%m-%d %H:%M:%S')"
    fi
    p_sep
    row "  ${BY}Top 5 Proses (CPU):${NC}"
    p_bot
    echo ""
    ps aux --sort=-%cpu | awk 'NR<=6{printf "  %-20s %5s%%\n",$11,$3}' 2>/dev/null
    echo -ne "\n${BY}[Enter] Kembali...${NC}"; read -r
}

# ─── UPDATE ───────────────────────────────────────────────
update_script() {
    show_logo
    echo -e "${BY}[~] Memeriksa update...${NC}"
    echo -e "${BG}[✔] Script sudah versi terbaru (v2.0).${NC}"
    sleep 2
}

# ─── MAIN MENU ────────────────────────────────────────────
main_menu() {
    while true; do
        show_logo
        rainbow_reset
        rb_p_top
        rb_row_center "${H2}▸  MANAJEMEN AKUN  ◂${NC}"
        rb_p_sep
        rb_row "  ${BG}[1]${NC}  ➕  Tambah Akun UDP"
        rb_row "  ${BR}[2]${NC}  ➖  Hapus Akun UDP"
        rb_row "  ${BC}[3]${NC}  📋  Daftar Akun UDP"
        rb_row "  ${BY}[4]${NC}  🔍  Detail Akun"
        rb_row "  ${BM}[5]${NC}  ♻️   Renew / Perpanjang Akun"
        rb_row "  ${BW}[6]${NC}  🔑  Ganti Password"
        rb_row "  ${BC}[7]${NC}  🔢  Set Max Login"
        rb_p_sep
        rb_row_center "${H3}▸  SISTEM & KONFIGURASI  ◂${NC}"
        rb_p_sep
        rb_row "  ${BB}[8]${NC}  ⚙️   Manajemen Service ZIVPN"
        rb_row "  ${BG}[9]${NC}  🌐  Pengaturan Domain"
        rb_row "  ${BM}[10]${NC} 🤖  Konfigurasi Telegram Bot"
        rb_row "  ${BC}[11]${NC} 🎨  Tema Tampilan"
        rb_row "  ${BY}[12]${NC} 🚀  Speedtest VPS"
        rb_row "  ${BR}[13]${NC} 📊  Monitor vCPU"
        rb_p_sep
        rb_row_center "${H4}▸  LAINNYA  ◂${NC}"
        rb_p_sep
        rb_row "  ${BG}[14]${NC} 🔄  Cek Update Script"
        rb_row "  ${BR}[99]${NC} 💀  Uninstall NEXUS ZIVPN"
        rb_row "  ${DIM}[0]${NC}  🚪  Keluar"
        rb_p_bot
        echo -ne "${BY}▸ Pilih menu [0-14/99]: ${NC}"; read -r choice
        case "$choice" in
            1)  add_user ;;
            2)  delete_user ;;
            3)  list_users ;;
            4)  detail_user ;;
            5)  renew_user ;;
            6)  change_password ;;
            7)  set_max_login ;;
            8)  manage_service ;;
            9)  manage_domain ;;
            10) setup_telegram ;;
            11) manage_theme ;;
            12) run_speedtest ;;
            13) monitor_vcpu ;;
            14) update_script ;;
            99) uninstall_zivpn ;;
            0)  echo -e "\n${BG}[✔] Sampai jumpa! — NEXUS ZIVPN${NC}\n"; exit 0 ;;
            *)  echo -e "${BR}[✗] Pilihan tidak valid!${NC}"; sleep 1 ;;
        esac
    done
}

# ─── ENTRY POINT ──────────────────────────────────────────
case "$1" in
    --install)
        check_os_support
        install_zivpn
        ;;
    --auto-cleanup)
        auto_cleanup
        ;;
    --uninstall)
        check_os_support
        uninstall_zivpn
        ;;
    --add-user)
        check_os_support
        init_db; add_user
        ;;
    --list-users)
        init_db; list_users
        ;;
    *)
        # Cek OS terlebih dahulu
        check_os_support
        if [[ ! -f "$BIN_PATH" ]]; then
            show_logo
            p_top
            row_center "${BR}  ⚠  ZIVPN BELUM DIINSTALL  ⚠${NC}"
            p_mid
            row "  OS Terdeteksi : ${BW}${OS_PRETTY:-$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'\"' -f2)}${NC}"
            row "  Platform      : ${BC}${OS_FAMILY:-Debian/Ubuntu}${NC}"
            p_sep
            row "  Cara install  : ${BW}bash nexus-zivpn.sh --install${NC}"
            row "  Setelah install: ${BW}zivpn${NC}  atau  ${BW}menu${NC}"
            p_bot
            echo -ne "\n${BY}Install sekarang? [y/N]: ${NC}"; read -r ins
            [[ "$ins" == "y" || "$ins" == "Y" ]] && install_zivpn || exit 0
        else
            main_menu
        fi
        ;;
esac
