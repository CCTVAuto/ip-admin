#!/bin/bash

# -------------------- BASIC INFO --------------------
ISP=$(curl -s ipinfo.io/org | cut -d " " -f 2-10)
MYIP=$(curl -sS ipv4.icanhazip.com)

owner="CCTVAuto"
gitlink="https://raw.githubusercontent.com"
tokengit=$(cat /etc/admin/token 2>/dev/null)
email=$(cat /etc/admin/email 2>/dev/null)

# -------------------- PERMISSION CHECK --------------------
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

# -------------------- GIT SETUP --------------------
check_git() {
    if ! command -v git &>/dev/null; then
        echo "⚠️ Git not found, installing..."
        if [[ -f /etc/debian_version ]]; then
            apt update -y && apt install git -y
        elif [[ -f /etc/redhat-release ]]; then
            yum install git -y
        else
            echo "❌ Unsupported OS, please install git manually."
            menu
        fi
    fi
}

git_setup() {
    git config --global user.email "${email}"
    git config --global user.name "${owner}"
}

git_clone_repo() {
    local repo_name="$1"
    local tmp_dir="/root/${repo_name}-$(date +%s)"
    rm -rf "$tmp_dir"
    mkdir -p "$tmp_dir"
    git clone "https://github.com/${owner}/${repo_name}.git" "$tmp_dir"
    echo "$tmp_dir"
}

git_push() {
    local repo_dir="$1"
    local commit_msg="$2"
    local repo_name="$3"

    cd "$repo_dir" || return
    git add .
    git commit -m "$commit_msg"
    git push -f https://${tokengit}@github.com/${owner}/${repo_name}.git
}

prepare_access_file() {
    [[ ! -f "access" ]] && touch access
}

# -------------------- CLIENT FUNCTIONS --------------------
load_clients() {
    if [[ ! -f "access" ]]; then
        echo "File 'access' not found!"
        return 1
    fi
    clear
    echo -e "\033[1;34m----------------------------------------\033[0m"
    echo -e "\033[1;33m              LIST OF CLIENTS           \033[0m"
    echo -e "\033[1;34m----------------------------------------\033[0m"
    grep -E "^### " "access" | cut -d ' ' -f 2-4
    echo -e "\033[1;34m----------------------------------------\033[0m"
}

select_client() {
    if [[ ! -f "access" ]]; then
        echo "File 'access' not found!"
        sleep 2
        return 1
    fi

    local total_clients
    total_clients=$(grep -c -E "^### " "access")
    if [[ ${total_clients} -eq 0 ]]; then
        echo "No clients found!"
        sleep 2
        return 1
    fi

    clear
    echo -e "\033[1;34m----------------------------------------\033[0m"
    echo -e "\033[1;33m              LIST OF CLIENTS           \033[0m"
    echo -e "\033[1;34m----------------------------------------\033[0m"
    printf " %-3s %-15s %-12s %-15s\n" "No" "IP Address" "Expired" "Name"
    echo -e "\033[1;34m----------------------------------------\033[0m"

    nl -w2 -s' ' <(grep -E "^### " "access" | awk '{printf "%-15s %-12s %-15s\n",$2,$3,$4}')

    echo -e "\033[1;34m----------------------------------------\033[0m"

    until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${total_clients} ]]; do
        if [[ ${total_clients} -eq 1 ]]; then
            read -rp "Select client [1]: " CLIENT_NUMBER
        else
            read -rp "Select client [1-${total_clients}]: " CLIENT_NUMBER
        fi
    done

    USER_IP=$(grep -E "^### " "access" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}p")
    EXP_DATE=$(grep -E "^### " "access" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}p")
    CLIENT_NAME=$(grep -E "^### " "access" | cut -d ' ' -f 4 | sed -n "${CLIENT_NUMBER}p")
}

display_client_info() {
    local daft="$USER_IP"
    local hariini=$(date +"%Y-%m-%d")
    local exp="$EXP_DATE"
    local client="$CLIENT_NAME"
    local type="$SCRIPT_TYPE"
    local links="apt update -y && apt install -y sudo wget curl coreutils && wget -O install.sh https://raw.githubusercontent.com/${owner}/resources/main/service/install.sh && chmod +x install.sh && ./install.sh"

    clear
    echo -e "\033[0;34m----------------------------------------\033[0m"
    echo -e "\E[44;1;39m      Client VPS Added Successfully     \E[0m"
    echo -e "\033[0;34m----------------------------------------\033[0m"
    echo "  Ip VPS        : $daft"
    echo "  Register Date : $hariini"
    echo "  Expired Date  : $exp"
    echo "  Client Name   : $client"
    echo "  Script Type   : $type"
    echo -e "\033[0;34m----------------------------------------\033[0m"
    echo "  Link Script   : "
    echo ""
    echo -e '```'${links}'```'
    echo ""
    echo -e "\033[0;34m----------------------------------------\033[0m"
    echo "              Nota Kaki"
    echo -e "\033[0;34m----------------------------------------\033[0m"
    echo " ðŸ”¥ Siapkan email untuk cert xray ðŸ”¥ "
    echo " ðŸ”¥ Pastikan domain dah siap2 pointing di CF sebelum install ðŸ”¥ "
    echo -e "\033[0;34m----------------------------------------\033[0m"
}

