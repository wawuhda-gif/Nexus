# SSH-PANEL-PRO v2.1

**Complete VPS Management System with All Protocols & ZiVPN Support**

## 🎯 Features

### ✅ User Management
- **Create Users** for SSH, Dropbear, Stunnel, WebSocket, OpenVPN, V2Ray, ZiVPN, Squid
- **Delete Users** with automatic cleanup
- **Extend Expiry** dates for active users
- **List All Users** with status (ACTIVE/EXPIRED)
- **Auto-check Expired** users with Telegram notifications

### 🎯 ZiVPN Support (Zahid Islam Binary)
- ✅ **Auto-Detection** of CPU architecture (AMD64/ARM)
- ✅ **Automatic Installation** from official GitHub
- ✅ **UDP Protocol** support (Port 7300)
- ✅ **Full Integration** with user management system
- ✅ **Configuration Storage** with user profiles

**GitHub Repository:** https://github.com/zahidbd2/udp-zivpn

### 📱 Telegram Bot Integration
- Setup bot token & chat ID
- Auto-notifications: New user, deleted user, expired user, extended user
- Test bot connectivity
- Enable/disable notifications

### 🌐 Domain Management
- Setup custom domains
- Auto-setup SSL certificates (Let's Encrypt)
- List configured domains
- Full certificate management

### 📊 System Monitoring
- Real-time system status (CPU, RAM, Disk)
- Service status for all protocols
- User statistics (active/expired)
- IP address and hostname info

### 💾 Backup & Restore
- Automatic backup with timestamps
- Restore from backup files
- Complete activity logging
- System logs viewer

### 🔧 Protocol Management
- Install all protocols automatically
- Start/stop/restart services
- Check service status
- Manage protocol ports

### 🔍 Binary & Dependency Check
- Complete binary verification
- System architecture detection
- Installation status for all protocols
- Generate detailed report

---

## 📦 Supported Protocols

| Protocol | Port | Binary | Status |
|----------|------|--------|--------|
| SSH | 22 | openssh-server | ✅ Built-in |
| Dropbear | 143 | dropbear | ✅ Optional |
| Stunnel | 443 | stunnel4 | ✅ Optional |
| WebSocket | 8080 | Custom | ✅ Optional |
| OpenVPN | 1194 | openvpn | ✅ Optional |
| V2Ray | 10000 | v2ray | ✅ Recommended |
| **ZiVPN** | **7300** | **zivpn** | ✅ **Ready** |
| Squid | 3128 | squid | ✅ Optional |

---

## 🚀 Installation

### Quick Start
```bash
# 1. Download script
sudo wget -O ssh-panel-pro.sh https://raw.githubusercontent.com/wawuhda-gif/Nexus/main/ssh-panel-pro.sh

# 2. Make executable
sudo chmod +x ssh-panel-pro.sh

# 3. Run
sudo ./ssh-panel-pro.sh
```

### First Run Setup
1. **Binary Check** - Script verifies all required binaries
2. **Install Missing** - Option to install missing packages
3. **Install ZiVPN** - Auto-install Zahid Islam binary
4. **Setup Telegram** - Configure bot for notifications
5. **Add Domains** - Setup custom domains with SSL

---

## 📋 Configuration Files

```
/etc/ssh-panel/
├── users.conf              # User database
├── telegram.conf           # Telegram bot settings
├── domain.conf             # Domain configurations
├── binary-check.log        # Binary verification report
├── zivpn-USERNAME.conf     # ZiVPN user configs
├── ws-USERNAME.conf        # WebSocket configs
└── vmess-USERNAME.json     # V2Ray configs

/var/log/
└── ssh-panel.log           # Activity logs

/var/backups/ssh-panel/
└── ssh-panel-backup-*.tar.gz  # Backup files
```

---

## 📱 Menu Options

### User Management (1-5)
1. Add New User
2. Delete User
3. Extend User Expiry
4. List All Users
5. Check Expired Users

### System Management (6-9)
6. System Status & Monitoring
7. Protocol Management
8. Domain Management
9. Telegram Bot Setup

### Backup & Maintenance (10-13)
10. Backup System
11. Restore Backup
12. View System Logs
13. Binary & Dependency Check

### Settings (14)
14. Settings
    - Change SSH port
    - Enable/disable Telegram
    - Edit user database
    - Clear logs
    - Install ZiVPN Binary

---

## 🔐 Security Features

- ✅ Password validation (min 6 characters)
- ✅ Username validation (alphanumeric, underscore, dash)
- ✅ User confirmation for delete/restore operations
- ✅ File permissions (600 for configs)
- ✅ Root-only execution
- ✅ Activity logging for audit trail
- ✅ Telegram notifications for all actions

---

## 📊 Binary Checklist

For complete binary requirements, see: **[BINARY-CHECKLIST.md](BINARY-CHECKLIST.md)**

### Essential (Auto-Installed)
- ✅ curl, wget, openssl
- ✅ openssh-server
- ✅ systemd
- ✅ iptables

### Optional (Available on-demand)
- ⚠️ dropbear, stunnel4
- ⚠️ openvpn, nginx, squid
- ⚠️ v2ray (auto-installed)
- ⚠️ certbot, python3

### Special: ZiVPN Binary
- ✅ **Auto-installed** from GitHub (zahidbd2/udp-zivpn)
- ✅ Architecture-aware installation
- ✅ Configuration management

---

## 🎯 ZiVPN Implementation

### Auto Installation
Script automatically:
1. Detects CPU architecture (AMD64/ARM)
2. Downloads correct installer from GitHub
3. Executes installation
4. Verifies binary location
5. Saves configuration files

### User Creation
When creating ZiVPN user:
1. Creates configuration file: `/etc/ssh-panel/zivpn-USERNAME.conf`
2. Sets UDP protocol on port 7300
3. Stores credentials securely
4. Adds to user database
5. Sends Telegram notification

### Configuration Example
```ini
[ZiVPN Configuration]
Username=testuser
Password=securepass
Protocol=UDP
Port=7300
Created=1234567890
BinaryVersion=Zahid-Islam
GitHub=https://github.com/zahidbd2/udp-zivpn
```

---

## 📝 Usage Examples

### Create SSH User
```
Option 1 → Enter username → Enter password → Select SSH → Set expiry days
```

### Create ZiVPN User
```
Option 1 → Enter username → Enter password → Select ZiVPN → Set expiry days
```

### Setup Telegram Bot
```
Option 9 → Enter bot token → Enter chat ID → Auto-test connection
```

### Check All Binaries
```
Option 13 → View complete binary report → Option to install missing
```

---

## 🐛 Troubleshooting

### ZiVPN Not Installing
```bash
# Manual installation
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    wget -O zi.sh https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/zi.sh
    sudo bash zi.sh
else
    bash <(curl -fsSL https://raw.githubusercontent.com/zahidbd2/udp-zivpn/main/zi2.sh)
fi
```

### Telegram Not Working
```bash
# Check configuration
cat /etc/ssh-panel/telegram.conf

# Test bot manually
curl -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d "chat_id=<CHATID>" \
  -d "text=Test Message"
```

### Missing Binaries
```bash
# Run binary check
Option 13 → View report → Install missing

# Or manually
sudo apt-get install -y openssh-server dropbear openvpn nginx squid
```

---

## 📞 Support & Issues

- **Script Repository:** https://github.com/wawuhda-gif/Nexus
- **ZiVPN Repository:** https://github.com/zahidbd2/udp-zivpn
- **Report Issues:** Create issue in repository

---

## 📜 License

Open Source - Free to use and modify

---

## 🎉 Credits

- **SSH-Panel-Pro:** Developed for comprehensive VPS management
- **ZiVPN Binary:** Created by Zahid Islam (zahidbd2)
- **Based on:** V2Ray, OpenVPN, Stunnel, and other open-source projects

---

## 📈 Version History

### v2.1 (Current)
- ✅ Complete ZiVPN support (Zahid Islam binary)
- ✅ Binary & dependency checker
- ✅ Architecture auto-detection
- ✅ Enhanced error handling
- ✅ Comprehensive documentation

### v2.0
- Core features implementation
- All protocol support
- Telegram integration
- Domain management

### v1.0
- Initial release
- Basic SSH management

---

**Last Updated:** 2026-04-29
**Status:** ✅ PRODUCTION READY
