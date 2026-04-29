# SSH-Panel-Pro v2.1 - Binary & Dependency Checklist

## 🔍 Complete Binary Requirement Check

### Architecture Support
- ✅ **AMD64** (x86_64)
- ✅ **ARMv7** (armv7l)
- ✅ **ARM64** (aarch64)

---

## 📦 **ESSENTIAL SYSTEM TOOLS** (Required)

| Binary | Package | Status | Purpose |
|--------|---------|--------|----------|
| `curl` | curl | ✅ REQUIRED | HTTP requests, Telegram bot |
| `wget` | wget | ✅ REQUIRED | Download files, installers |
| `openssl` | openssl | ✅ REQUIRED | SSL/TLS, encryption |
| `base64` | coreutils | ✅ REQUIRED | Encoding/decoding |
| `sed` | sed | ✅ REQUIRED | Text manipulation |
| `awk` | gawk | ✅ REQUIRED | Data processing |
| `grep` | grep | ✅ REQUIRED | Pattern matching |

**Installation:**
```bash
apt-get install -y curl wget openssl coreutils sed gawk grep
```

---

## 🔐 **SSH/ACCESS PROTOCOLS**

| Binary | Package | Port | Status | Implementation |
|--------|---------|------|--------|----------------|
| `sshd` | openssh-server | 22 | ✅ INSTALLED | OpenSSH daemon |
| `ssh-keygen` | openssh-client | - | ✅ INSTALLED | Key generation |
| `dropbear` | dropbear | 143 | ⚠️ OPTIONAL | Lightweight SSH |
| `dropbearkey` | dropbear | - | ⚠️ OPTIONAL | Dropbear key gen |
| `stunnel4` | stunnel4 | 443 | ⚠️ OPTIONAL | SSL/TLS wrapper |

**Installation:**
```bash
apt-get install -y openssh-server openssh-client dropbear stunnel4
```

---

## 🌐 **VPN & TUNNELING PROTOCOLS**

| Binary | Package | Port | Status | Implementation |
|--------|---------|------|--------|----------------|
| `openvpn` | openvpn | 1194 | ⚠️ OPTIONAL | OpenVPN server |
| `nginx` | nginx | 80/443 | ✅ RECOMMENDED | Web/proxy server |
| `squid` | squid | 3128 | ⚠️ OPTIONAL | Proxy server |
| `socat` | socat | Custom | ⚠️ OPTIONAL | Socket/port forwarder |

**Installation:**
```bash
apt-get install -y openvpn nginx squid socat
```

---

## 🚀 **ADVANCED PROTOCOLS**

### **V2Ray / XRay** (Port: 10000)
**Status:** ⚠️ OPTIONAL but RECOMMENDED

**Installation Method 1 (Official FHS):**
```bash
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
```

**Installation Method 2 (Direct Binary):**
```bash
wget https://github.com/v2fly/v2ray-core/releases/download/v4.45.2/v2ray-linux-64.zip
unzip v2ray-linux-64.zip -d /usr/local/bin/
```

**Verification:**
```bash
v2ray version
```

---

## 🎯 **ZIVPN (ZAHID ISLAM BINARY)** - ⭐ SPECIAL INSTALLATION

### **Repository:** https://github.com/zahidbd2/udp-zivpn
**Port:** 7300 (UDP)
**Status:** ✅ AUTO-INSTALLED via Script

### **Auto-Installation (Recommended)**
Script automatically detects CPU architecture and installs:

```bash
# AMD64 (x86_64)
wget -O zi.sh https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/zi.sh
sudo bash zi.sh

# ARM (armv7l, aarch64)
bash <(curl -fsSL https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/zi2.sh)
```

### **Manual Binary Locations (After Installation)**
- AMD64: `/usr/local/bin/zivpn` or `/usr/bin/zivpn`
- ARM: `/usr/local/bin/zivpn` or `/usr/bin/zivpn`