add_client() {
    REPO_DIR=$(git_clone_repo "$1")
    cd "$REPO_DIR" || return
    prepare_access_file
    clear
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\033[1;33m             Add IP Client           \033[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"

    read -rp "New Client Name: " NAME
    read -rp "Client IP: " IP
    read -rp "Berapa hari aktif (contoh 30): " ACTIVE_DAYS

    # Kira tarikh expired dari hari ini
    EXP=$(date -d "+$ACTIVE_DAYS days" +"%Y-%m-%d")

    echo "### $IP $EXP $NAME" >> access
    git_push "$REPO_DIR" "Add client $NAME" "$1"

    cd /root || true
    rm -rf "$REPO_DIR"

    USER_IP="$IP"
    EXP_DATE="$EXP"
    CLIENT_NAME="$NAME"
    SCRIPT_TYPE="$1"
    display_client_info
}

del_client() {
    REPO_DIR=$(git_clone_repo "$1")
    cd "$REPO_DIR" || return
    prepare_access_file

    select_client || { cd /root; rm -rf "$REPO_DIR"; return; }

    sed -i "/^### $USER_IP $EXP_DATE $CLIENT_NAME/d" access
    git_push "$REPO_DIR" "Delete client $CLIENT_NAME" "$1"

    cd /root || true
    rm -rf "$REPO_DIR"
    clear
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\033[1;33m               Delete Client         \033[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo "Client $CLIENT_NAME deleted and pushed."
    echo -e "\033[0;34m------------------------------------\033[0m"
}

renew_client() {
    REPO_DIR=$(git_clone_repo "$1")
    cd "$REPO_DIR" || return
    prepare_access_file

    select_client || { cd /root; rm -rf "$REPO_DIR"; return; }
    clear
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\033[1;33m             Renew Date Client      \033[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo "Current Expiry Date : $EXP_DATE"
    read -rp "Tambah berapa hari (contoh 30): " ADD_DAYS

    # Kira tarikh baru dari expiry lama
    NEW_EXP=$(date -d "$EXP_DATE +$ADD_DAYS days" +"%Y-%m-%d")

    sed -i "s/^### $USER_IP $EXP_DATE $CLIENT_NAME/### $USER_IP $NEW_EXP $CLIENT_NAME/" access
    git_push "$REPO_DIR" "Renew client $CLIENT_NAME ($ADD_DAYS days)" "$1"

    cd /root || true
    rm -rf "$REPO_DIR"
    clear
    echo -e "\033[0;34m------------------------------------\033[0m"
    echo -e "\033[1;33mClient $CLIENT_NAME renewed until $NEW_EXP\033[0m"
    echo -e "\033[0;34m------------------------------------\033[0m"
}

cek_client() {
    REPO_DIR=$(git_clone_repo "$1")
    cd "$REPO_DIR" || return
    prepare_access_file

    load_clients

    cd /root || true
    rm -rf "$REPO_DIR"
}

# -------------------- MENU --------------------
menu_repo() {
    while true; do
        clear
        echo -e "\033[0;34m------------------------------------\033[0m"
        echo -e "\033[1;33m             SELECT REPOSITORY      \033[0m"
        echo -e "\033[0;34m------------------------------------\033[0m"
        echo ""
        echo -e " [\e[36m 01 \e[0m] Multiport WS"
        echo -e " [\e[36m 02 \e[0m] Multiport XTLS"
        echo -e " [\e[36m 03 \e[0m] Admin IP"
        echo ""
        echo -e "\033[0;34m------------------------------------\033[0m"
        read -rp "Choose repository [1-3] or [x] back to menu: " REP

        case $REP in
            1) REPO="client-multiport-ws";;
            2) REPO="client-multiport-xtls";;
            3) REPO="ip-admin";;
            x|X) menu ;;
            *) echo -e "\033[1;31mInvalid selection!\033[0m"; sleep 1; continue;;
        esac

        SCRIPT_TYPE="$REPO"

        clear
        echo ""
        echo -e "\033[0;34m------------------------------------\033[0m"
        echo -e "\033[1;33m                ACTION MENU         \033[0m"
        echo -e "\033[0;34m------------------------------------\033[0m"
        echo ""
        echo -e " [\e[36m 01 \e[0m] Add Client"
        echo -e " [\e[36m 02 \e[0m] Delete Client"
        echo -e " [\e[36m 03 \e[0m] Renew Client"
        echo -e " [\e[36m 04 \e[0m] Check Clients"
        echo ""
        echo -e "\033[0;34m------------------------------------\033[0m"
        read -rp "Select action [1-4] or [x] back to menu: " ACT

        case $ACT in
            1) add_client "$REPO";;
            2) del_client "$REPO";;
            3) renew_client "$REPO";;
            4) cek_client "$REPO";;
            x|X) menu-admin ;;
            *) echo -e "\033[1;31mInvalid action!\033[0m"; sleep 1;;
        esac

        echo -e "\nPress Enter to go back..."
        read -r
    done
}

# -------------------- MAIN --------------------
PERMISSION
check_git
git_setup
menu_repo

