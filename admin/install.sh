#!/bin/bash
# ==================== COLOR DEFINITIONS ====================
DF='\e[39m'
Bold='\e[1m'
Blink='\e[5m'
NC='\e[0m'

# ==================== SYSTEM INFO ====================
ISP=$(curl -s ipinfo.io/org | cut -d " " -f 2-10)
MYIP=$(wget -qO- ipinfo.io/ip)
owner="CCTVAuto"
resourses="ip-admin/main/admin"
gitlink="https://raw.githubusercontent.com"
echo "Checking VPS..."

# ==================== PERMISSION CHECK ====================
PERMISSION() {
    cek=$(curl -sS "${gitlink}/${owner}/ip-admin/main/access" | awk '{print $2}' | grep "$MYIP")
    if [[ "$cek" == "$MYIP" ]]; then
        echo -e "${Bold}Permission Accepted...${NC}"
    else
        echo -e "${Bold}Permission Denied!${NC}"
        rm -rf /etc/admin > /dev/null 2>&1
        rm -rf *.sh* > /dev/null 2>&1
        clear
        echo "Your IP NOT REGISTER / EXPIRED | Contact Telegram @CCTVAuto to Unlock"
        exit 0
    fi
    clear
}
PERMISSION

# ==================== ROOT & VIRTUALIZATION CHECK ====================
if [[ "$EUID" -ne 0 ]]; then
    echo "You need to run this script as root"
    exit 1
fi
if [[ "$(systemd-detect-virt)" == "openvz" ]]; then
    echo "OpenVZ is not supported"
    exit 1
fi

# ==================== SETUP ACCESS ====================
rm -rf /etc/admin > /dev/null 2>&1
mkdir -p /etc/admin

read -p "INPUT OWNER ACCESS CODE: " ans
echo -e "$ans" > /etc/admin/token

read -p "INPUT OWNER EMAIL: " email
echo -e "$email" > /etc/admin/email

# ==================== INSTALL ADMIN MENU ====================
echo -e "\033[0;34m------------------------------------\033[0m"
echo -e "\E[44;1;39m          Install Admin Menu        \E[0m"
echo -e "\033[0;34m------------------------------------\033[0m"
sleep 2

wget -qO /usr/bin/menu-admin "${gitlink}/${owner}/${resourses}/menu-admin.sh" && chmod +x /usr/bin/menu-admin
wget -qO /usr/bin/xp-ip "${gitlink}/${owner}/${resourses}/xp-ip.sh" && chmod +x /usr/bin/xp-ip

# ==================== SETUP CRON (SAFE) ====================
# Hapus old entry antara tag
sed -i "/^# IPREGBEGIN_EXP/,/^# IPREGEND_EXPIP/d" /etc/crontab

# Tambah cron baru cuma kalau belum wujud
if ! grep -q "/usr/bin/xp-ip" /etc/crontab; then
cat << EOF >> /etc/crontab
# IPREGBEGIN_EXP
1 0 * * * root /usr/bin/xp-ip # delete expired IP VPS License
# IPREGEND_EXPIP
EOF
echo "Cron job untuk delete expired IP ditambah."
fi

# ==================== CLEANUP ====================
sleep 2
clear
rm -f /root/install.sh
rm -f /root/.bash_history

sleep 2
menu-admin