### **Verify Installation**
```bash
which zivpn
zivpn --version
```

### **Configuration Files**
- User configs: `/etc/ssh-panel/zivpn-USERNAME.conf`
- Service: `/etc/systemd/system/zivpn.service`
- Logs: `/var/log/zivpn.log`

---

## 📜 **DATABASE & SSL CERTIFICATES**

| Binary | Package | Status | Purpose |
|--------|---------|--------|----------|
| `certbot` | certbot | ⚠️ OPTIONAL | Let's Encrypt SSL |
| `mysql` | mysql-client | ⚠️ OPTIONAL | MySQL client |
| `sqlite3` | sqlite3 | ⚠️ OPTIONAL | SQLite database |
| `htpasswd` | apache2-utils | ✅ RECOMMENDED | Squid auth |

**Installation:**
```bash
apt-get install -y certbot mysql-client sqlite3 apache2-utils
```

---

## 🛠️ **UTILITY PACKAGES**

| Binary | Package | Status | Purpose |
|--------|---------|--------|----------|
| `systemctl` | systemd | ✅ INSTALLED | Service management |
| `ufw` | ufw | ⚠️ OPTIONAL | Firewall |
| `iptables` | iptables | ✅ INSTALLED | IP filtering |
| `python3` | python3 | ⚠️ OPTIONAL | Scripting |
| `nano` | nano | ⚠️ OPTIONAL | Text editor |

**Installation:**
```bash
apt-get install -y ufw iptables python3 nano
```

---

## 📋 **COMPLETE INSTALLATION SCRIPT**

```bash
#!/bin/bash

# Update package list
sudo apt-get update

# Install all essential packages
sudo apt-get install -y \
  curl wget openssl coreutils sed gawk grep \
  openssh-server openssh-client dropbear stunnel4 \
  openvpn nginx squid socat \
  certbot mysql-client sqlite3 apache2-utils \
  ufw iptables python3 nano

# Install V2Ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# Install ZiVPN (Auto-detects architecture)
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    wget -O /tmp/zi.sh https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/zi.sh
    sudo bash /tmp/zi.sh
else
    bash <(curl -fsSL https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/zi2.sh)
fi

echo "All binaries installed successfully!"
```

---

## ✅ **BINARY CHECK REPORT**

Run this in SSH-Panel-Pro to generate full report:
```
Option 13 → Binary & Dependency Check
```

Report saved to: `/etc/ssh-panel/binary-check.log`

---

## 🔗 **IMPORTANT GITHUB REPOSITORIES**

| Protocol | Repository | Notes |
|----------|-----------|-------|
| ZiVPN | https://github.com/zahidbd2/udp-zivpn | Zahid Islam Official |
| V2Ray | https://github.com/v2fly/v2ray-core | Official V2Ray |
| Stunnel | https://www.stunnel.org/ | SSL wrapper |
| OpenVPN | https://openvpn.net/ | Official VPN |

---

## 📊 **SYSTEM REQUIREMENTS**

- **OS:** Ubuntu 18.04+, Debian 10+
- **CPU:** Any (Auto-detects architecture)
- **RAM:** 512 MB minimum
- **Disk:** 1 GB minimum
- **Ports:** 22, 80, 143, 443, 1194, 3128, 7300, 8080, 10000 (configurable)

---

## 🚀 **QUICK START**

```bash
# 1. Download script
sudo wget -O /usr/local/bin/ssh-panel-pro.sh https://raw.githubusercontent.com/wawuhda-gif/Nexus/main/ssh-panel-pro.sh

# 2. Make executable
sudo chmod +x /usr/local/bin/ssh-panel-pro.sh

# 3. Run
sudo ssh-panel-pro.sh

# 4. Select option 13 to check all binaries
```

---

**Last Updated:** 2026-04-29
**Version:** 2.1
**Status:** ✅ READY FOR PRODUCTION
