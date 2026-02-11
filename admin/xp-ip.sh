#!/bin/bash
# =========================
# VPS Multiport Management
# =========================

# -------- Color Validation --------
green='\e[32m'
Lyellow='\e[93m'
red='\e[31m'
NC='\e[0m'

# -------- Variables --------
MYIP=$(wget -qO- ipinfo.io/ip)
owner="CCTVAuto"
gitlink="https://raw.githubusercontent.com"
tokengit=$(cat /etc/admin/token)
email=$(cat /etc/admin/email)

echo "Checking VPS..."

# -------- Permission Check --------
PERMISSION() {
    if curl -sS ${gitlink}/${owner}/ip-admin/main/access | awk '{print $2}' | grep -qw "$MYIP"; then
        echo -e "\033[0;34m------------------------------------\033[0m"
        echo "Permission Accepted..."
        echo -e "\033[0;34m------------------------------------\033[0m"
    else
        echo -e "\033[0;34m------------------------------------\033[0m"
        echo "Permission Denied!"
        echo -e "\033[0;34m------------------------------------\033[0m"
        rm -rf /etc/admin > /dev/null 2>&1
        rm -rf *.sh* > /dev/null 2>&1
        clear
        echo "Your IP NOT REGISTER / EXPIRED | Contact Telegram @CCTVAuto to Unlock"
        sleep 3
        exit 1
    fi
    clear
}

# -------- Multiport Update Function --------
update_multiport() {
    local repo="$1"
    local backup_file="$2"

    rm -rf /root/$repo
    rm -rf /etc/admin/$backup_file

    git config --global user.email "$email"
    git config --global user.name "$owner"

    git clone https://github.com/$owner/$repo.git
    cp /root/$repo/access /etc/admin/$backup_file

    cd /root/$repo
    rm -rf .git
    git init

    echo -e "[ ${Lyellow}INFO${NC} ] Checking list..."
    grep -E "^### " "access" | cut -d ' ' -f 2-4 | nl -s '. '

    data=( $(grep '^###' "access" | cut -d ' ' -f 2) )
    now=$(date +"%Y-%m-%d")

    for user in "${data[@]}"; do
        exp=$(grep -w "^### $user" "access" | cut -d ' ' -f 3)
        d1=$(date -d "$exp" +%s)
        d2=$(date -d "$now" +%s)
        exp2=$(( (d1 - d2) / 86400 ))
        if [[ "$exp2" -le 0 ]]; then
            sed -i "/^### $user $exp /d" "access"
        fi
    done

    git add .
    git commit -m expired
    git branch -M main
    git remote add origin https://github.com/$owner/$repo.git
    git push -f https://${tokengit}@github.com/$owner/$repo.git

    rm -rf /root/$repo
    cd
}

# -------- Main --------
PERMISSION

update_multiport "client-multiport-ws" "backup-client-multiport-ws.txt"
sleep 2
update_multiport "client-multiport-xtls" "backup-client-multiport-xtls.txt"

echo -e "${green}All multiport updates completed successfully.${NC}"
