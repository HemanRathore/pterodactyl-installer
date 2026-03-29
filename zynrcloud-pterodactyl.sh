#!/bin/bash
# ============================================================
#
#  ███████╗██╗   ██╗███╗   ██╗██████╗  ██████╗██╗      ██████╗ ██╗   ██╗██████╗
#  ╚══███╔╝╚██╗ ██╔╝████╗  ██║██╔══██╗██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
#    ███╔╝  ╚████╔╝ ██╔██╗ ██║██████╔╝██║     ██║     ██║   ██║██║   ██║██║  ██║
#   ███╔╝    ╚██╔╝  ██║╚██╗██║██╔══██╗██║     ██║     ██║   ██║██║   ██║██║  ██║
#  ███████╗   ██║   ██║ ╚████║██║  ██║╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
#  ╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝
#
#  ══════════════════════════════════════════════════════════════════════
#  ★★★   PTERODACTYL MASTER COMMAND  v4.4.14  — by ZynrCloud   ★★★
#  ══════════════════════════════════════════════════════════════════════
#
#         ░▒▓█  PROUDLY HOSTED & POWERED BY  Z Y N R C L O U D  █▓▒░
#
#         Website  :  https://zynrcloud.com
#         Discord  :  https://discord.gg/zynrcloud
#         GitHub   :  https://github.com/zynrcloud
#         Developer:  ZynrCloud Core Infrastructure Team
#         Script   :  zynrcloud-pterodactyl.sh  v4.4.14
#
#  ══════════════════════════════════════════════════════════════════════
#  ZynrCloud delivers enterprise-grade game server hosting, VPS, and
#  managed Pterodactyl infrastructure. Fast. Reliable. Always online.
#  ══════════════════════════════════════════════════════════════════════
#
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
WHITE='\033[1;37m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

ok()   { echo -e "${GREEN}  [✔] $*${RESET}"; }
err()  { echo -e "${RED}  [✘] $*${RESET}"; }
info() { echo -e "${CYAN}  [•] $*${RESET}"; }
warn() { echo -e "${YELLOW}  [!] $*${RESET}"; }
sep()  { echo -e "${DIM}  ──────────────────────────────────────────────────────${RESET}"; }
hsep() { echo -e "${CYAN}  ══════════════════════════════════════════════════════${RESET}"; }
ask()  { echo -en "${MAGENTA}  [?] $* ${RESET}"; }
step() { echo -e "\n${BOLD}${WHITE}  ──[ $* ]──${RESET}"; }

require_root() {
    [[ $EUID -ne 0 ]] && { err "Run as root: sudo bash $0"; exit 1; }
}

detect_os() {
    [ -f /etc/os-release ] && . /etc/os-release && OS=$ID && OS_VERSION=$VERSION_ID \
        || { err "Cannot detect OS"; exit 1; }
}

# Spinner — call after backgrounding a command with &
spinner() {
    local pid=$! sp='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}[%s]${RESET} %s..." "${sp:i++%${#sp}:1}" "$1"
        sleep 0.1
    done
    wait "$pid"; local rc=$?
    [ $rc -eq 0 ] \
        && printf "\r  ${GREEN}[✔]${RESET} %-55s\n" "$1" \
        || printf "\r  ${RED}[✘]${RESET} %-55s (exit $rc)\n" "$1 FAILED"
    return $rc
}

# Check if nginx is installed
nginx_available() { command -v nginx &>/dev/null; }

# ═══════════════════════════════════════════════════════════════
#   ADD PHP REPO + INSTALL PHP 8.2  (Ubuntu 20/22/24 + Debian 11/12/13)
#   Always ensures php8.2-fpm is actually installable
# ═══════════════════════════════════════════════════════════════
_add_php_repo() {
    step "PHP 8.2 Repository"

    # Detect OS first
    local DISTRO CODENAME
    DISTRO=$(   . /etc/os-release 2>/dev/null; echo "${ID:-debian}" | tr '[:upper:]' '[:lower:]')
    CODENAME=$( . /etc/os-release 2>/dev/null; echo "${VERSION_CODENAME:-$(lsb_release -sc 2>/dev/null)}")
    ok "OS: ${DISTRO} ${CODENAME}"

    # Check if php8.2-fpm already available
    if apt-cache show php8.2-fpm &>/dev/null 2>&1; then
        ok "PHP 8.2 packages already available in apt"
        return 0
    fi

    info "PHP 8.2 not in apt — installing base tools..."

    # Minimal base tools — different sets for Ubuntu vs Debian
    if [[ "$DISTRO" == "ubuntu" ]]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            curl wget gnupg2 gpg ca-certificates lsb-release \
            apt-transport-https software-properties-common 2>&1 | tail -3
    else
        # Debian — software-properties-common does NOT exist on Debian
        # Install only what's actually in Debian repos
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            curl wget gnupg2 gpg ca-certificates lsb-release \
            apt-transport-https 2>&1 | tail -3
    fi

    # Verify curl is now available
    if ! command -v curl &>/dev/null; then
        # Last resort — try wget as fallback downloader
        if ! command -v wget &>/dev/null; then
            err "Neither curl nor wget available. Cannot download PHP repo key."
            err "Run manually:  apt-get install -y curl"
            return 1
        fi
        info "curl not found — will use wget as fallback"
    fi

    # ── Ubuntu: use Ondrej PPA ────────────────────────────────
    if [[ "$DISTRO" == "ubuntu" ]]; then
        info "Adding ppa:ondrej/php (Ubuntu ${CODENAME})..."
        rm -f /etc/apt/sources.list.d/ondrej-ubuntu-php-*.list 2>/dev/null
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php 2>&1 | tail -3

    # ── Debian: use packages.sury.org ────────────────────────
    else
        # Map Debian testing/unstable/future to bookworm (last stable)
        local SURY_CN="$CODENAME"
        case "$CODENAME" in
            trixie|forky|sid|unstable|testing|"")
                SURY_CN="bookworm"
                warn "Debian ${CODENAME} — using 'bookworm' Sury repo (compatible)"
                ;;
        esac

        info "Adding Sury PHP repo for Debian ${SURY_CN}..."

        # Download GPG key — try curl first, fall back to wget
        rm -f /usr/share/keyrings/sury-php.gpg 2>/dev/null
        local KEY_URL="https://packages.sury.org/php/apt.gpg"

        if command -v curl &>/dev/null; then
            curl -fsSL "$KEY_URL" | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
        else
            wget -qO- "$KEY_URL" | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
        fi

        if [ ! -s /usr/share/keyrings/sury-php.gpg ]; then
            err "Failed to download Sury GPG key"
            err "Check internet: curl -fsSL https://packages.sury.org/php/apt.gpg"
            return 1
        fi
        chmod 644 /usr/share/keyrings/sury-php.gpg

        echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${SURY_CN} main" \
            > /etc/apt/sources.list.d/sury-php.list
        ok "Sury repo written for ${SURY_CN}"
    fi

    info "Running apt-get update after repo add..."
    DEBIAN_FRONTEND=noninteractive apt-get update -y 2>&1 | grep -E "^(Get|Err|W:|E:)" | head -10

    # Final check
    if apt-cache show php8.2-fpm &>/dev/null 2>&1; then
        ok "PHP 8.2 packages now available"
        return 0
    else
        err "PHP 8.2 still not available after repo add!"
        err "OS: ${DISTRO} ${CODENAME}  |  Sury target: ${SURY_CN:-$CODENAME}"
        err ""
        err "Manual fix — run these on your server:"
        err "  apt-get install -y curl gpg"
        err "  curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor > /usr/share/keyrings/sury-php.gpg"
        err "  echo 'deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ bookworm main' > /etc/apt/sources.list.d/sury-php.list"
        err "  apt-get update && apt-get install -y php8.2-fpm"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
#   BANNER
# ═══════════════════════════════════════════════════════════════
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'ASCIIEOF'
  ███████╗██╗   ██╗███╗   ██╗██████╗  ██████╗██╗      ██████╗ ██╗   ██╗██████╗
  ╚══███╔╝╚██╗ ██╔╝████╗  ██║██╔══██╗██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
    ███╔╝  ╚████╔╝ ██╔██╗ ██║██████╔╝██║     ██║     ██║   ██║██║   ██║██║  ██║
   ███╔╝    ╚██╔╝  ██║╚██╗██║██╔══██╗██║     ██║     ██║   ██║██║   ██║██║  ██║
  ███████╗   ██║   ██║ ╚████║██║  ██║╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
  ╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝
ASCIIEOF
    echo -e "${RESET}"
    echo -e "${BOLD}${WHITE}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ⚡⚡  PTERODACTYL MASTER COMMAND  v4.4.14  ⚡⚡              ║${RESET}"
    echo -e "${BOLD}${CYAN}  ║  ░▒▓█  Hosted & Powered by  Z Y N R C L O U D  █▓▒░         ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  🌐  https://zynrcloud.com  •  discord.gg/zynrcloud          ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  🚀  Enterprise Game Hosting • VPS • Managed Pterodactyl     ║${RESET}"
    echo -e "${BOLD}${WHITE}  ╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════
#   MAIN MENU
# ═══════════════════════════════════════════════════════════════
main_menu() {
    show_banner
    echo -e "${BOLD}${WHITE}  SELECT AN OPTION:${RESET}"
    hsep
    echo -e "  ${BOLD}${GREEN}── INSTALL ─────────────────────────────────────────────${RESET}"
    echo -e "  ${GREEN}[1]${RESET}   🚀  Install Panel Only"
    echo -e "  ${GREEN}[2]${RESET}   🔧  Install Wings Only"
    echo -e "  ${GREEN}[3]${RESET}   💎  Install Panel + Wings (Combined, Same Server)"
    hsep
    echo -e "  ${BOLD}${RED}── UNINSTALL ───────────────────────────────────────────${RESET}"
    echo -e "  ${RED}[4]${RESET}   🗑️   Uninstall Panel"
    echo -e "  ${RED}[5]${RESET}   🗑️   Uninstall Wings"
    echo -e "  ${RED}[6]${RESET}   💣  Uninstall Everything (Panel + Wings + Docker)"
    hsep
    echo -e "  ${BOLD}${YELLOW}── UPDATE ──────────────────────────────────────────────${RESET}"
    echo -e "  ${YELLOW}[7]${RESET}   🔄  Update Panel"
    echo -e "  ${YELLOW}[8]${RESET}   🔄  Update Wings"
    echo -e "  ${YELLOW}[9]${RESET}   🔄  Update Both (Panel + Wings)"
    hsep
    echo -e "  ${BOLD}${CYAN}── FIX / MANAGE ────────────────────────────────────────${RESET}"
    echo -e "  ${CYAN}[10]${RESET}  🛠️   Fix / Repair Panel"
    echo -e "  ${CYAN}[11]${RESET}  🛠️   Fix / Repair Wings"
    echo -e "  ${MAGENTA}[12]${RESET}  🧩  Blueprints Manager"
    echo -e "  ${MAGENTA}[13]${RESET}  🥚  Addons / Eggs Manager"
    echo -e "  ${BLUE}[14]${RESET}  🔐  SSL Certificate Manager"
    echo -e "  ${BLUE}[15]${RESET}  ☁️   Cloudflare Tunnel Manager"
    echo -e "  ${BLUE}[16]${RESET}  📊  Status & Health Check"
    echo -e "  ${BLUE}[17]${RESET}  💾  Backup & Restore"
    echo -e "  ${WHITE}[18]${RESET}  🔑  Reset Admin Password"
    echo -e "  ${WHITE}[19]${RESET}  📦  Database Manager"
    echo -e "  ${BOLD}${RED}[20]${RESET}  🚨  Emergency 502 / Nginx Fix  ${DIM}← run this if site is down${RESET}"
    echo -e "  ${BOLD}${MAGENTA}[21]${RESET}  🎨  ZynrCloud Themes & Blueprints  ${DIM}← Nebula theme + full pack${RESET}"
    hsep
    echo -e "  ${DIM}[0]   Exit${RESET}"
    hsep
    ask "Enter option:"; read -r CHOICE
    case "$CHOICE" in
        1)  install_panel_menu ;;
        2)  install_wings ;;
        3)  install_combined ;;
        4)  uninstall_panel ;;
        5)  uninstall_wings ;;
        6)  uninstall_everything ;;
        7)  update_panel ;;
        8)  update_wings ;;
        9)  update_panel; update_wings ;;
        10) fix_panel ;;
        11) fix_wings ;;
        12) blueprints_menu ;;
        13) eggs_menu ;;
        14) ssl_menu ;;
        15) cloudflare_menu ;;
        16) status_check ;;
        17) backup_menu ;;
        18) reset_admin_password ;;
        19) database_menu ;;
        20) emergency_502_fix ;;
        21) themes_blueprints_menu ;;
        0)
            echo ""
            echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════╗${RESET}"
            echo -e "${BOLD}${CYAN}  ║  ★  Thank you for using ZynrCloud!  ★               ║${RESET}"
            echo -e "${BOLD}${CYAN}  ║     https://zynrcloud.com  •  Stay powerful.         ║${RESET}"
            echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════╝${RESET}"
            echo ""; exit 0 ;;
        *) warn "Invalid option. Press Enter to retry..."; read -r; main_menu ;;
    esac
}

# ═══════════════════════════════════════════════════════════════
#   COLLECT PANEL INPUTS
# ═══════════════════════════════════════════════════════════════
_collect_panel_inputs() {
    echo ""
    ask "Panel domain/FQDN (e.g. panel.zynrcloud.com):"; read -r P_DOMAIN
    ask "Your email (admin + Let's Encrypt):";           read -r P_EMAIL
    ask "Admin username:";                               read -r P_ADMIN_USER
    ask "Admin password:";                               read -r -s P_ADMIN_PASS; echo ""
    ask "Admin email:";                                  read -r P_ADMIN_EMAIL
    ask "MariaDB root password (will be set now):";      read -r -s P_DB_PASS;    echo ""
}

# ═══════════════════════════════════════════════════════════════
#   SHARED PANEL INSTALL  (ssl | cf | nossl)
# ═══════════════════════════════════════════════════════════════
_do_install_panel() {
    local PANEL_DOMAIN="$1" PANEL_EMAIL="$2" ADMIN_USER="$3"
    local ADMIN_PASS="$4"   ADMIN_EMAIL="$5" DB_ROOT_PASS="$6"
    local USE_CF="$7"
    local USE_FILE_CACHE=false

    # 1 ── System update (SYNCHRONOUS — must finish before any install)
    step "System Update"
    info "Running apt-get update..."
    DEBIAN_FRONTEND=noninteractive apt-get update -y &>/dev/null
    ok "Package lists updated"

    # 2 ── PHP 8.2 repo (before any PHP package install)
    _add_php_repo || {
        err "Failed to add PHP repo. Cannot continue."
        return 1
    }

    # 3 ── Kill any stale MariaDB/MySQL that would block install
    step "Pre-install Cleanup"
    systemctl stop mariadb mysql 2>/dev/null || true
    pkill -9 mysqld mariadbd mysqld_safe 2>/dev/null || true
    kill -9 $(lsof -t -i:3306 2>/dev/null) 2>/dev/null || true
    # If a broken/partial mariadb install exists, force-remove it
    if dpkg -l mariadb-server 2>/dev/null | grep -qE '^(iF|iU|rH|rc)'; then
        info "Removing broken MariaDB install..."
        DEBIAN_FRONTEND=noninteractive dpkg --remove --force-remove-reinstreq             mariadb-server mariadb-server-core mariadb-client mariadb-client-core             mariadb-common mysql-common 2>/dev/null || true
        DEBIAN_FRONTEND=noninteractive apt-get purge -y mariadb-server mariadb-server-core             mariadb-client mariadb-common mysql-common 2>/dev/null || true
        rm -rf /etc/mysql /var/lib/mysql /var/run/mysqld /var/log/mysql
        apt-get autoremove -y &>/dev/null
    fi
    # If a broken/partial PHP 8.2 install exists, purge and wipe it
    if dpkg -l php8.2-common 2>/dev/null | grep -qE '^(iF|iU|rH|rc)'; then
        info "Removing broken PHP 8.2 install..."
        DEBIAN_FRONTEND=noninteractive apt-get purge -y "php8.2*" 2>/dev/null || true
        rm -rf /etc/php/8.2 /usr/lib/php/20220829
    fi
    # Pre-create PHP dirs so post-install scripts never fail on missing paths
    mkdir -p /etc/php/8.2/mods-available /etc/php/8.2/cli/conf.d /etc/php/8.2/fpm/conf.d
    # Fix any other broken dpkg state before installing
    dpkg --configure -a 2>/dev/null || true
    apt-get install -f -y &>/dev/null || true
    ok "Pre-install cleanup done"

    # 3 ── Core packages
    step "Core Dependencies"
    info "Installing PHP 8.2 + MariaDB + Redis..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl tar unzip git wget gnupg2 ca-certificates \
        lsb-release apt-transport-https \
        php8.2 php8.2-cli php8.2-gd php8.2-mysql php8.2-pdo \
        php8.2-mbstring php8.2-tokenizer php8.2-bcmath php8.2-xml \
        php8.2-fpm php8.2-curl php8.2-zip \
        mariadb-server redis-server
    local PKG_EXIT=$?
    if [ $PKG_EXIT -ne 0 ]; then
        # Last resort: fix broken state and retry once
        warn "First install attempt failed — fixing dpkg state and retrying..."
        dpkg --configure -a 2>/dev/null || true
        apt-get install -f -y &>/dev/null || true
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            php8.2 php8.2-cli php8.2-gd php8.2-mysql php8.2-pdo \
            php8.2-mbstring php8.2-tokenizer php8.2-bcmath php8.2-xml \
            php8.2-fpm php8.2-curl php8.2-zip \
            mariadb-server redis-server
        PKG_EXIT=$?
    fi
    if [ $PKG_EXIT -ne 0 ]; then
        err "Package installation failed (exit ${PKG_EXIT})"
        err "Check your internet connection and try again"
        return 1
    fi

    # Verify PHP 8.2 is actually installed and working
    if ! php8.2 --version &>/dev/null; then
        err "php8.2 binary not found after install — something went wrong"
        err "Try manually: apt-get install -y php8.2 php8.2-fpm"
        return 1
    fi
    ok "PHP 8.2 installed: $(php8.2 --version 2>/dev/null | head -1)"
    ok "MariaDB + Redis installed"

    # 4 ── Start Redis NOW (artisan commands need it)
    step "Redis"
    _fix_redis
    if systemctl is-active --quiet redis-server; then
        ok "Redis running"
    else
        warn "Redis failed — Panel will use file-based cache instead"
        USE_FILE_CACHE=true
    fi

    # 5 ── Nginx (always install — CF mode restricts it to localhost)
    step "Nginx"
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        nginx certbot python3-certbot-nginx &>/dev/null
    ok "Nginx + Certbot installed"
    rm -f /etc/nginx/sites-enabled/default

    # 6 ── PHP-FPM
    systemctl enable php8.2-fpm &>/dev/null
    systemctl restart php8.2-fpm &>/dev/null
    sleep 3
    if [ -S "/run/php/php8.2-fpm.sock" ]; then
        ok "PHP 8.2-FPM running — socket ready"
    else
        err "PHP 8.2-FPM socket not found after start!"
        err "Logs: journalctl -u php8.2-fpm -n 20"
        journalctl -u php8.2-fpm --no-pager -n 10 --no-hostname 2>/dev/null
        return 1
    fi

    # 7 ── Composer
    step "Composer"
    if ! command -v composer &>/dev/null; then
        curl -sS https://getcomposer.org/installer \
            | php -- --install-dir=/usr/local/bin --filename=composer &>/dev/null
    fi
    ok "Composer: $(composer --version 2>/dev/null | head -1)"

    # 8 ── Panel files
    step "Panel Files"
    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl || { err "cd failed"; return 1; }
    info "Downloading latest Panel release..."
    curl -fsSL -o panel.tar.gz \
        https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzf panel.tar.gz &>/dev/null
    rm -f panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/ 2>/dev/null
    ok "Panel files extracted"

    # 9 ── MariaDB
    step "MariaDB Database"
    systemctl enable --now mariadb &>/dev/null
    sleep 2
    mysql -u root 2>/dev/null <<SQLEOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
CREATE DATABASE IF NOT EXISTS panel;
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_ROOT_PASS}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
FLUSH PRIVILEGES;
SQLEOF
    ok "Database 'panel' + user 'pterodactyl' created"

    # 10 ── Composer install
    step "Composer Dependencies"
    cp .env.example .env
    info "Running composer install (may take ~60s)..."
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader 2>/dev/null
    ok "Composer install complete"

    # 11 ── App key
    php artisan key:generate --force &>/dev/null
    ok "Application key generated"

    # 12 ── Env setup
    step "Panel Environment"
    local PANEL_URL CACHE_DRV SESSION_DRV QUEUE_DRV
    PANEL_URL="https://${PANEL_DOMAIN}"
    [[ "$USE_CF" == "nossl" ]] && PANEL_URL="http://${PANEL_DOMAIN}"

    if [[ "$USE_FILE_CACHE" == "true" ]]; then
        CACHE_DRV="file"; SESSION_DRV="file"; QUEUE_DRV="sync"
        warn "Using file cache (Redis unavailable)"
    else
        CACHE_DRV="redis"; SESSION_DRV="redis"; QUEUE_DRV="redis"
    fi

    php artisan p:environment:setup \
        --author="$PANEL_EMAIL" \
        --url="$PANEL_URL" \
        --timezone="UTC" \
        --cache="$CACHE_DRV" \
        --session="$SESSION_DRV" \
        --queue="$QUEUE_DRV" \
        --redis-host=127.0.0.1 \
        --redis-pass=null \
        --redis-port=6379 \
        --no-interaction &>/dev/null

    php artisan p:environment:database \
        --host=127.0.0.1 --port=3306 \
        --database=panel --username=pterodactyl \
        --password="$DB_ROOT_PASS" \
        --no-interaction &>/dev/null
    ok "Environment set — URL: ${PANEL_URL} | Cache: ${CACHE_DRV}"

    # 13 ── Migrations
    step "Database Migrations"
    info "Running migrations + seed (~30s)..."

    # Verify PHP version meets Pterodactyl's requirement (>= 8.2)
    local PHP_INSTALLED_VER
    PHP_INSTALLED_VER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null)
    if [[ "$PHP_INSTALLED_VER" < "8.2" ]]; then
        err "PHP version too old: ${PHP_INSTALLED_VER} — Pterodactyl requires >= 8.2"
        err "The 'php' command is pointing to the wrong version."
        info "Switching default PHP to 8.2..."
        update-alternatives --set php /usr/bin/php8.2 &>/dev/null || true
        update-alternatives --set php-config /usr/bin/php-config8.2 &>/dev/null || true
        PHP_INSTALLED_VER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null)
        ok "PHP CLI now: $(php --version 2>/dev/null | head -1)"
    fi

    php artisan migrate --seed --force
    if [ $? -ne 0 ]; then
        err "Migrations failed — check output above"
        err "Common causes: wrong DB password, DB not running, PHP version mismatch"
    else
        ok "Migrations + seed complete"
    fi

    # 14 ── Admin user
    step "Admin User"
    php artisan p:user:make \
        --email="$ADMIN_EMAIL" --username="$ADMIN_USER" \
        --name-first="ZynrCloud" --name-last="Admin" \
        --password="$ADMIN_PASS" --admin=1 &>/dev/null
    ok "Admin '${ADMIN_USER}' created"

    # 15 ── Permissions + cron
    step "Permissions + Cron"
    chown -R www-data:www-data /var/www/pterodactyl
    crontab -l 2>/dev/null | grep -v 'pterodactyl' | crontab -
    (crontab -l 2>/dev/null; echo "* * * * * /usr/bin/php8.2 /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
    ok "Permissions set + cron registered"

    # 16 ── Queue worker
    step "Queue Worker (pteroq)"
    cat > /etc/systemd/system/pteroq.service << 'PTEROQEOF'
# ZynrCloud — Pterodactyl Queue Worker
[Unit]
Description=Pterodactyl Queue Worker (ZynrCloud)
After=redis-server.service mariadb.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php8.2 /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
PTEROQEOF
    systemctl daemon-reload
    systemctl enable --now pteroq &>/dev/null
    ok "pteroq enabled + started"

    # 17 ── Nginx vhost
    case "$USE_CF" in
        ssl)    _setup_nginx_ssl    "$PANEL_DOMAIN" "$PANEL_EMAIL" ;;
        nossl)  _setup_nginx_nossl  "$PANEL_DOMAIN" ;;
        cf)     _setup_nginx_cf     "$PANEL_DOMAIN" ;;
    esac
}

# ── Nginx vhosts ─────────────────────────────────────────────

_nginx_php_block() {
    cat << 'PHPEOF'
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size = 100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }
    location ~ /\.ht { deny all; }
PHPEOF
}

_write_nginx_http_vhost() {
    local DOMAIN="$1" LISTEN="$2"   # LISTEN = "80" or "127.0.0.1:80"
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    cat > /etc/nginx/sites-available/pterodactyl.conf << NGINXEOF
# ZynrCloud — Pterodactyl Panel
server {
    listen ${LISTEN};
    server_name ${DOMAIN};
    root /var/www/pterodactyl/public;
    index index.php;
    access_log /var/log/nginx/pterodactyl.access.log;
    error_log  /var/log/nginx/pterodactyl.error.log error;
    client_max_body_size 100m;
    client_body_timeout  120s;
    sendfile off;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size = 100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }
    location ~ /\.ht { deny all; }
}
NGINXEOF
    ln -sf /etc/nginx/sites-available/pterodactyl.conf \
           /etc/nginx/sites-enabled/pterodactyl.conf
}

_setup_nginx_ssl() {
    local DOMAIN="$1" EMAIL="$2"
    step "Nginx + Let's Encrypt SSL"
    _write_nginx_http_vhost "$DOMAIN" "80"
    systemctl enable --now nginx &>/dev/null
    nginx -t &>/dev/null && systemctl reload nginx
    info "Requesting Let's Encrypt cert for ${DOMAIN}..."
    certbot --nginx -d "$DOMAIN" --email "$EMAIL" \
        --agree-tos --no-eff-email --redirect -n 2>&1 | tail -6
    nginx -t &>/dev/null && systemctl reload nginx \
        && ok "Nginx + SSL configured for ${DOMAIN}" \
        || err "Nginx config error after certbot — run: nginx -t"
}

_setup_nginx_nossl() {
    local DOMAIN="$1"
    step "Nginx (HTTP only)"
    _write_nginx_http_vhost "$DOMAIN" "80"
    systemctl enable --now nginx &>/dev/null
    nginx -t &>/dev/null && systemctl reload nginx \
        && ok "Nginx (HTTP) configured for ${DOMAIN}" \
        || err "Nginx config error — run: nginx -t"
    warn "SSL not enabled. Add a cert later via option [14]."
}

_setup_nginx_cf() {
    local DOMAIN="$1"
    step "Nginx (Cloudflare Tunnel mode)"

    # Remove ALL default/conflicting nginx configs first
    rm -f /etc/nginx/sites-enabled/default
    rm -f /etc/nginx/sites-available/default
    # Remove any stale pterodactyl config
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf

    # CF tunnel: cloudflared connects to localhost:80, nginx must listen on 0.0.0.0:80
    # but ONLY serve the panel — no need for SSL since CF handles TLS
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    cat > /etc/nginx/sites-available/pterodactyl.conf << CFNGINX
# ZynrCloud — Pterodactyl Panel (Cloudflare Tunnel Mode)
# CF handles HTTPS — nginx serves plain HTTP to cloudflared on localhost
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.access.log;
    error_log  /var/log/nginx/pterodactyl.error.log error;

    client_max_body_size 100m;
    client_body_timeout  120s;
    sendfile off;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size = 100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }
    location ~ /\.ht { deny all; }
}
CFNGINX

    ln -sf /etc/nginx/sites-available/pterodactyl.conf \
           /etc/nginx/sites-enabled/pterodactyl.conf

    # Verify config before reloading
    if nginx -t 2>/dev/null; then
        systemctl enable nginx &>/dev/null
        systemctl restart nginx
        ok "Nginx configured for Cloudflare Tunnel (HTTP on port 80)"
    else
        err "Nginx config test failed — details:"
        nginx -t
    fi
}

# ── CF post-install: TOKEN method (the correct Cloudflare way) ──
_post_cf_setup() {
    local DOMAIN="$1"
    step "Cloudflare Tunnel — Token Setup"
    _install_cloudflared

    echo ""
    echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║  HOW TO GET YOUR TUNNEL TOKEN (takes ~2 minutes)             ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╠══════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${WHITE}  ║  1. Go to: https://one.dash.cloudflare.com                   ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  2. Click  Networks → Tunnels → Create a Tunnel              ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  3. Choose  Cloudflared  connector type                      ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  4. Give it a name (e.g. zynrcloud-panel)                    ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  5. Copy the token from the install command shown             ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║     It looks like:  eyJhIjoiOWU1OTA5...  (long string)        ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  6. In Public Hostname tab add:                               ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║     Subdomain: ${DOMAIN%%.*}  Domain: ${DOMAIN#*.}              ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║     Type: HTTP   URL: localhost:80                            ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    warn "Make sure 'This hostname is not covered by a certificate' warning is resolved"
    warn "in Cloudflare → SSL/TLS → set mode to Full or Full (Strict)"
    echo ""

    ask "Paste your Cloudflare Tunnel token here:"; read -r CF_TOKEN

    if [ -z "$CF_TOKEN" ]; then
        warn "No token entered. You can run option [15] → Install with Token later."
        info "Manual command: cloudflared service install <YOUR_TOKEN>"
        return
    fi

    info "Installing cloudflared service with token..."
    # This is the CORRECT method — single command, no browser login needed
    cloudflared service install "$CF_TOKEN"

    if [ $? -eq 0 ]; then
        systemctl enable --now cloudflared &>/dev/null
        sleep 2
        if systemctl is-active --quiet cloudflared; then
            ok "Cloudflared tunnel service running!"
            ok "Panel should be accessible at: https://${DOMAIN}"
            info "Check tunnel status at: https://one.dash.cloudflare.com"
        else
            warn "Service installed but not active. Checking logs..."
            journalctl -u cloudflared --no-pager -n 10 --no-hostname 2>/dev/null
        fi
    else
        err "Token install failed. Check your token and try again."
        info "Manual command: cloudflared service install <YOUR_TOKEN>"
    fi
}

# ── Summary box ──────────────────────────────────────────────
_print_panel_summary() {
    local DOMAIN="$1" USER="$2" MODE="$3"
    local SCHEME="https"; [[ "$MODE" == "3" ]] && SCHEME="http"
    echo ""
    echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║           🎉  PANEL INSTALL SUMMARY  🎉              ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${CYAN}  ║  🌐  Panel URL  : ${SCHEME}://${DOMAIN}${RESET}"
    echo -e "${BOLD}${CYAN}  ║  👤  Admin User : ${USER}${RESET}"
    [[ "$MODE" == "1" ]] && echo -e "${BOLD}${CYAN}  ║  🔒  Mode       : Nginx + Let's Encrypt SSL${RESET}"
    [[ "$MODE" == "2" ]] && echo -e "${BOLD}${CYAN}  ║  ☁️   Mode       : Cloudflare Tunnel${RESET}"
    [[ "$MODE" == "3" ]] && echo -e "${BOLD}${CYAN}  ║  🌐  Mode       : HTTP Only (no SSL)${RESET}"
    echo -e "${BOLD}${CYAN}  ║  ★   Powered by : ZynrCloud — https://zynrcloud.com  ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════╝${RESET}"
}

# ═══════════════════════════════════════════════════════════════
#  [1]  INSTALL PANEL MENU
# ═══════════════════════════════════════════════════════════════
install_panel_menu() {
    show_banner
    echo -e "${BOLD}${GREEN}  🚀 INSTALL PTERODACTYL PANEL${RESET}"
    sep; require_root; detect_os

    echo -e "\n  ${WHITE}Choose your SSL / connection method:${RESET}\n"
    echo -e "  ${GREEN}[1]${RESET}  🔒  Standard  (Nginx + Let's Encrypt SSL)"
    echo -e "         ${DIM}→ Public domain, DNS pointing to this server's IP${RESET}"
    echo ""
    echo -e "  ${GREEN}[2]${RESET}  ☁️   Cloudflare Tunnel  (No open ports, HTTPS via Cloudflare)"
    echo -e "         ${DIM}→ No firewall rules needed. Cloudflare handles TLS end-to-end.${RESET}"
    echo ""
    echo -e "  ${GREEN}[3]${RESET}  🌐  HTTP Only  (No SSL — dev / internal)"
    echo -e "         ${DIM}→ Not for production.${RESET}"
    sep
    ask "Choose [1/2/3]:"; read -r PANEL_MODE_CHOICE

    _collect_panel_inputs

    local INSTALL_RC=0
    case "$PANEL_MODE_CHOICE" in
        1) _do_install_panel "$P_DOMAIN" "$P_EMAIL" "$P_ADMIN_USER" "$P_ADMIN_PASS" "$P_ADMIN_EMAIL" "$P_DB_PASS" "ssl"
           INSTALL_RC=$? ;;
        2) _do_install_panel "$P_DOMAIN" "$P_EMAIL" "$P_ADMIN_USER" "$P_ADMIN_PASS" "$P_ADMIN_EMAIL" "$P_DB_PASS" "cf"
           INSTALL_RC=$?
           [ $INSTALL_RC -eq 0 ] && _post_cf_setup "$P_DOMAIN" ;;
        3) _do_install_panel "$P_DOMAIN" "$P_EMAIL" "$P_ADMIN_USER" "$P_ADMIN_PASS" "$P_ADMIN_EMAIL" "$P_DB_PASS" "nossl"
           INSTALL_RC=$? ;;
        *) warn "Invalid — defaulting to SSL"
           PANEL_MODE_CHOICE=1
           _do_install_panel "$P_DOMAIN" "$P_EMAIL" "$P_ADMIN_USER" "$P_ADMIN_PASS" "$P_ADMIN_EMAIL" "$P_DB_PASS" "ssl"
           INSTALL_RC=$? ;;
    esac

    sep
    if [ $INSTALL_RC -eq 0 ]; then
        ok "Panel installation complete!"
        _print_panel_summary "$P_DOMAIN" "$P_ADMIN_USER" "$PANEL_MODE_CHOICE"
    else
        err "Panel installation FAILED (exit code ${INSTALL_RC})"
        err "Scroll up to see the exact error."
        echo ""
        echo -e "  ${WHITE}Common fixes:${RESET}"
        echo -e "  ${CYAN}→ Run option [20] Emergency Recovery to install missing packages${RESET}"
        echo -e "  ${CYAN}→ Run option [10] → [9] to fix DB credentials${RESET}"
        echo -e "  ${CYAN}→ Run option [6] Uninstall Everything then reinstall fresh${RESET}"
    fi
    pause
}

# ═══════════════════════════════════════════════════════════════
#   SHARED WINGS INSTALL
# ═══════════════════════════════════════════════════════════════
_do_install_wings() {
    step "Docker"
    if ! command -v docker &>/dev/null; then
        info "Installing Docker..."
        curl -fsSL https://get.docker.com | bash &>/dev/null
        ok "Docker installed"
    else
        ok "Docker already present"
    fi
    systemctl enable --now docker &>/dev/null

    step "Wings Binary"
    local ARCH
    ARCH=$(dpkg --print-architecture 2>/dev/null \
        || uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
    mkdir -p /etc/pterodactyl
    info "Downloading Wings (${ARCH})..."
    curl -fsSL -o /usr/local/bin/wings \
        "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_${ARCH}"
    chmod u+x /usr/local/bin/wings
    ok "Wings: $(/usr/local/bin/wings --version 2>/dev/null || echo 'installed')"

    step "Wings Systemd Service"
    cat > /etc/systemd/system/wings.service << 'WINGSEOF'
# ZynrCloud — Pterodactyl Wings Daemon
[Unit]
Description=Pterodactyl Wings Daemon (ZynrCloud)
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
WINGSEOF
    systemctl daemon-reload
    systemctl enable wings &>/dev/null
    ok "Wings service registered (start after 'wings configure ...')"
}

# ═══════════════════════════════════════════════════════════════
#  [2]  INSTALL WINGS ONLY
# ═══════════════════════════════════════════════════════════════
install_wings() {
    show_banner
    echo -e "${BOLD}${GREEN}  🔧 INSTALL PTERODACTYL WINGS${RESET}"
    sep; require_root; detect_os
    _do_install_wings
    local WINGS_IP; WINGS_IP=$(hostname -I | awk '{print $1}')
    sep; ok "Wings installation complete!"
    echo ""
    echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║           🎉  WINGS INSTALL SUMMARY  🎉              ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${CYAN}  ║  🖥️  Node IP : ${WINGS_IP}${RESET}"
    echo -e "${BOLD}${CYAN}  ╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${WHITE}  ║  NEXT STEPS:                                         ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  1. Panel → Admin → Nodes → Create Node              ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  2. 'Configuration' tab → copy auto-deploy token     ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  3. On this server run:                              ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║     wings configure \\                               ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║       --panel-url=https://your.panel \\              ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║       --token=<TOKEN> --node=<ID>                   ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  4. systemctl start wings                            ║${RESET}"
    echo -e "${BOLD}${CYAN}  ║  ★  ZynrCloud — https://zynrcloud.com                ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════╝${RESET}"
    pause
}

# ═══════════════════════════════════════════════════════════════
#  [3]  COMBINED PANEL + WINGS
# ═══════════════════════════════════════════════════════════════
install_combined() {
    show_banner
    echo -e "${BOLD}${GREEN}  💎 INSTALL PANEL + WINGS — COMBINED (Same Server)${RESET}"
    sep; require_root; detect_os

    warn "Panel + Wings on the same machine. Fine for personal/small setups."
    echo ""
    echo -e "  ${WHITE}Panel SSL / connection method:${RESET}"
    echo -e "  ${GREEN}[1]${RESET}  🔒  Standard (Nginx + Let's Encrypt SSL)"
    echo -e "  ${GREEN}[2]${RESET}  ☁️   Cloudflare Tunnel"
    echo -e "  ${GREEN}[3]${RESET}  🌐  HTTP Only"
    sep
    ask "Choose [1/2/3]:"; read -r COMBO_MODE

    _collect_panel_inputs

    local COMBO_RC=0
    echo ""; info "════ PHASE 1 / 2 — Installing Panel ════"
    case "$COMBO_MODE" in
        1) _do_install_panel "$P_DOMAIN" "$P_EMAIL" "$P_ADMIN_USER" "$P_ADMIN_PASS" "$P_ADMIN_EMAIL" "$P_DB_PASS" "ssl"
           COMBO_RC=$? ;;
        2) _do_install_panel "$P_DOMAIN" "$P_EMAIL" "$P_ADMIN_USER" "$P_ADMIN_PASS" "$P_ADMIN_EMAIL" "$P_DB_PASS" "cf"
           COMBO_RC=$?; [ $COMBO_RC -eq 0 ] && _post_cf_setup "$P_DOMAIN" ;;
        3) _do_install_panel "$P_DOMAIN" "$P_EMAIL" "$P_ADMIN_USER" "$P_ADMIN_PASS" "$P_ADMIN_EMAIL" "$P_DB_PASS" "nossl"
           COMBO_RC=$? ;;
        *) COMBO_MODE=1
           _do_install_panel "$P_DOMAIN" "$P_EMAIL" "$P_ADMIN_USER" "$P_ADMIN_PASS" "$P_ADMIN_EMAIL" "$P_DB_PASS" "ssl"
           COMBO_RC=$? ;;
    esac

    if [ $COMBO_RC -ne 0 ]; then
        err "Panel install FAILED — skipping Wings install"
        err "Fix the panel first, then install Wings separately via option [2]"
        pause; return
    fi

    echo ""; info "════ PHASE 2 / 2 — Installing Wings ════"
    _do_install_wings

    sep; ok "Combined install complete!"
    _print_panel_summary "$P_DOMAIN" "$P_ADMIN_USER" "$COMBO_MODE"
    echo -e "\n  ${WHITE}Wings IP: $(hostname -I | awk '{print $1}')${RESET}"
    echo -e "  ${WHITE}→ Create a Node in Panel, then run 'wings configure ...' to link.${RESET}"
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"
    pause
}

# ═══════════════════════════════════════════════════════════════
#  [4]  UNINSTALL PANEL
# ═══════════════════════════════════════════════════════════════
uninstall_panel() {
    show_banner; echo -e "${BOLD}${RED}  🗑️  UNINSTALL PANEL${RESET}"; sep; require_root
    warn "Permanently removes Panel files, database, Nginx config, queue service, and cron."
    ask "Type CONFIRM to proceed:"; read -r C
    [[ "$C" != "CONFIRM" ]] && { info "Aborted."; pause; return; }

    info "Stopping services..."
    systemctl stop pteroq 2>/dev/null
    systemctl stop nginx 2>/dev/null
    systemctl stop php8.2-fpm 2>/dev/null
    systemctl disable pteroq 2>/dev/null
    ok "Services stopped"

    info "Removing Panel files..."
    rm -rf /var/www/pterodactyl
    ok "Panel files removed"

    info "Dropping database..."
    mysql -u root -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null
    mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';" 2>/dev/null
    mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null
    ok "Database dropped"

    info "Removing Nginx config..."
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    if nginx_available; then
        nginx -t &>/dev/null && systemctl reload nginx 2>/dev/null || true
    fi
    ok "Nginx config removed"

    info "Removing systemd service..."
    rm -f /etc/systemd/system/pteroq.service
    systemctl daemon-reload
    ok "pteroq service removed"

    info "Removing cron job..."
    crontab -l 2>/dev/null | grep -v 'pterodactyl' | crontab - 2>/dev/null
    ok "Cron job removed"

    sep
    ok "Panel fully uninstalled!"
    echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"
    pause
}

# ═══════════════════════════════════════════════════════════════
#  [5]  UNINSTALL WINGS
# ═══════════════════════════════════════════════════════════════
uninstall_wings() {
    show_banner; echo -e "${BOLD}${RED}  🗑️  UNINSTALL WINGS${RESET}"; sep; require_root
    warn "Permanently removes Wings binary, config, service."
    ask "Type CONFIRM:"; read -r C; [[ "$C" != "CONFIRM" ]] && { info "Aborted."; pause; return; }
    systemctl stop wings 2>/dev/null; systemctl disable wings 2>/dev/null
    rm -f /usr/local/bin/wings; rm -rf /etc/pterodactyl
    rm -f /etc/systemd/system/wings.service; systemctl daemon-reload
    ok "Wings removed"
    ask "Also remove Docker? [y/n]:"; read -r RD
    [[ "$RD" =~ ^[Yy]$ ]] && {
        apt-get purge -y docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin &>/dev/null
        ok "Docker removed"
    }
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#  [6]  UNINSTALL EVERYTHING
#  Removes: Panel, Wings, Docker, MariaDB, Redis, Nginx, PHP,
#  Composer, Node.js, Yarn, NPM, Certbot, Cloudflared,
#  Blueprint Framework, all configs, all data, all services
# ═══════════════════════════════════════════════════════════════
uninstall_everything() {
    show_banner
    echo -e "${BOLD}${RED}  💣 UNINSTALL EVERYTHING — FULL WIPE${RESET}"
    sep
    require_root

    echo ""
    echo -e "  ${RED}${BOLD}This will PERMANENTLY destroy:${RESET}"
    echo -e "  ${RED}  ✘  Pterodactyl Panel + all panel data${RESET}"
    echo -e "  ${RED}  ✘  Pterodactyl Wings + all server files${RESET}"
    echo -e "  ${RED}  ✘  MariaDB + ALL databases${RESET}"
    echo -e "  ${RED}  ✘  Docker + all containers and images${RESET}"
    echo -e "  ${RED}  ✘  Redis, Nginx, PHP 8.2, Certbot${RESET}"
    echo -e "  ${RED}  ✘  Node.js, NPM, Yarn${RESET}"
    echo -e "  ${RED}  ✘  Composer${RESET}"
    echo -e "  ${RED}  ✘  Blueprint Framework + all extensions${RESET}"
    echo -e "  ${RED}  ✘  Cloudflared + tunnel config${RESET}"
    echo -e "  ${RED}  ✘  All SSL certificates${RESET}"
    echo -e "  ${RED}  ✘  All cron jobs and systemd services${RESET}"
    echo ""
    warn "There is NO undo. The server will be as clean as a fresh install."
    echo ""
    ask "Type  DELETE-EVERYTHING  to confirm:"; read -r C
    [[ "$C" != "DELETE-EVERYTHING" ]] && { info "Aborted."; pause; return; }

    echo ""
    warn "Starting full wipe in 3 seconds... Ctrl+C to cancel"
    sleep 3

    # ═══════════════════════════════════════════════════════════
    step "[ 1/12 ] Stopping All Services"
    # ═══════════════════════════════════════════════════════════
    for svc in pteroq wings nginx php8.2-fpm php8.1-fpm php8.0-fpm \
               mariadb mysql redis-server redis docker cloudflared; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            systemctl stop "$svc" 2>/dev/null
            info "Stopped: $svc"
        fi
        systemctl disable "$svc" 2>/dev/null || true
    done
    ok "All services stopped"

    # ═══════════════════════════════════════════════════════════
    step "[ 2/12 ] Removing Pterodactyl Panel"
    # ═══════════════════════════════════════════════════════════
    # Panel files
    rm -rf /var/www/pterodactyl
    ok "Panel files removed"

    # Panel service
    rm -f /etc/systemd/system/pteroq.service
    ok "pteroq service removed"

    # Panel cron
    crontab -l 2>/dev/null | grep -v 'pterodactyl' | crontab - 2>/dev/null
    ok "Cron job removed"

    # Nginx vhost
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    ok "Nginx vhost removed"

    # ═══════════════════════════════════════════════════════════
    step "[ 3/12 ] Removing Pterodactyl Wings"
    # ═══════════════════════════════════════════════════════════
    rm -f /usr/local/bin/wings
    rm -rf /etc/pterodactyl
    rm -f /etc/systemd/system/wings.service
    ok "Wings removed"

    # ═══════════════════════════════════════════════════════════
    step "[ 4/12 ] Removing MariaDB / MySQL + ALL Databases"
    # ═══════════════════════════════════════════════════════════
    # Drop the panel DB/user first (best effort)
    mysql -u root -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || true
    mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';" 2>/dev/null || true
    mysql -u root -e "FLUSH PRIVILEGES;" 2>/dev/null || true

    # ── Internal helper: run apt purge silently, only show real errors ──
    _apt_purge() {
        DEBIAN_FRONTEND=noninteractive apt-get purge -y "$@" 2>&1 \
            | grep -vE \
                "^(Reading|Building|Note, selecting|Package '.*' is not installed|0 upgraded|The following|Use 'apt|E: Unable to locate|E: Couldn't find)" \
            | grep -vE "^\s*$" \
            | head -5 || true
    }

    # Purge MariaDB and MySQL completely
    _apt_purge mariadb-server mariadb-client mariadb-common \
               mysql-server mysql-client mysql-common \
               'mariadb-*' 'mysql-*'

    # Force-remove ALL MariaDB/MySQL data, configs, logs
    # (dpkg warns if not empty but won't delete — we do it manually)
    rm -rf /var/lib/mysql
    rm -rf /var/lib/mariadb
    rm -rf /etc/mysql          # force delete even if dpkg left it
    rm -rf /etc/mariadb.conf.d
    rm -rf /var/log/mysql
    rm -rf /var/log/mariadb
    rm -f  /root/.my.cnf
    # Clean up any socket files dpkg leaves behind
    rm -f /var/run/mysqld/mysqld.sock 2>/dev/null
    rm -rf /var/run/mysqld 2>/dev/null
    ok "MariaDB + all databases completely removed"

    # ═══════════════════════════════════════════════════════════
    step "[ 5/12 ] Removing Docker + All Containers & Images"
    # ═══════════════════════════════════════════════════════════
    if command -v docker &>/dev/null; then
        # Restart docker briefly to allow clean container removal
        systemctl start docker &>/dev/null; sleep 2
        if systemctl is-active --quiet docker 2>/dev/null; then
            local CTRS; CTRS=$(docker ps -aq 2>/dev/null)
            [ -n "$CTRS" ] && { docker stop $CTRS &>/dev/null; docker rm $CTRS &>/dev/null; } || true
            local IMGS; IMGS=$(docker images -q 2>/dev/null)
            [ -n "$IMGS" ] && docker rmi -f $IMGS &>/dev/null || true
            docker volume  prune -f &>/dev/null || true
            docker network prune -f &>/dev/null || true
            systemctl stop docker &>/dev/null
        fi
        ok "Docker containers/images/volumes cleaned"
    fi

    _apt_purge docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin \
        docker-compose docker.io

    rm -rf /var/lib/docker
    rm -rf /etc/docker
    rm -rf /var/run/docker.sock
    rm -rf /usr/local/lib/docker
    rm -f /usr/local/bin/docker-compose
    ok "Docker fully removed"

    # ═══════════════════════════════════════════════════════════
    step "[ 6/12 ] Removing Redis"
    # ═══════════════════════════════════════════════════════════
    _apt_purge redis redis-server redis-tools
    rm -rf /var/lib/redis /etc/redis /var/log/redis
    ok "Redis removed"

    # ═══════════════════════════════════════════════════════════
    step "[ 7/12 ] Removing Nginx + SSL Certificates"
    # ═══════════════════════════════════════════════════════════
    _apt_purge nginx nginx-common nginx-core nginx-full \
        certbot python3-certbot-nginx

    rm -rf /etc/nginx
    rm -rf /var/log/nginx
    rm -rf /var/cache/nginx

    # Remove all Let's Encrypt certificates
    rm -rf /etc/letsencrypt
    rm -rf /var/lib/letsencrypt
    rm -rf /var/log/letsencrypt
    ok "Nginx + all SSL certificates removed"

    # ═══════════════════════════════════════════════════════════
    step "[ 8/12 ] Removing PHP 8.2 + All Extensions"
    # ═══════════════════════════════════════════════════════════
    _apt_purge 'php8.2*' 'php8.1*' 'php8.0*' 'php7.4*' 'php-*' php-common

    rm -rf /etc/php
    rm -rf /var/lib/php
    rm -rf /run/php
    rm -f /usr/bin/php /usr/bin/php8.2 /usr/bin/php8.1

    # Remove Sury/Ondrej PHP repo
    rm -f /etc/apt/sources.list.d/sury-php.list
    rm -f /etc/apt/sources.list.d/ondrej-ubuntu-php-*.list
    rm -f /usr/share/keyrings/sury-php.gpg
    ok "PHP + PHP repo removed"

    # ═══════════════════════════════════════════════════════════
    step "[ 9/12 ] Removing Node.js, NPM, Yarn"
    # ═══════════════════════════════════════════════════════════
    # Remove Yarn via npm FIRST (before nuking node)
    if command -v npm &>/dev/null; then
        npm uninstall -g yarn corepack 2>/dev/null || true
    fi
    # Remove yarn binary directly — do NOT use apt purge yarn
    # (apt's 'yarn' package is actually 'cmdtest' on Ubuntu — wrong package!)
    rm -f /usr/bin/yarn /usr/bin/yarnpkg
    rm -f /usr/local/bin/yarn /usr/local/bin/yarnpkg

    # Now purge Node.js and npm (never purge 'yarn' via apt — it installs cmdtest!)
    _apt_purge nodejs npm

    # Remove NodeSource / Yarn apt repos
    rm -f /etc/apt/sources.list.d/nodesource.list
    rm -f /etc/apt/sources.list.d/node_*.list
    rm -f /usr/share/keyrings/nodesource.gpg
    rm -f /etc/apt/sources.list.d/yarn.list
    rm -f /usr/share/keyrings/yarnkey.gpg

    # Force-remove leftover node_modules directories (dpkg won't do this)
    rm -rf /usr/lib/node_modules
    rm -rf /usr/local/lib/node_modules
    rm -rf /usr/local/share/.cache/yarn
    rm -rf /root/.npm
    rm -rf /root/.yarn
    rm -rf /root/.config/yarn
    rm -rf /root/.cache/yarn
    rm -f  /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx
    ok "Node.js + NPM + Yarn removed"

    # ═══════════════════════════════════════════════════════════
    step "[10/12 ] Removing Composer"
    # ═══════════════════════════════════════════════════════════
    rm -f /usr/local/bin/composer
    rm -rf /root/.composer
    rm -rf /root/.config/composer
    ok "Composer removed"

    # ═══════════════════════════════════════════════════════════
    step "[11/12 ] Removing Blueprint Framework"
    # ═══════════════════════════════════════════════════════════
    rm -f /usr/local/bin/blueprint
    rm -f /usr/bin/blueprint
    # Blueprint files inside panel are already gone with panel files
    # But clean up any stray blueprint tmp files
    rm -rf /tmp/blueprint-framework* 2>/dev/null
    rm -rf /tmp/bp_* 2>/dev/null
    rm -rf /tmp/bpinst_* 2>/dev/null
    ok "Blueprint Framework removed"

    # ═══════════════════════════════════════════════════════════
    step "[12/12 ] Removing Cloudflared + Final Cleanup"
    # ═══════════════════════════════════════════════════════════
    # Cloudflared
    cloudflared service uninstall 2>/dev/null || true
    rm -f /usr/local/bin/cloudflared
    rm -f /etc/systemd/system/cloudflared.service
    rm -rf /root/.cloudflared
    ok "Cloudflared removed"

    # Reload systemd after removing all unit files
    systemctl daemon-reload
    systemctl reset-failed 2>/dev/null || true

    # Run apt autoremove to clean orphaned dependencies
    info "Cleaning up orphaned packages..."
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y 2>/dev/null | tail -3
    DEBIAN_FRONTEND=noninteractive apt-get autoclean -y 2>/dev/null | tail -2

    # Update apt cache to reflect removed repos
    DEBIAN_FRONTEND=noninteractive apt-get update -y &>/dev/null

    ok "System cleanup complete"

    # ── Final summary ───────────────────────────────────────────
    echo ""
    echo -e "${BOLD}${GREEN}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}  ║        ✔  FULL WIPE COMPLETE — Server is clean          ║${RESET}"
    echo -e "${BOLD}${GREEN}  ╠══════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ✔  Pterodactyl Panel      removed                      ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ✔  Pterodactyl Wings      removed                      ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ✔  MariaDB + databases    removed                      ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ✔  Docker + containers    removed                      ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ✔  Redis                  removed                      ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ✔  Nginx + SSL certs      removed                      ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ✔  PHP 8.2 + extensions   removed                      ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ✔  Node.js + Yarn + NPM   removed                      ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ✔  Composer               removed                      ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ✔  Blueprint Framework     removed                      ║${RESET}"
    echo -e "${BOLD}${WHITE}  ║  ✔  Cloudflared            removed                      ║${RESET}"
    echo -e "${BOLD}${GREEN}  ╠══════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${CYAN}  ║  Server is clean. Run option [1] for a fresh install.   ║${RESET}"
    echo -e "${BOLD}${CYAN}  ║  ★  ZynrCloud — https://zynrcloud.com                   ║${RESET}"
    echo -e "${BOLD}${GREEN}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    pause
}

# ═══════════════════════════════════════════════════════════════
#  [7]  UPDATE PANEL
# ═══════════════════════════════════════════════════════════════
update_panel() {
    show_banner; echo -e "${BOLD}${YELLOW}  🔄 UPDATE PANEL${RESET}"; sep; require_root
    [ ! -d /var/www/pterodactyl ] && { err "Panel not found"; pause; return; }
    cp /var/www/pterodactyl/.env \
        "/var/www/pterodactyl/.env.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null
    ok ".env backed up"
    cd /var/www/pterodactyl || exit
    php artisan down &>/dev/null
    info "Downloading latest Panel..."; curl -fsSL -o panel.tar.gz \
        https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzf panel.tar.gz &>/dev/null; rm -f panel.tar.gz; ok "Files updated"
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader &>/dev/null & spinner "Composer install"
    php artisan migrate --force &>/dev/null && ok "Migrations done"
    php artisan view:clear &>/dev/null; php artisan config:clear &>/dev/null; php artisan route:clear &>/dev/null
    ok "Caches cleared"
    chown -R www-data:www-data /var/www/pterodactyl
    php artisan up &>/dev/null; systemctl restart pteroq
    sep; ok "Panel updated!"; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#  [8]  UPDATE WINGS
# ═══════════════════════════════════════════════════════════════
update_wings() {
    show_banner; echo -e "${BOLD}${YELLOW}  🔄 UPDATE WINGS${RESET}"; sep; require_root
    ! command -v wings &>/dev/null && { err "Wings not found"; pause; return; }
    local OV; OV=$(wings --version 2>/dev/null || echo "unknown")
    info "Current: ${OV}"; systemctl stop wings 2>/dev/null
    local ARCH; ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
    info "Downloading Wings (${ARCH})..."
    curl -fsSL -o /usr/local/bin/wings \
        "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_${ARCH}"
    chmod u+x /usr/local/bin/wings
    systemctl start wings 2>/dev/null
    ok "Wings updated: ${OV} → $(/usr/local/bin/wings --version 2>/dev/null || echo 'latest')"
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#  [10]  FIX / REPAIR PANEL
# ═══════════════════════════════════════════════════════════════
fix_panel() {
    show_banner; echo -e "${BOLD}${CYAN}  🛠️  FIX / REPAIR PANEL${RESET}"; sep; require_root

    echo -e "  ${WHITE}Choose a fix:${RESET}"
    echo -e "  ${GREEN}[1]${RESET} Fix Permissions"
    echo -e "  ${GREEN}[2]${RESET} Restart Queue Worker (pteroq)"
    echo -e "  ${GREEN}[3]${RESET} Fix / Reload Nginx  (auto-installs if missing)"
    echo -e "  ${GREEN}[4]${RESET} Clear all caches  (auto-fixes Redis first)"
    echo -e "  ${GREEN}[5]${RESET} Re-run Migrations"
    echo -e "  ${GREEN}[6]${RESET} Rebuild Composer autoload"
    echo -e "  ${GREEN}[7]${RESET} Fix Redis  (start or switch to file cache)"
    echo -e "  ${GREEN}[8]${RESET} Full Auto-Repair  (all of the above)"
    echo -e "  ${YELLOW}[9]${RESET} Fix DB credentials  ${DIM}(fixes 'Access denied' / password: NO errors)${RESET}"
    sep; ask "Choose:"; read -r FIX_OPT

    # ── Internal: read a value from .env ─────────────────────
    _env_get() { grep -E "^${1}=" /var/www/pterodactyl/.env 2>/dev/null \
                     | head -1 | cut -d'=' -f2- | tr -d '"'"'" ; }

    # ── Internal: test DB connection using .env values ────────
    _fp_db_ok() {
        local HOST PORT DB USER PASS
        HOST=$(  _env_get DB_HOST     ); HOST=${HOST:-127.0.0.1}
        PORT=$(  _env_get DB_PORT     ); PORT=${PORT:-3306}
        DB=$(    _env_get DB_DATABASE ); DB=${DB:-panel}
        USER=$(  _env_get DB_USERNAME ); USER=${USER:-pterodactyl}
        PASS=$(  _env_get DB_PASSWORD )
        mysql -h"$HOST" -P"$PORT" -u"$USER" -p"$PASS" \
            -e "USE \`${DB}\`;" &>/dev/null 2>&1
    }

    # ── [9] Fix DB credentials ────────────────────────────────
    _fp_fix_db() {
        step "Fix DB Credentials"
        [ ! -f /var/www/pterodactyl/.env ] && { err ".env not found"; return 1; }

        local CUR_HOST CUR_USER CUR_DB CUR_PASS
        CUR_HOST=$( _env_get DB_HOST     ); CUR_HOST=${CUR_HOST:-127.0.0.1}
        CUR_USER=$( _env_get DB_USERNAME ); CUR_USER=${CUR_USER:-pterodactyl}
        CUR_DB=$(   _env_get DB_DATABASE ); CUR_DB=${CUR_DB:-panel}
        CUR_PASS=$( _env_get DB_PASSWORD )

        info "Current .env DB settings:"
        echo -e "  Host : ${CUR_HOST}"
        echo -e "  User : ${CUR_USER}"
        echo -e "  DB   : ${CUR_DB}"
        echo -e "  Pass : ${CUR_PASS:-(empty!)}"
        echo ""

        # Try to connect with current creds first
        if _fp_db_ok; then
            ok "DB connection works fine with current .env credentials"
            return 0
        fi

        err "DB connection FAILED (Access denied or wrong password)"
        echo ""
        warn "This usually means the DB password in .env doesn't match MariaDB."
        echo ""
        echo -e "  ${WHITE}Choose a fix:${RESET}"
        echo -e "  ${GREEN}[A]${RESET} Enter the correct password (I know it)"
        echo -e "  ${GREEN}[B]${RESET} Reset the DB password to a new one (I don't know it)"
        ask "Choose [A/B]:"; read -r DB_FIX_CHOICE

        if [[ "$DB_FIX_CHOICE" =~ ^[Aa]$ ]]; then
            # ── User knows the password
            ask "Enter the correct DB password for user '${CUR_USER}':"; read -r -s NEW_DB_PASS; echo ""
            [ -z "$NEW_DB_PASS" ] && { warn "No password entered. Aborted."; return 1; }

            # Test it directly before writing
            mysql -h"$CUR_HOST" -u"$CUR_USER" -p"$NEW_DB_PASS" \
                -e "USE \`${CUR_DB}\`;" &>/dev/null 2>&1
            if [ $? -ne 0 ]; then
                err "Still can't connect with that password. Try option [B] to reset it."
                return 1
            fi

            # Write correct password into .env
            sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${NEW_DB_PASS}/" \
                /var/www/pterodactyl/.env
            ok ".env updated with correct password"

        elif [[ "$DB_FIX_CHOICE" =~ ^[Bb]$ ]]; then
            # ── Generate a new password and reset in MariaDB
            local NEW_PASS
            NEW_PASS=$(tr -dc 'A-Za-z0-9!@#%^&*' </dev/urandom | head -c 24)

            info "Resetting password for MariaDB user '${CUR_USER}'@'127.0.0.1'..."

            # Try with root (no password first, then prompt)
            local ROOT_OK=false
            mysql -u root -e "SELECT 1;" &>/dev/null 2>&1 && ROOT_OK=true

            if [ "$ROOT_OK" = "false" ]; then
                ask "Enter MariaDB ROOT password:"; read -r -s DB_ROOT_PW; echo ""
                mysql -u root -p"$DB_ROOT_PW" \
                    -e "ALTER USER '${CUR_USER}'@'127.0.0.1' IDENTIFIED BY '${NEW_PASS}'; FLUSH PRIVILEGES;" \
                    2>/dev/null
            else
                mysql -u root \
                    -e "ALTER USER '${CUR_USER}'@'127.0.0.1' IDENTIFIED BY '${NEW_PASS}'; FLUSH PRIVILEGES;" \
                    2>/dev/null
            fi

            if [ $? -ne 0 ]; then
                # Try localhost binding too
                mysql -u root \
                    -e "ALTER USER '${CUR_USER}'@'localhost' IDENTIFIED BY '${NEW_PASS}'; FLUSH PRIVILEGES;" \
                    2>/dev/null || {
                    err "Could not reset password in MariaDB. Try manually:"
                    err "  mysql -u root"
                    err "  ALTER USER '${CUR_USER}'@'127.0.0.1' IDENTIFIED BY 'newpass';"
                    return 1
                }
            fi

            # Write new password into .env
            sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${NEW_PASS}/" \
                /var/www/pterodactyl/.env

            ok "MariaDB password reset + .env updated"
            info "New password (save this!): ${BOLD}${GREEN}${NEW_PASS}${RESET}"
        else
            warn "Invalid choice. Aborted."; return 1
        fi

        # Also make sure DB_HOST is 127.0.0.1 not localhost (avoids socket vs TCP mismatch)
        local ENV_HOST; ENV_HOST=$(_env_get DB_HOST)
        if [ "$ENV_HOST" = "localhost" ]; then
            sed -i 's/^DB_HOST=localhost/DB_HOST=127.0.0.1/' /var/www/pterodactyl/.env
            ok "Fixed DB_HOST: localhost → 127.0.0.1  (prevents socket/TCP mismatch)"
        fi

        # Clear config cache so Laravel picks up new .env
        cd /var/www/pterodactyl &>/dev/null
        php artisan config:clear &>/dev/null
        ok "Config cache cleared"

        # Final test
        if _fp_db_ok; then
            ok "DB connection verified — panel can reach database!"
        else
            err "Still failing. Check .env manually: cat /var/www/pterodactyl/.env | grep DB_"
        fi
    }

    _fp_permissions() {
        step "Fix Permissions"
        chown -R www-data:www-data /var/www/pterodactyl
        chmod -R 755 /var/www/pterodactyl/storage \
                     /var/www/pterodactyl/bootstrap/cache 2>/dev/null
        ok "Permissions fixed"
    }

    _fp_queue() {
        step "Queue Worker"
        systemctl restart pteroq 2>/dev/null \
            && ok "pteroq restarted — $(systemctl is-active pteroq)" \
            || warn "pteroq restart failed — is the service file installed?"
    }

    _fp_nginx() {
        step "Nginx"
        if ! nginx_available; then
            warn "Nginx is NOT installed."
            ask "Install Nginx now? [y/n]:"; read -r INST_NGX
            if [[ "$INST_NGX" =~ ^[Yy]$ ]]; then
                DEBIAN_FRONTEND=noninteractive apt-get install -y \
                    nginx certbot python3-certbot-nginx &>/dev/null
                ok "Nginx installed"
                if [ -d /var/www/pterodactyl ]; then
                    ask "Panel domain (to recreate vhost):"; read -r FIX_DOMAIN
                    _write_nginx_http_vhost "$FIX_DOMAIN" "80"
                    rm -f /etc/nginx/sites-enabled/default
                    ok "Nginx vhost recreated for ${FIX_DOMAIN}"
                fi
                systemctl enable --now nginx &>/dev/null
            else
                return
            fi
        fi
        if nginx -t &>/dev/null; then
            systemctl reload nginx && ok "Nginx reloaded OK"
        else
            err "Nginx config syntax errors:"
            nginx -t 2>&1
        fi
    }

    _fp_redis() {
        step "Redis"
        if ! systemctl is-active --quiet redis-server; then
            info "Redis not running — attempting start..."
            systemctl enable redis-server &>/dev/null
            systemctl start  redis-server &>/dev/null
            sleep 3
            if systemctl is-active --quiet redis-server; then
                ok "Redis started"
            else
                err "Redis failed — switching Panel to file drivers"
                if [ -f /var/www/pterodactyl/.env ]; then
                    sed -i 's/^CACHE_DRIVER=.*/CACHE_DRIVER=file/'     /var/www/pterodactyl/.env
                    sed -i 's/^SESSION_DRIVER=.*/SESSION_DRIVER=file/' /var/www/pterodactyl/.env
                    sed -i 's/^QUEUE_DRIVER=.*/QUEUE_DRIVER=sync/'     /var/www/pterodactyl/.env
                    ok ".env updated — file drivers (no Redis)"
                fi
            fi
        else
            ok "Redis is running"
        fi
    }

    _fp_cache() {
        step "Clear Caches"
        _fp_redis
        cd /var/www/pterodactyl || { err "Panel directory not found"; return; }
        # Check DB before running artisan commands that need it
        if ! _fp_db_ok; then
            warn "DB not reachable — run option [9] to fix DB credentials first"
            warn "Attempting cache clear anyway (non-DB caches)..."
        fi
        php artisan view:clear   2>&1 | grep -Ev "^[[:space:]]*$"
        php artisan config:clear 2>&1 | grep -Ev "^[[:space:]]*$"
        php artisan route:clear  2>&1 | grep -Ev "^[[:space:]]*$"
        php artisan cache:clear  2>&1 | grep -Ev "^[[:space:]]*$"
        ok "Caches cleared"
    }

    _fp_migrate() {
        step "Migrations"
        _fp_redis
        cd /var/www/pterodactyl || { err "Panel directory not found"; return; }

        # Check DB credentials BEFORE running migrate
        if ! _fp_db_ok; then
            err "DB connection failed — cannot run migrations"
            err "Run option [9] (Fix DB credentials) first, then retry"
            echo ""
            info "Current DB_HOST:     $(_env_get DB_HOST)"
            info "Current DB_USERNAME: $(_env_get DB_USERNAME)"
            info "Current DB_PASSWORD: $(_env_get DB_PASSWORD)"
            return 1
        fi

        ok "DB connection verified — running migrations..."
        php artisan migrate --force && ok "Migrations complete"
    }

    _fp_composer() {
        step "Composer Autoload"
        cd /var/www/pterodactyl || { err "Panel directory not found"; return; }
        COMPOSER_ALLOW_SUPERUSER=1 \
            composer install --no-dev --optimize-autoloader &>/dev/null \
            && ok "Composer autoload rebuilt"
    }

    case "$FIX_OPT" in
        1) _fp_permissions ;;
        2) _fp_queue ;;
        3) _fp_nginx ;;
        4) _fp_cache ;;
        5) _fp_migrate ;;
        6) _fp_composer ;;
        7) _fp_redis ;;
        8)
            _fp_fix_db       # always fix DB first in full repair
            _fp_permissions
            _fp_redis
            _fp_queue
            _fp_nginx
            _fp_cache
            _fp_migrate
            _fp_composer
            ;;
        9) _fp_fix_db ;;
        *) warn "Invalid option" ;;
    esac
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}


# ═══════════════════════════════════════════════════════════════
#  [11]  FIX / REPAIR WINGS
# ═══════════════════════════════════════════════════════════════
fix_wings() {
    show_banner; echo -e "${BOLD}${CYAN}  🛠️  FIX / REPAIR WINGS${RESET}"; sep; require_root
    echo -e "  ${WHITE}Choose a fix:${RESET}"
    echo -e "  ${GREEN}[1]${RESET} Restart Wings"
    echo -e "  ${GREEN}[2]${RESET} Reconfigure Wings (new token)"
    echo -e "  ${GREEN}[3]${RESET} Fix Docker networking"
    echo -e "  ${GREEN}[4]${RESET} Full Wings diagnostic + last 30 logs"
    echo -e "  ${GREEN}[5]${RESET} Restart Wings + Docker"
    sep; ask "Choose:"; read -r WFIX_OPT
    case "$WFIX_OPT" in
        1) systemctl restart wings 2>/dev/null && ok "Wings restarted — $(systemctl is-active wings)" ;;
        2)
            systemctl stop wings 2>/dev/null
            ask "Panel URL:"; read -r W_URL
            ask "Wings token (Panel → Node → Configuration):"; read -r W_TOKEN
            ask "Node ID:"; read -r W_NID
            wings configure --panel-url="$W_URL" --token="$W_TOKEN" --node="$W_NID" --allow-insecure
            systemctl start wings; ok "Wings reconfigured + started"
            ;;
        3) systemctl restart docker && ok "Docker restarted"
           docker network prune -f && ok "Unused networks pruned"
           systemctl restart wings && ok "Wings restarted" ;;
        4)
            echo -e "\n  ${WHITE}═══ Diagnostic ═══${RESET}"
            echo -e "  Wings  : $(systemctl is-active wings 2>/dev/null || echo 'not-found')"
            echo -e "  Docker : $(systemctl is-active docker 2>/dev/null || echo 'not-found')"
            command -v wings &>/dev/null \
                && echo -e "  Version: $(wings --version 2>/dev/null)" \
                || echo -e "  Binary : ${RED}NOT FOUND${RESET}"
            [ -f /etc/pterodactyl/config.yml ] \
                && echo -e "  Config : ${GREEN}EXISTS${RESET}" \
                || echo -e "  Config : ${RED}MISSING — run wings configure${RESET}"
            echo -e "\n  ${WHITE}═══ Last 30 logs ═══${RESET}"
            journalctl -u wings --no-pager -n 30 --no-hostname 2>/dev/null \
                || warn "No journal logs found"
            ;;
        5) systemctl restart docker; sleep 2; systemctl restart wings; ok "Docker + Wings restarted" ;;
        *) warn "Invalid option" ;;
    esac
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#  [12]  BLUEPRINTS MANAGER
# ═══════════════════════════════════════════════════════════════
blueprints_menu() {
    show_banner; echo -e "${BOLD}${MAGENTA}  🧩 BLUEPRINTS MANAGER${RESET}"; sep; require_root

    echo -e "  ${DIM}Blueprint Framework extends Pterodactyl with community addons.${RESET}"
    sep
    echo -e "  ${GREEN}[1]${RESET} Install Blueprint Framework"
    echo -e "  ${GREEN}[2]${RESET} Install a Blueprint extension (.blueprint file or URL)"
    echo -e "  ${GREEN}[3]${RESET} List installed Blueprint extensions"
    echo -e "  ${GREEN}[4]${RESET} Remove a Blueprint extension"
    echo -e "  ${GREEN}[5]${RESET} Update Blueprint Framework"
    echo -e "  ${GREEN}[6]${RESET} Reinstall Blueprint Framework  ${DIM}(wipes + fresh install)${RESET}"
    echo -e "  ${RED}[7]${RESET} Uninstall Blueprint Framework  ${DIM}(removes all BP files)${RESET}"
    echo -e "  ${GREEN}[8]${RESET} Show community links"
    sep; ask "Choose:"; read -r BP_OPT

    # ════════════════════════════════════════════════════════
    #   HELPER — clone + run blueprint.sh
    #   $1 = "install" | "update" | "reinstall"
    # ════════════════════════════════════════════════════════
    _bp_run_framework() {
        local MODE="$1"
        [ ! -d /var/www/pterodactyl ] && { err "Panel not found at /var/www/pterodactyl"; return 1; }

        # Dependencies
        DEBIAN_FRONTEND=noninteractive apt-get install -y unzip git curl &>/dev/null

        # Get latest tag
        info "Fetching latest Blueprint release tag..."
        local BP_TAG
        BP_TAG=$(curl -fsSL \
            "https://api.github.com/repos/BlueprintFramework/framework/releases/latest" \
            2>/dev/null | grep '"tag_name"' | head -1 \
            | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
        [ -z "$BP_TAG" ] && BP_TAG="main" && \
            warn "Could not fetch tag — using main branch"
        ok "Blueprint version: ${BP_TAG}"

        # Clone to temp
        info "Cloning Blueprint Framework (${BP_TAG})..."
        local BP_TMP="/tmp/blueprint-framework-$$"
        rm -rf "$BP_TMP"
        if [ "$BP_TAG" = "main" ]; then
            git clone --depth=1 \
                https://github.com/BlueprintFramework/framework.git \
                "$BP_TMP" 2>&1 | tail -3
        else
            git clone --depth=1 --branch "$BP_TAG" \
                https://github.com/BlueprintFramework/framework.git \
                "$BP_TMP" 2>&1 | tail -3
        fi
        if [ ! -d "$BP_TMP" ] || [ ! -f "$BP_TMP/blueprint.sh" ]; then
            err "Clone failed or blueprint.sh missing. Check connectivity."
            rm -rf "$BP_TMP"; return 1
        fi
        ok "Source downloaded"

        # Remove ONLY the conflicting blueprint CLI shortcut file (not the .blueprint dir)
        # The CLI shortcut is a plain file at /usr/local/bin/blueprint or /var/www/pterodactyl/blueprint
        rm -f /var/www/pterodactyl/blueprint    2>/dev/null  # stale CLI file
        rm -f /usr/local/bin/blueprint          2>/dev/null  # old shortcut

        # Copy framework files — skip .git, never overwrite directories with files
        info "Copying Blueprint source files into panel..."
        find "$BP_TMP" -maxdepth 1 -mindepth 1 | while IFS= read -r item; do
            local bname; bname=$(basename "$item")
            [ "$bname" = ".git" ] && continue
            local dest="/var/www/pterodactyl/${bname}"
            if [ -d "$item" ]; then
                if [ -f "$dest" ]; then
                    # dest is a plain file but source is a dir — remove the file first
                    rm -f "$dest"
                fi
                cp -r "$item" /var/www/pterodactyl/ 2>/dev/null || true
            else
                if [ -d "$dest" ]; then
                    : # dest is a dir, source is file — skip silently
                else
                    cp "$item" /var/www/pterodactyl/ 2>/dev/null || true
                fi
            fi
        done
        rm -rf "$BP_TMP"
        ok "Files copied"

        # Ensure Node.js + Yarn are installed (Blueprint requires both)
        # Always ensure Node.js >= 20 (Blueprint requires it)
        NODE_MAJOR=$(node --version 2>/dev/null | grep -oE '[0-9]+' | head -1)
        if [ -z "$NODE_MAJOR" ] || [ "$NODE_MAJOR" -lt 20 ]; then
            info "Installing Node.js 20 (current: ${NODE_MAJOR:-none})..."
            # Purge ALL old node packages and binaries
            DEBIAN_FRONTEND=noninteractive apt-get purge -y nodejs npm libnode-dev 'libnode*' 2>/dev/null || true
            apt-get autoremove -y &>/dev/null || true
            rm -f /usr/bin/node /usr/bin/nodejs /usr/bin/npm /usr/bin/npx
            rm -f /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx
            hash -r 2>/dev/null || true
            # Remove any broken third-party repos that block apt update
            rm -f /etc/apt/sources.list.d/*ookla* /etc/apt/sources.list.d/*speedtest*                   /etc/apt/trusted.gpg.d/*ookla* /usr/share/keyrings/*ookla* 2>/dev/null || true
            # Add NodeSource repo and install
            curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
            DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
            # Flush shell command cache so new binary is found
            hash -r 2>/dev/null || true
            # Verify
            NODE_MAJOR=$(/usr/bin/node --version 2>/dev/null | grep -oE '[0-9]+' | head -1)
            if [ -z "$NODE_MAJOR" ] || [ "$NODE_MAJOR" -lt 20 ]; then
                err "Node.js 20 install failed (got: $(/usr/bin/node --version 2>/dev/null || echo none))"
                return 1
            fi
            # Point node/npm to new binaries explicitly
            ln -sf /usr/bin/node /usr/local/bin/node 2>/dev/null || true
            ln -sf /usr/bin/npm  /usr/local/bin/npm  2>/dev/null || true
        fi
        if ! command -v yarn &>/dev/null; then
            info "Installing Yarn..."
            # Must use npm — NOT apt (apt's yarn = cmdtest, wrong package)
            npm install -g yarn &>/dev/null
            # Ensure yarn is accessible system-wide regardless of PATH
            YARN_BIN=$(npm root -g 2>/dev/null | sed 's|/node_modules||')/bin/yarn
            if [ -f "$YARN_BIN" ] && [ ! -f /usr/bin/yarn ]; then
                ln -sf "$YARN_BIN" /usr/bin/yarn
            fi
            # Also try corepack as fallback
            if ! command -v yarn &>/dev/null && command -v corepack &>/dev/null; then
                corepack enable &>/dev/null
                corepack prepare yarn@stable --activate &>/dev/null
            fi
            # Hard symlink from known npm global bin locations
            for p in /usr/local/bin/yarn /usr/lib/node_modules/.bin/yarn /root/.npm-global/bin/yarn; do
                [ -f "$p" ] && ln -sf "$p" /usr/bin/yarn && break
            done
        fi
        # Final verify — abort early with clear message if still missing
        if ! command -v yarn &>/dev/null; then
            err "Yarn install failed — cannot continue Blueprint install"
            err "Run manually: npm install -g yarn && ln -sf \$(which yarn) /usr/bin/yarn"
            return 1
        fi
        ok "Node $(node --version 2>/dev/null) / Yarn $(yarn --version 2>/dev/null) ready"

        # Run installer as root (it handles its own permissions internally)
        chmod +x /var/www/pterodactyl/blueprint.sh
        cd /var/www/pterodactyl || return 1

        info "Running blueprint.sh (this will take ~2-3 minutes)..."
        bash /var/www/pterodactyl/blueprint.sh
        local EXIT_CODE=$?

        if [ $EXIT_CODE -eq 0 ]; then
            ok "Blueprint Framework ${MODE}ed successfully!"
            # Fix ownership after install
            chown -R www-data:www-data /var/www/pterodactyl &>/dev/null
            # Check CLI
            if command -v blueprint &>/dev/null; then
                # blueprint uses -help not --version
                local BP_VER
                BP_VER=$(blueprint -v 2>/dev/null \
                    || blueprint -version 2>/dev/null \
                    || echo "installed")
                ok "blueprint CLI: ${BP_VER}"
            else
                info "Tip: if 'blueprint' command not found, run: hash -r  or re-login"
            fi
        else
            err "Blueprint installer exited with errors (code ${EXIT_CODE})"
            err "Check the output above for details"
            return 1
        fi
    }

    # ════════════════════════════════════════════════════════
    #   OPTION DISPATCH
    # ════════════════════════════════════════════════════════
    case "$BP_OPT" in

        # ── [1] Install ───────────────────────────────────
        1)
            step "Install Blueprint Framework"
            if command -v blueprint &>/dev/null || \
               [ -d /var/www/pterodactyl/.blueprint ]; then
                warn "Blueprint appears to already be installed."
                warn "Use option [5] to update, or [6] to reinstall from scratch."
                pause; return
            fi
            _bp_run_framework "install"
            ;;

        # ── [2] Install extension ─────────────────────────
        2)
            step "Install Blueprint Extension"
            if ! command -v blueprint &>/dev/null; then
                err "Blueprint Framework is not installed. Run option [1] first."
                pause; return
            fi
            echo ""
            echo -e "  ${DIM}Paste a direct .blueprint file URL, or a local file path.${RESET}"
            echo -e "  ${DIM}Find extensions at: https://blueprint.zip/browse${RESET}"
            echo ""
            ask "URL or file path:"; read -r BP_IN
            [ -z "$BP_IN" ] && { warn "Nothing entered."; pause; return; }

            cd /var/www/pterodactyl || exit

            if [[ "$BP_IN" =~ ^https?:// ]]; then
                info "Downloading extension..."
                local BP_FN
                BP_FN=$(basename "$BP_IN" | sed 's/[?#&].*//')
                [[ "$BP_FN" != *.blueprint ]] && BP_FN="extension.blueprint"
                curl -fsSL -o "/var/www/pterodactyl/${BP_FN}" "$BP_IN"
                if [ $? -ne 0 ]; then
                    err "Download failed — check the URL"; pause; return
                fi
                ok "Downloaded: ${BP_FN}"
                blueprint -install "$BP_FN"
                local RC=$?
            else
                [ ! -f "$BP_IN" ] && { err "File not found: $BP_IN"; pause; return; }
                local BP_FN; BP_FN=$(basename "$BP_IN")
                cp "$BP_IN" "/var/www/pterodactyl/${BP_FN}"
                blueprint -install "$BP_FN"
                local RC=$?
            fi
            [ $RC -eq 0 ] && ok "Extension installed!" || err "Install failed — check output above"
            ;;

        # ── [3] List ──────────────────────────────────────
        3)
            step "Installed Blueprint Extensions"
            cd /var/www/pterodactyl 2>/dev/null || { err "Panel not found"; pause; return; }
            if command -v blueprint &>/dev/null; then
                echo ""
                # List installed extensions via filesystem (blueprint -list not supported)
            local EXT_DIR="/var/www/pterodactyl/.blueprint/extensions"
            if [ -d "$EXT_DIR" ] && [ "$(ls -A "$EXT_DIR" 2>/dev/null)" ]; then
                echo ""
                ls "$EXT_DIR" 2>/dev/null | sed 's/^/    /'
                echo ""
            else
                warn "No extensions installed yet"
            fi
            elif [ -d /var/www/pterodactyl/.blueprint/extensions ]; then
                info "Extensions found in .blueprint/extensions/:"
                ls -1 /var/www/pterodactyl/.blueprint/extensions/ 2>/dev/null \
                    | grep -v '^blueprint$' \
                    | while read -r ext; do echo -e "  ${GREEN}→${RESET} ${ext}"; done
            else
                warn "Blueprint Framework not installed — run option [1]"
            fi
            ;;

        # ── [4] Remove extension ──────────────────────────
        4)
            step "Remove Blueprint Extension"
            if ! command -v blueprint &>/dev/null; then
                err "Blueprint Framework not installed."; pause; return
            fi
            cd /var/www/pterodactyl || exit
            echo ""
            info "Currently installed extensions:"
            # List installed extensions via filesystem
            local EXT_DIR="/var/www/pterodactyl/.blueprint/extensions"
            if [ -d "$EXT_DIR" ] && [ "$(ls -A "$EXT_DIR" 2>/dev/null)" ]; then
                echo ""
                ls "$EXT_DIR" 2>/dev/null | sed 's/^/    /'
                echo ""
            else
                warn "No extensions installed"
            fi
            echo ""
            ask "Extension ID to remove (e.g. nightadmin):"; read -r BID
            [ -z "$BID" ] && { warn "No ID entered."; pause; return; }
            warn "Removing '${BID}' — panel assets will rebuild (~1 min)"
            ask "Confirm? [y/n]:"; read -r RMCONFIRM
            [[ "$RMCONFIRM" =~ ^[Yy]$ ]] || { info "Aborted."; pause; return; }
            blueprint -remove "$BID"
            local RC=$?
            if [ $RC -eq 0 ]; then
                ok "'${BID}' removed successfully!"
                chown -R www-data:www-data /var/www/pterodactyl &>/dev/null
            else
                err "Remove failed (exit $RC)"
                warn "Check the ID is correct — run: ls /var/www/pterodactyl/.blueprint/extensions/"
            fi
            ;;

        # ── [5] Update framework ──────────────────────────
        5)
            step "Update Blueprint Framework"
            if ! command -v blueprint &>/dev/null && \
               [ ! -d /var/www/pterodactyl/.blueprint ]; then
                warn "Blueprint doesn't appear to be installed. Use option [1] to install."
                pause; return
            fi
            _bp_run_framework "update"
            ;;

        # ── [6] Reinstall (wipe + fresh) ──────────────────
        6)
            step "Reinstall Blueprint Framework"
            warn "This removes all Blueprint Framework files then reinstalls fresh."
            warn "Your installed EXTENSIONS will be removed too."
            ask "Type CONFIRM to proceed:"; read -r RECONF
            [[ "$RECONF" != "CONFIRM" ]] && { info "Aborted."; pause; return; }

            info "Removing Blueprint Framework files..."
            rm -rf /var/www/pterodactyl/.blueprint
            rm -f  /var/www/pterodactyl/blueprint.sh
            rm -rf /var/www/pterodactyl/blueprint
            rm -f  /usr/local/bin/blueprint
            # Remove Blueprint-added routes/config if present
            rm -f  /var/www/pterodactyl/routes/blueprint.php 2>/dev/null
            ok "Blueprint files removed"

            info "Running fresh install..."
            _bp_run_framework "reinstall"
            ;;

        # ── [7] Uninstall framework ───────────────────────
        7)
            step "Uninstall Blueprint Framework"
            warn "This PERMANENTLY removes Blueprint Framework and all its extensions."
            warn "The Pterodactyl Panel itself will remain intact."
            ask "Type REMOVE-BLUEPRINT to confirm:"; read -r UNCONF
            [[ "$UNCONF" != "REMOVE-BLUEPRINT" ]] && { info "Aborted."; pause; return; }

            info "Stopping queue worker..."
            systemctl stop pteroq 2>/dev/null

            info "Removing Blueprint files..."
            rm -rf /var/www/pterodactyl/.blueprint
            rm -f  /var/www/pterodactyl/blueprint.sh
            rm -rf /var/www/pterodactyl/blueprint
            rm -f  /usr/local/bin/blueprint
            rm -f  /var/www/pterodactyl/routes/blueprint.php 2>/dev/null

            info "Clearing Panel caches..."
            cd /var/www/pterodactyl 2>/dev/null && {
                php artisan view:clear   &>/dev/null
                php artisan config:clear &>/dev/null
                php artisan route:clear  &>/dev/null
                php artisan cache:clear  &>/dev/null
                # Rebuild panel assets without Blueprint
                php artisan up &>/dev/null
            }

            info "Fixing permissions..."
            chown -R www-data:www-data /var/www/pterodactyl &>/dev/null

            systemctl start pteroq 2>/dev/null
            ok "Blueprint Framework fully uninstalled"
            info "Panel is still running — Blueprint extensions are gone"
            ;;

        # ── [8] Links ─────────────────────────────────────
        8)
            echo ""
            echo -e "  ${WHITE}Blueprint Community Resources:${RESET}"
            echo -e "  ${CYAN}  🌐 https://blueprint.zip                 ${DIM}official site + browse extensions${RESET}"
            echo -e "  ${CYAN}  🐙 https://github.com/BlueprintFramework/framework${RESET}"
            echo -e "  ${CYAN}  💬 https://discord.gg/blueprint          ${DIM}community Discord${RESET}"
            echo -e "  ${CYAN}  📦 https://blueprint.zip/browse          ${DIM}extension marketplace${RESET}"
            ;;

        *) warn "Invalid option" ;;
    esac

    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#  [13]  EGGS MANAGER
# ═══════════════════════════════════════════════════════════════
eggs_menu() {
    show_banner; echo -e "${BOLD}${MAGENTA}  🥚 ADDONS / EGGS MANAGER${RESET}"; sep; require_root
    echo -e "  ${GREEN}[1]${RESET} Import Egg (file or URL)"
    echo -e "  ${GREEN}[2]${RESET} Show community repos"
    echo -e "  ${GREEN}[3]${RESET} Scan directory for egg JSONs"
    echo -e "  ${GREEN}[4]${RESET} Clone Pelican Eggs → /tmp"
    echo -e "  ${GREEN}[5]${RESET} Clone parkervcp Eggs → /tmp"
    sep; ask "Choose:"; read -r EGG_OPT
    case "$EGG_OPT" in
        1) ask "Path or URL:"; read -r ES
           [[ "$ES" =~ ^http ]] && { curl -fsSL -o /tmp/_zynr_egg.json "$ES"; ok "Downloaded to /tmp/_zynr_egg.json"; } \
               || ok "Local file: $ES"
           info "Import: Panel → Admin → Nests → Import Egg" ;;
        2) echo -e "\n  ${CYAN}• https://github.com/pelican-eggs/eggs\n  • https://github.com/parkervcp/eggs\n  • https://github.com/ign-gg/Pterodactyl-Eggs${RESET}" ;;
        3) ask "Directory:"; read -r ED
           [ -d "$ED" ] || { err "Not found: $ED"; pause; return; }
           C=0; for f in "$ED"/*.json; do [ -f "$f" ] || continue
               N=$(python3 -c "import json; print(json.load(open('$f')).get('name','?'))" 2>/dev/null || basename "$f")
               echo -e "  ${GREEN}→${RESET} $N  ${DIM}($f)${RESET}"; C=$((C+1)); done
           info "Total: $C eggs" ;;
        4) rm -rf /tmp/pelican-eggs
           git clone --depth=1 https://github.com/pelican-eggs/eggs /tmp/pelican-eggs &>/dev/null
           ok "Cloned → /tmp/pelican-eggs" ;;
        5) rm -rf /tmp/parkervcp-eggs
           git clone --depth=1 https://github.com/parkervcp/eggs /tmp/parkervcp-eggs &>/dev/null
           ok "Cloned → /tmp/parkervcp-eggs" ;;
        *) warn "Invalid option" ;;
    esac
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#  [14]  SSL MANAGER
# ═══════════════════════════════════════════════════════════════
ssl_menu() {
    show_banner; echo -e "${BOLD}${BLUE}  🔐 SSL CERTIFICATE MANAGER${RESET}"; sep; require_root
    echo -e "  ${GREEN}[1]${RESET} Issue cert (Nginx plugin)"
    echo -e "  ${GREEN}[2]${RESET} Issue cert (Standalone — stops Nginx briefly)"
    echo -e "  ${GREEN}[3]${RESET} Renew all certs"
    echo -e "  ${GREEN}[4]${RESET} List certs"
    echo -e "  ${GREEN}[5]${RESET} Revoke a cert"
    echo -e "  ${GREEN}[6]${RESET} Dry-run renewal test"
    sep; ask "Choose:"; read -r SSL_OPT
    case "$SSL_OPT" in
        1) ! nginx_available && { err "Nginx not installed"; pause; return; }
           ask "Domain:"; read -r SD; ask "Email:"; read -r SE
           certbot --nginx -d "$SD" --email "$SE" --agree-tos --no-eff-email --redirect -n && ok "Cert issued for $SD" ;;
        2) ask "Domain:"; read -r SD; ask "Email:"; read -r SE
           nginx_available && systemctl stop nginx 2>/dev/null
           certbot certonly --standalone -d "$SD" --email "$SE" --agree-tos --no-eff-email -n && ok "Standalone cert for $SD"
           nginx_available && systemctl start nginx 2>/dev/null ;;
        3) certbot renew --quiet && ok "All certs renewed" ;;
        4) certbot certificates ;;
        5) ask "Domain to revoke:"; read -r RD; certbot revoke --cert-name "$RD" -n && ok "Revoked: $RD" ;;
        6) certbot renew --dry-run && ok "Dry run passed" ;;
        *) warn "Invalid option" ;;
    esac
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#   INTERNAL: install cloudflared binary
# ═══════════════════════════════════════════════════════════════
_install_cloudflared() {
    command -v cloudflared &>/dev/null && { ok "cloudflared: $(cloudflared --version 2>/dev/null | head -1)"; return; }
    info "Installing cloudflared..."
    local ARCH; ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
    curl -fsSL -o /usr/local/bin/cloudflared \
        "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}"
    chmod +x /usr/local/bin/cloudflared
    ok "cloudflared: $(cloudflared --version 2>/dev/null | head -1)"
}

# ═══════════════════════════════════════════════════════════════
#  [15]  CLOUDFLARE TUNNEL MANAGER
# ═══════════════════════════════════════════════════════════════
cloudflare_menu() {
    show_banner; echo -e "${BOLD}${BLUE}  ☁️  CLOUDFLARE TUNNEL MANAGER${RESET}"; sep; require_root
    echo -e "  ${DIM}Expose Panel/Wings without opening ports — Cloudflare handles HTTPS.${RESET}"; sep
    echo -e "  ${GREEN}[1]${RESET}  Install / Update cloudflared binary"
    echo -e "  ${GREEN}[2]${RESET}  ⭐ Install Tunnel via TOKEN  ← USE THIS"
    echo -e "         ${DIM}Get token from: one.dash.cloudflare.com → Networks → Tunnels${RESET}"
    echo -e "  ${GREEN}[3]${RESET}  Start / Stop / Restart Tunnel service"
    echo -e "  ${GREEN}[4]${RESET}  Show Tunnel status + last 30 logs"
    echo -e "  ${GREEN}[5]${RESET}  Check + fix Nginx for Cloudflare mode"
    echo -e "  ${GREEN}[6]${RESET}  Uninstall / remove cloudflared service"
    sep; ask "Choose:"; read -r CF_OPT
    case "$CF_OPT" in
        1)
            rm -f /usr/local/bin/cloudflared
            _install_cloudflared
            ;;
        2)
            _install_cloudflared
            echo ""
            echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════════╗${RESET}"
            echo -e "${BOLD}${WHITE}  ║  HOW TO GET YOUR TOKEN:                                  ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║  1. https://one.dash.cloudflare.com                      ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║  2. Networks → Tunnels → Create a Tunnel                 ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║  3. Type: Cloudflared  → give it a name                  ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║  4. Copy the token (eyJhIjoiOWU1OTA5...)                 ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║  5. Public Hostname → add your subdomain → HTTP:80       ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║  6. Make sure SSL/TLS mode is Full or Full (Strict)      ║${RESET}"
            echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════════╝${RESET}"
            echo ""
            # Stop and remove any old cloudflared service first
            systemctl stop cloudflared 2>/dev/null
            systemctl disable cloudflared 2>/dev/null
            cloudflared service uninstall 2>/dev/null
            rm -f /etc/systemd/system/cloudflared.service
            systemctl daemon-reload
            ask "Paste your Cloudflare Tunnel token:"; read -r CF_TOKEN
            if [ -z "$CF_TOKEN" ]; then
                warn "No token entered. Aborted."
            else
                info "Installing cloudflared with token..."
                cloudflared service install "$CF_TOKEN"
                if [ $? -eq 0 ]; then
                    systemctl enable --now cloudflared &>/dev/null
                    sleep 3
                    systemctl is-active --quiet cloudflared \
                        && ok "Tunnel service running!" \
                        || { err "Service not active — logs:"; journalctl -u cloudflared --no-pager -n 15 --no-hostname; }
                else
                    err "Token install failed — check token and retry"
                fi
            fi
            ;;
        3)
            echo -e "  ${GREEN}[1]${RESET} Start  ${GREEN}[2]${RESET} Stop  ${GREEN}[3]${RESET} Restart"
            ask "Choose:"; read -r CS
            case "$CS" in
                1) systemctl start   cloudflared ;;
                2) systemctl stop    cloudflared ;;
                3) systemctl restart cloudflared ;;
                *) warn "Invalid" ;;
            esac
            echo -e "  cloudflared: $(systemctl is-active cloudflared 2>/dev/null)"
            ;;
        4)
            echo -e "\n  ${WHITE}── Service Status ───────────────────────────────────${RESET}"
            systemctl status cloudflared --no-pager -l 2>/dev/null || warn "cloudflared service not found"
            echo -e "\n  ${WHITE}── Last 30 Logs ─────────────────────────────────────${RESET}"
            journalctl -u cloudflared --no-pager -n 30 --no-hostname 2>/dev/null || warn "No logs available"
            ;;
        5)
            info "Checking Nginx for Cloudflare Tunnel mode..."
            if ! nginx_available; then
                err "Nginx not installed"
                ask "Install Nginx now? [y/n]:"; read -r INX
                [[ "$INX" =~ ^[Yy]$ ]] && DEBIAN_FRONTEND=noninteractive apt-get install -y nginx &>/dev/null && ok "Nginx installed"
            fi
            ask "Panel domain (used in server_name):"; read -r CF_FIX_DOMAIN
            _setup_nginx_cf "$CF_FIX_DOMAIN"
            info "Nginx is now serving HTTP on port 80 for cloudflared to connect to."
            info "Make sure your Cloudflare tunnel public hostname points to: http://localhost:80"
            ;;
        6)
            warn "This stops and removes the cloudflared service."
            ask "Confirm? [y/n]:"; read -r UNI
            [[ "$UNI" =~ ^[Yy]$ ]] && {
                systemctl stop cloudflared 2>/dev/null
                systemctl disable cloudflared 2>/dev/null
                cloudflared service uninstall 2>/dev/null
                rm -f /etc/systemd/system/cloudflared.service
                rm -f /usr/local/bin/cloudflared
                systemctl daemon-reload
                ok "cloudflared removed"
            }
            ;;
        *) warn "Invalid option" ;;
    esac
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#  [16]  STATUS & HEALTH CHECK
# ═══════════════════════════════════════════════════════════════
status_check() {
    show_banner; echo -e "${BOLD}${BLUE}  📊 STATUS & HEALTH CHECK${RESET}"; sep
    _chk() {
        local st; st=$(systemctl is-active "$2" 2>/dev/null || echo "not-found")
        [ "$st" = "active" ] \
            && printf "  ${GREEN}[✔]${RESET} %-22s ${GREEN}%s${RESET}\n" "$1" "$st" \
            || printf "  ${RED}[✘]${RESET} %-22s ${RED}%s${RESET}\n" "$1" "$st"
    }
    echo -e "\n  ${WHITE}── Services ─────────────────────────────────────────${RESET}"
    _chk "Nginx"           nginx
    _chk "PHP 8.2-FPM"     php8.2-fpm
    _chk "MariaDB"         mariadb
    _chk "Redis"           redis-server
    _chk "pteroq"          pteroq
    _chk "Wings"           wings
    _chk "Docker"          docker
    _chk "Cloudflared"     cloudflared
    echo -e "\n  ${WHITE}── Resources ────────────────────────────────────────${RESET}"
    df -h / | tail -1 | awk '{printf "  💾 Disk : %s / %s (%s)\n",$3,$2,$5}'
    free -h | awk '/^Mem:/{printf "  🧠 RAM  : %s / %s\n",$3,$2}'
    echo -e "  ⚙️  CPUs : $(nproc)  |  Load:$(uptime | awk -F'load average:' '{print $2}')"
    echo -e "  🌐 IP   : $(hostname -I | awk '{print $1}')  |  $(hostname)"
    echo -e "\n  ${WHITE}── Versions ─────────────────────────────────────────${RESET}"
    [ -f /var/www/pterodactyl/config/app.php ] \
        && echo -e "  🚀 Panel : ${CYAN}v$(grep "'version'" /var/www/pterodactyl/config/app.php | head -1 | awk -F"'" '{print $4}')${RESET}" \
        || echo -e "  🚀 Panel : ${RED}Not installed${RESET}"
    command -v wings &>/dev/null \
        && echo -e "  🔧 Wings : ${CYAN}$(wings --version 2>/dev/null)${RESET}" \
        || echo -e "  🔧 Wings : ${RED}Not installed${RESET}"
    command -v docker &>/dev/null \
        && echo -e "  🐳 Docker: ${CYAN}$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')${RESET}  ($(docker ps -q 2>/dev/null | wc -l) running)" \
        || echo -e "  🐳 Docker: ${RED}Not installed${RESET}"
    command -v cloudflared &>/dev/null \
        && echo -e "  ☁️  CF    : ${CYAN}$(cloudflared --version 2>/dev/null | head -1)${RESET}" \
        || echo -e "  ☁️  CF    : ${DIM}Not installed${RESET}"
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#  [17]  BACKUP & RESTORE
# ═══════════════════════════════════════════════════════════════
backup_menu() {
    show_banner; echo -e "${BOLD}${BLUE}  💾 BACKUP & RESTORE${RESET}"; sep; require_root
    BD="/var/backups/pterodactyl"; mkdir -p "$BD"; TS=$(date +%Y%m%d_%H%M%S)
    echo -e "  ${GREEN}[1]${RESET} Full backup (files + DB)"
    echo -e "  ${GREEN}[2]${RESET} DB only"
    echo -e "  ${GREEN}[3]${RESET} Files only"
    echo -e "  ${GREEN}[4]${RESET} Restore"
    echo -e "  ${GREEN}[5]${RESET} List backups"
    echo -e "  ${GREEN}[6]${RESET} Delete old backups"
    sep; ask "Choose:"; read -r BO
    case "$BO" in
        1) tar -czf "$BD/panel_files_${TS}.tar.gz" /var/www/pterodactyl &>/dev/null & spinner "Backing up files"
           mysqldump panel > "$BD/panel_db_${TS}.sql" 2>/dev/null; ok "Full backup → $BD" ;;
        2) mysqldump panel > "$BD/panel_db_${TS}.sql" 2>/dev/null; ok "DB → $BD/panel_db_${TS}.sql" ;;
        3) tar -czf "$BD/panel_files_${TS}.tar.gz" /var/www/pterodactyl &>/dev/null & spinner "Backing up files"
           ok "Files → $BD/panel_files_${TS}.tar.gz" ;;
        4) ls -lh "$BD" 2>/dev/null || { warn "No backups"; pause; return; }
           ask "Filename:"; read -r RF
           [[ "$RF" == *.sql ]]    && { mysql panel < "$BD/$RF" && ok "DB restored"; }
           [[ "$RF" == *.tar.gz ]] && { tar -xzf "$BD/$RF" -C / && chown -R www-data:www-data /var/www/pterodactyl && ok "Files restored"; }
           ;;
        5) ls -lh "$BD" 2>/dev/null || warn "No backups" ;;
        6) ask "Delete older than how many days?:"; read -r DD
           find "$BD" -type f -mtime +"$DD" -delete && ok "Old backups removed" ;;
        *) warn "Invalid option" ;;
    esac
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#  [18]  RESET ADMIN PASSWORD
# ═══════════════════════════════════════════════════════════════
reset_admin_password() {
    show_banner; echo -e "${BOLD}${WHITE}  🔑 RESET ADMIN PASSWORD${RESET}"; sep; require_root
    ask "Username or email:"; read -r RU
    ask "New password:"; read -r -s NP; echo ""
    ask "Confirm:"; read -r -s NP2; echo ""
    [ "$NP" != "$NP2" ] && { err "Passwords don't match!"; pause; return; }
    cd /var/www/pterodactyl || exit
    php artisan tinker --execute="
        \$u=\Pterodactyl\Models\User::where('username','${RU}')->orWhere('email','${RU}')->first();
        if(\$u){\$u->password=Hash::make('${NP}');\$u->save();echo 'Updated: '.\$u->username;}
        else{echo 'User not found.';}
    " 2>/dev/null
    ok "Password reset for: $RU"
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#  [19]  DATABASE MANAGER
# ═══════════════════════════════════════════════════════════════
database_menu() {
    show_banner; echo -e "${BOLD}${WHITE}  📦 DATABASE MANAGER${RESET}"; sep; require_root
    echo -e "  ${GREEN}[1]${RESET} Show table sizes"
    echo -e "  ${GREEN}[2]${RESET} Optimize / repair tables"
    echo -e "  ${GREEN}[3]${RESET} Create Node database host user"
    echo -e "  ${GREEN}[4]${RESET} Reset pterodactyl DB password"
    echo -e "  ${GREEN}[5]${RESET} Open MariaDB shell"
    echo -e "  ${BOLD}${RED}[6]${RESET} 💣 Nuke & Recreate Database  ${DIM}(wipes panel DB + user, sets new password)${RESET}"
    sep; ask "Choose:"; read -r DO

    # ── Helper: try mysql as root with or without password ────
    _mysql_root() {
        # Try passwordless first (unix socket auth), then prompt
        mysql -u root "$@" 2>/dev/null && return 0
        if [ -z "$MYSQL_ROOT_PW" ]; then
            ask "MariaDB root password (leave blank if none):"; read -r -s MYSQL_ROOT_PW; echo ""
        fi
        mysql -u root -p"${MYSQL_ROOT_PW}" "$@" 2>/dev/null
    }

    case "$DO" in
        1)
            _mysql_root -e "SELECT table_name AS 'Table',
                ROUND(((data_length+index_length)/1024/1024),2) AS 'Size_MB'
                FROM information_schema.TABLES WHERE table_schema='panel'
                ORDER BY (data_length+index_length) DESC;" 2>/dev/null \
                || err "Cannot connect to MariaDB. Try option [6] to reset credentials."
            ;;
        2)
            mysqlcheck --optimize panel 2>/dev/null && ok "Tables optimized" \
                || err "Cannot connect. Try option [6]."
            ;;
        3)
            ask "Host IP (e.g. 127.0.0.1):"; read -r NI
            ask "Username:"; read -r NU
            ask "Password:"; read -r -s NP; echo ""
            _mysql_root <<NODEEOF
CREATE USER IF NOT EXISTS '${NU}'@'${NI}' IDENTIFIED BY '${NP}';
GRANT ALL PRIVILEGES ON *.* TO '${NU}'@'${NI}' WITH GRANT OPTION;
FLUSH PRIVILEGES;
NODEEOF
            ok "Node DB user: ${NU}@${NI}  |  Add in Panel → Admin → Database Hosts"
            ;;
        4)
            ask "New pterodactyl DB password:"; read -r -s NDBP; echo ""
            _mysql_root <<DBPEOF
ALTER USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${NDBP}';
FLUSH PRIVILEGES;
DBPEOF
            if [ $? -eq 0 ]; then
                sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${NDBP}/" \
                    /var/www/pterodactyl/.env 2>/dev/null
                cd /var/www/pterodactyl &>/dev/null && php artisan config:clear &>/dev/null
                ok "DB password updated in MariaDB + .env"
            else
                err "Failed to update password in MariaDB"
            fi
            ;;
        5)
            info "Opening MariaDB shell (type 'exit' to leave)"
            mysql -u root 2>/dev/null || {
                ask "Root password:"; read -r -s RPW; echo ""
                mysql -u root -p"$RPW"
            }
            ;;

        # ── [6] NUKE & RECREATE ───────────────────────────────
        6)
            show_banner
            echo -e "${BOLD}${RED}  💣 NUKE & RECREATE DATABASE${RESET}"
            sep
            echo ""
            warn "This will:"
            warn "  • Drop the 'panel' database and all its data"
            warn "  • Drop the 'pterodactyl'@'127.0.0.1' user"
            warn "  • Recreate them with a NEW password you set"
            warn "  • Update .env + re-run panel migrations"
            echo ""
            ask "Type NUKE-DATABASE to confirm:"; read -r NUKECONF
            [[ "$NUKECONF" != "NUKE-DATABASE" ]] && { info "Aborted."; pause; return; }

            # ── Step 1: Stop panel services while we work
            step "Stopping Panel Services"
            systemctl stop pteroq 2>/dev/null && ok "pteroq stopped" || true
            php artisan down &>/dev/null 2>/dev/null || true

            # ── Step 2: Get new password
            step "New Database Password"
            local NEW_DB_PASS NEW_DB_PASS2
            while true; do
                ask "New DB password (min 8 chars):"; read -r -s NEW_DB_PASS; echo ""
                ask "Confirm password:";              read -r -s NEW_DB_PASS2; echo ""
                [ "$NEW_DB_PASS" = "$NEW_DB_PASS2" ] && [ ${#NEW_DB_PASS} -ge 8 ] && break
                err "Passwords don't match or too short. Try again."
            done

            # ── Step 3: Try to connect as root (reset root if needed)
            step "MariaDB Root Access"
            local ROOT_CMD="mysql -u root"

            # Test passwordless first
            if ! mysql -u root -e "SELECT 1;" &>/dev/null 2>&1; then
                warn "Root has a password or socket auth failed."
                warn "Trying to reset MariaDB root via system (safe mode)..."
                echo ""
                echo -e "  ${WHITE}Choose how to get root access:${RESET}"
                echo -e "  ${GREEN}[A]${RESET} I know the root password — enter it"
                echo -e "  ${GREEN}[B]${RESET} I don't know it — reset root via system"
                ask "Choose [A/B]:"; read -r ROOT_METHOD

                if [[ "$ROOT_METHOD" =~ ^[Aa]$ ]]; then
                    ask "MariaDB root password:"; read -r -s ROOT_PW; echo ""
                    mysql -u root -p"$ROOT_PW" -e "SELECT 1;" &>/dev/null 2>&1 || {
                        err "Wrong root password. Cannot continue."
                        pause; return 1
                    }
                    ROOT_CMD="mysql -u root -p${ROOT_PW}"
                    ok "Root access confirmed"
                else
                    info "Stopping MariaDB to reset root password..."
                    systemctl stop mariadb
                    # Start in skip-grant-tables mode
                    mysqld_safe --skip-grant-tables &>/dev/null &
                    sleep 5
                    # Reset root password
                    local NEW_ROOT_PW
                    NEW_ROOT_PW=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20)
                    mysql -u root --connect-expired-password <<RESETROOT
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_ROOT_PW}';
FLUSH PRIVILEGES;
RESETROOT
                    # Kill safe mode, restart properly
                    kill %1 2>/dev/null; sleep 2
                    systemctl start mariadb; sleep 3
                    ROOT_CMD="mysql -u root -p${NEW_ROOT_PW}"
                    ok "Root password reset to: ${BOLD}${GREEN}${NEW_ROOT_PW}${RESET}"
                    warn "Save this root password!"
                fi
            else
                ok "Root access via Unix socket (no password needed)"
            fi

            # ── Step 4: Nuke and recreate
            step "Dropping Old Database & User"
            $ROOT_CMD 2>/dev/null <<NUKEEOF
DROP DATABASE IF EXISTS panel;
DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';
DROP USER IF EXISTS 'pterodactyl'@'localhost';
FLUSH PRIVILEGES;
NUKEEOF
            ok "Old database + user dropped"

            step "Creating Fresh Database & User"
            $ROOT_CMD 2>/dev/null <<CREATEEOF
CREATE DATABASE panel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${NEW_DB_PASS}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
FLUSH PRIVILEGES;
CREATEEOF
            ok "Fresh 'panel' database + 'pterodactyl'@'127.0.0.1' created"

            # ── Step 5: Update .env
            step "Updating .env"
            if [ -f /var/www/pterodactyl/.env ]; then
                sed -i "s/^DB_HOST=.*/DB_HOST=127.0.0.1/"           /var/www/pterodactyl/.env
                sed -i "s/^DB_PORT=.*/DB_PORT=3306/"                /var/www/pterodactyl/.env
                sed -i "s/^DB_DATABASE=.*/DB_DATABASE=panel/"       /var/www/pterodactyl/.env
                sed -i "s/^DB_USERNAME=.*/DB_USERNAME=pterodactyl/"  /var/www/pterodactyl/.env
                sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${NEW_DB_PASS}/" /var/www/pterodactyl/.env
                ok ".env updated with new credentials"
            else
                err ".env not found — panel may not be installed"
                pause; return 1
            fi

            # ── Step 6: Re-run migrations + seed
            step "Running Migrations + Seed"
            cd /var/www/pterodactyl || { err "Panel dir not found"; pause; return 1; }
            php artisan config:clear &>/dev/null
            info "Running migrations (may take ~30s)..."
            php artisan migrate --seed --force
            ok "Migrations + seed complete"

            # ── Step 7: Re-create admin user
            step "Admin User"
            echo ""
            ask "Admin username:";           read -r NEW_ADMIN_USER
            ask "Admin password:";           read -r -s NEW_ADMIN_PASS;  echo ""
            ask "Admin email:";              read -r NEW_ADMIN_EMAIL
            php artisan p:user:make \
                --email="$NEW_ADMIN_EMAIL" \
                --username="$NEW_ADMIN_USER" \
                --name-first="ZynrCloud" \
                --name-last="Admin" \
                --password="$NEW_ADMIN_PASS" \
                --admin=1 &>/dev/null
            ok "Admin '${NEW_ADMIN_USER}' created"

            # ── Step 8: Restart services
            step "Restarting Services"
            chown -R www-data:www-data /var/www/pterodactyl
            php artisan up &>/dev/null
            systemctl start pteroq 2>/dev/null && ok "pteroq started"
            systemctl restart nginx  2>/dev/null && ok "nginx restarted"

            # ── Summary
            echo ""
            echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════╗${RESET}"
            echo -e "${BOLD}${CYAN}  ║      🎉  DATABASE REBUILT SUCCESSFULLY  🎉           ║${RESET}"
            echo -e "${BOLD}${CYAN}  ╠══════════════════════════════════════════════════════╣${RESET}"
            echo -e "${BOLD}${WHITE}  ║  DB Host     : 127.0.0.1                            ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║  DB Name     : panel                                ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║  DB User     : pterodactyl                          ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║  DB Password : ${NEW_DB_PASS}${RESET}"
            echo -e "${BOLD}${WHITE}  ║  Admin User  : ${NEW_ADMIN_USER}${RESET}"
            echo -e "${BOLD}${CYAN}  ║  ★  ZynrCloud — https://zynrcloud.com               ║${RESET}"
            echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════╝${RESET}"
            ;;

        *) warn "Invalid option" ;;
    esac
    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ═══════════════════════════════════════════════════════════════
#  [20]  EMERGENCY FULL RECOVERY
#  Installs missing services, fixes nginx, fixes PHP-FPM,
#  fixes Redis + MariaDB, rebuilds panel — one tap fix-all
# ═══════════════════════════════════════════════════════════════
emergency_502_fix() {
    show_banner
    echo -e "${BOLD}${RED}  🚨 EMERGENCY FULL RECOVERY${RESET}"
    sep
    require_root

    echo -e "  ${DIM}Auto-detecting what's broken and fixing everything...${RESET}"
    echo ""

    # ── Step 1: System update + detect OS ──────────────────────
    step "System Check"
    detect_os 2>/dev/null || { OS="ubuntu"; OS_VERSION="22.04"; }
    ok "OS: ${OS} ${OS_VERSION}"
    info "Running apt-get update..."
    DEBIAN_FRONTEND=noninteractive apt-get update -y &>/dev/null
    ok "Package lists updated"

    # ── Step 2: PHP — install if missing, detect version ───────
    step "PHP-FPM"
    local PHP_VER="" PHP_SOCK=""

    # Check what's already installed/running
    for v in 8.3 8.2 8.1; do
        if dpkg -l "php${v}-fpm" 2>/dev/null | grep -q "^ii" || \
           systemctl is-active --quiet "php${v}-fpm" 2>/dev/null || \
           [ -S "/run/php/php${v}-fpm.sock" ]; then
            PHP_VER="$v"; PHP_SOCK="/run/php/php${v}-fpm.sock"
            ok "Found installed PHP-FPM: ${PHP_VER}"
            break
        fi
    done

    # If nothing found — install PHP 8.2
    if [ -z "$PHP_VER" ]; then
        warn "PHP-FPM not installed — installing PHP 8.2..."
        # Add PHP repo
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            gnupg2 ca-certificates lsb-release apt-transport-https \
            software-properties-common &>/dev/null

        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php &>/dev/null 2>&1 || {
            curl -fsSL https://packages.sury.org/php/apt.gpg \
                | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg 2>/dev/null
            echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" \
                > /etc/apt/sources.list.d/sury-php.list
        }
        DEBIAN_FRONTEND=noninteractive apt-get update -y &>/dev/null

        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            php8.2 php8.2-cli php8.2-gd php8.2-mysql php8.2-pdo \
            php8.2-mbstring php8.2-tokenizer php8.2-bcmath php8.2-xml \
            php8.2-fpm php8.2-curl php8.2-zip &>/dev/null

        PHP_VER="8.2"; PHP_SOCK="/run/php/php8.2-fpm.sock"
        ok "PHP 8.2 installed"
    fi

    # Start PHP-FPM
    systemctl enable "php${PHP_VER}-fpm" &>/dev/null
    systemctl restart "php${PHP_VER}-fpm" &>/dev/null
    sleep 3

    if [ -S "$PHP_SOCK" ]; then
        ok "PHP ${PHP_VER}-FPM running — socket: ${PHP_SOCK}"
    else
        err "PHP-FPM socket still missing after restart!"
        info "Logs: journalctl -u php${PHP_VER}-fpm -n 30"
        # Try to get logs automatically
        journalctl -u "php${PHP_VER}-fpm" --no-pager -n 10 --no-hostname 2>/dev/null
    fi

    # ── Step 3: Redis — install if missing ─────────────────────
    step "Redis"
    if ! dpkg -l redis-server 2>/dev/null | grep -q "^ii"; then
        warn "Redis not installed — installing..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y redis-server &>/dev/null
        ok "Redis installed"
    fi
    _fix_redis
    if systemctl is-active --quiet redis-server; then
        ok "Redis running"
    else
        warn "Redis failed — will switch Panel to file cache"
        [ -f /var/www/pterodactyl/.env ] && {
            sed -i 's/^CACHE_DRIVER=.*/CACHE_DRIVER=file/'     /var/www/pterodactyl/.env
            sed -i 's/^SESSION_DRIVER=.*/SESSION_DRIVER=file/' /var/www/pterodactyl/.env
            sed -i 's/^QUEUE_DRIVER=.*/QUEUE_DRIVER=sync/'     /var/www/pterodactyl/.env
            ok ".env switched to file drivers"
        }
    fi

    # ── Step 4: MariaDB — install if missing ───────────────────
    step "MariaDB"
    systemctl stop mariadb mysql 2>/dev/null || true
    pkill -9 mysqld mariadbd mysqld_safe 2>/dev/null || true
    kill -9 $(lsof -t -i:3306 2>/dev/null) 2>/dev/null || true
    if dpkg -l mariadb-server 2>/dev/null | grep -qE '^(iF|iU|rH|rc)'; then
        warn "Broken MariaDB found — force-removing..."
        DEBIAN_FRONTEND=noninteractive dpkg --remove --force-remove-reinstreq             mariadb-server mariadb-server-core mariadb-client mariadb-client-core             mariadb-common mysql-common 2>/dev/null || true
        DEBIAN_FRONTEND=noninteractive apt-get purge -y mariadb-server mariadb-server-core             mariadb-client mariadb-common mysql-common &>/dev/null || true
        rm -rf /etc/mysql /var/lib/mysql /var/run/mysqld /var/log/mysql
        apt-get autoremove -y &>/dev/null
    fi
    # Fix broken PHP too if present
    if dpkg -l php8.2-common 2>/dev/null | grep -qE '^(iF|iU|rH|rc)'; then
        warn "Broken PHP 8.2 found — purging..."
        DEBIAN_FRONTEND=noninteractive apt-get purge -y "php8.2*" 2>/dev/null || true
        rm -rf /etc/php/8.2 /usr/lib/php/20220829
    fi
    mkdir -p /etc/php/8.2/mods-available /etc/php/8.2/cli/conf.d /etc/php/8.2/fpm/conf.d
    dpkg --configure -a 2>/dev/null || true
    apt-get install -f -y &>/dev/null || true
    if ! dpkg -l mariadb-server 2>/dev/null | grep -q "^ii"; then
        warn "MariaDB not installed — installing..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server &>/dev/null
        ok "MariaDB installed"
    fi
    systemctl enable mariadb &>/dev/null
    systemctl start  mariadb &>/dev/null
    sleep 3
    if systemctl is-active --quiet mariadb; then
        ok "MariaDB running"
        # Check if panel DB exists
        if ! mysql -u root -e "USE panel;" &>/dev/null 2>&1; then
            warn "Panel database missing! Run option [19] → [6] Nuke & Recreate Database"
        else
            ok "Panel database exists"
        fi
    else
        err "MariaDB failed to start!"
        journalctl -u mariadb --no-pager -n 10 --no-hostname 2>/dev/null
    fi

    # ── Step 5: Nginx — install + clean rewrite ────────────────
    step "Nginx"
    if ! dpkg -l nginx 2>/dev/null | grep -q "^ii"; then
        warn "Nginx not installed — installing..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
            nginx certbot python3-certbot-nginx &>/dev/null
        ok "Nginx installed"
    fi

    # Nuke every conflicting config
    systemctl stop nginx 2>/dev/null
    rm -f /etc/nginx/sites-enabled/*
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    rm -f /etc/nginx/sites-available/default

    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    cat > /etc/nginx/sites-available/pterodactyl.conf << EMERGENCYNGINX
# ZynrCloud — Pterodactyl Panel (Emergency Recovery Config v4.4.14)
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.access.log;
    error_log  /var/log/nginx/pterodactyl.error.log error;

    client_max_body_size 100m;
    client_body_timeout  120s;
    sendfile off;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size = 100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }
    location ~ /\.ht { deny all; }
}
EMERGENCYNGINX

    ln -sf /etc/nginx/sites-available/pterodactyl.conf \
           /etc/nginx/sites-enabled/pterodactyl.conf

    if nginx -t &>/dev/null; then
        systemctl enable nginx &>/dev/null
        systemctl start nginx
        sleep 1
        systemctl is-active --quiet nginx \
            && ok "Nginx running — config uses PHP ${PHP_VER} socket" \
            || { err "Nginx failed to start:"; journalctl -u nginx --no-pager -n 15 --no-hostname; }
    else
        err "Nginx config still invalid:"; nginx -t 2>&1
    fi

    # ── Step 6: Panel permissions ──────────────────────────────
    step "Panel Permissions"
    if [ -d /var/www/pterodactyl ]; then
        chown -R www-data:www-data /var/www/pterodactyl
        chmod -R 755 /var/www/pterodactyl/storage \
                     /var/www/pterodactyl/bootstrap/cache 2>/dev/null
        ok "Permissions fixed"
    else
        err "Panel not found at /var/www/pterodactyl — use option [1] to install"
    fi

    # ── Step 7: Fix .env + clear caches ───────────────────────
    if [ -f /var/www/pterodactyl/artisan ]; then
        step "Panel Config + Caches"
        cd /var/www/pterodactyl || true
        # Fix DB_HOST localhost → 127.0.0.1 (prevents socket vs TCP mismatch)
        sed -i 's/^DB_HOST=localhost$/DB_HOST=127.0.0.1/' .env 2>/dev/null
        php artisan config:clear 2>/dev/null && ok "Config cache cleared"
        php artisan view:clear   2>/dev/null && ok "View cache cleared"
        php artisan route:clear  2>/dev/null && ok "Route cache cleared"
        php artisan up           2>/dev/null || true
    fi

    # ── Step 8: pteroq queue worker ───────────────────────────
    step "Queue Worker (pteroq)"
    if [ -f /etc/systemd/system/pteroq.service ]; then
        systemctl daemon-reload
        systemctl enable pteroq &>/dev/null
        systemctl restart pteroq 2>/dev/null
        sleep 2
        systemctl is-active --quiet pteroq \
            && ok "pteroq running" \
            || warn "pteroq failed — check: journalctl -u pteroq -n 20"
    else
        warn "pteroq service not installed — panel may not be set up yet"
    fi

    # ── Step 9: Cloudflared ────────────────────────────────────
    if systemctl list-unit-files cloudflared.service &>/dev/null 2>&1; then
        step "Cloudflared"
        systemctl restart cloudflared 2>/dev/null \
            && ok "cloudflared restarted" \
            || warn "cloudflared not active"
    fi

    # ── Final summary ───────────────────────────────────────────
    echo ""
    hsep
    echo -e "${BOLD}${WHITE}  ── Final Service Status ──────────────────────────────${RESET}"
    for svc in nginx "php${PHP_VER}-fpm" mariadb redis-server pteroq; do
        _st=$(systemctl is-active "$svc" 2>/dev/null || echo "not-found")
        [ "$_st" = "active" ] \
            && printf "  ${GREEN}[✔]${RESET} %-24s ${GREEN}%s${RESET}\n" "$svc" "$_st" \
            || printf "  ${RED}[✘]${RESET} %-24s ${RED}%s${RESET}\n" "$svc" "$_st"
    done
    hsep
    echo ""

    # Tell user what to do next if DB is still broken
    if ! systemctl is-active --quiet mariadb || \
       ! mysql -u root -e "USE panel;" &>/dev/null 2>&1; then
        echo -e "  ${BOLD}${YELLOW}  ── NEXT STEPS NEEDED ──────────────────────────────────${RESET}"
        echo -e "  ${YELLOW}  MariaDB or panel database still needs attention:${RESET}"
        echo -e "  ${WHITE}  → Run option [19] Database Manager → [6] Nuke & Recreate${RESET}"
        echo -e "  ${WHITE}  → Or run option [10] Fix Panel → [9] Fix DB Credentials${RESET}"
        echo ""
    else
        ok "All core services running — panel should be accessible!"
    fi

    warn "If still getting 502: curl -v http://localhost"
    warn "Nginx logs: journalctl -u nginx -n 30"
    sep
    echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"
    pause
}



# ═══════════════════════════════════════════════════════════════
#  [21]  ZYNRCLOUD THEMES & BLUEPRINTS INSTALLER
# ═══════════════════════════════════════════════════════════════

ZYNR_BP_LIST=(
    "nebula.blueprint|🎨 Nebula Theme (official Pterodactyl theme by prplwtf)"
    "euphoriatheme.blueprint|🎨 Euphoria Theme"
    "BetterAdmin.blueprint|🛠️  Better Admin panel UI"
    "blueannoucements.blueprint|📢 Blue Announcements"
    "bluetables.blueprint|📋 Blue Tables UI"
    "consolelogs.blueprint|🖥️  Console Logs viewer"
    "dbedit.blueprint|🗄️  Database Editor"
    "huxregister.blueprint|📝 Hux Register (custom register page)"
    "laravellogs.blueprint|📄 Laravel Logs viewer"
    "loader.blueprint|⚡ Loader (loading screen)"
    "lyrdyannounce.blueprint|📣 Lyrdy Announcements"
    "mclogs.blueprint|📜 MCLogs (upload logs to mclo.gs)"
    "mcmods.blueprint|🧩 Minecraft Mods manager"
    "mcplugins.blueprint|🔌 Minecraft Plugins manager"
    "mctools.blueprint|🛠️  Minecraft Tools"
    "minecrafticonchanger.blueprint|🖼️  Minecraft Icon Changer"
    "minecraftplayermanager.blueprint|👥 Minecraft Player Manager"
    "minecraftpluginmanager.blueprint|🔧 Minecraft Plugin Manager"
    "nightadmin.blueprint|🌙 Night Admin dark UI"
    "playerlisting.blueprint|📋 Player Listing"
    "resourcemanager.blueprint|📦 Resource Manager"
    "sagaautosuspension.blueprint|⏸️  Saga Auto Suspension"
    "sagaminecraftmodpackinstaller.blueprint|📦 Saga Modpack Installer"
    "sagaminecraftplayermanager.blueprint|👥 Saga Player Manager"
    "sagaminecraftplugininstaller.blueprint|🔌 Saga Plugin Installer"
    "sagarustplugininstaller.blueprint|🦀 Saga Rust Plugin Installer"
    "sagaserverpropertiesui.blueprint|⚙️  Saga Server Properties UI"
    "sagaserversorter.blueprint|🗂️  Saga Server Sorter"
    "serverbackgrounds.blueprint|🖼️  Server Backgrounds"
    "serverimporter.blueprint|📥 Server Importer"
    "serversplitter.blueprint|✂️  Server Splitter"
    "simplefavicons.blueprint|⭐ Simple Favicons"
    "snowflakes.blueprint|❄️  Snowflakes (seasonal UI effect)"
    "startupchanger.blueprint|🚀 Startup Changer"
    "subdomainmanager.blueprint|🌐 Subdomain Manager"
    "subdomains.blueprint|🔗 Subdomains"
    "versionchanger.blueprint|🔄 Version Changer"
    "votifiertester.blueprint|🗳️  Votifier Tester"
)

themes_blueprints_menu() {
    show_banner
    echo -e "${BOLD}${MAGENTA}  🎨 ZYNRCLOUD THEMES & BLUEPRINTS INSTALLER${RESET}"
    sep
    require_root

    if ! command -v blueprint &>/dev/null && \
       [ ! -f /var/www/pterodactyl/blueprint.sh ]; then
        err "Blueprint Framework is not installed!"
        warn "Run option [12] → [1] to install Blueprint Framework first."
        pause; return
    fi

    echo -e "  ${DIM}Nebula theme + 38 blueprints from the ZynrCloud collection${RESET}"
    sep
    echo -e "  ${GREEN}[1]${RESET}  🎨  Install Nebula Theme only"
    echo -e "  ${GREEN}[2]${RESET}  📦  Install FULL Blueprint Pack  ${DIM}(all 38 — takes ~20 min)${RESET}"
    echo -e "  ${GREEN}[3]${RESET}  🔧  Pick & install specific blueprints"
    echo -e "  ${GREEN}[4]${RESET}  📋  List all 38 blueprints in the pack"
    echo -e "  ${GREEN}[5]${RESET}  📤  How to upload blueprint files to this server"
    sep
    ask "Choose:"; read -r TBM_OPT

    # ── GitHub config (update these with your repo) ───────────
    local GH_USER="HemanRathore"
    local GH_REPO="pterodactyl-installer"
    local GH_RAW="https://raw.githubusercontent.com/${GH_USER}/${GH_REPO}/main"
    local GH_REL="https://github.com/${GH_USER}/${GH_REPO}/releases/latest/download"

    # ── Helper: find Blueprint.rar on server ──────────────────
    _find_bp_pack() {
        for p in /root/Blueprint.rar /root/blueprints/Blueprint.rar \
                 /tmp/Blueprint.rar /var/www/pterodactyl/Blueprint.rar; do
            [ -f "$p" ] && echo "$p" && return 0
        done
        return 1
    }

    # ── Helper: find nebula.blueprint on server ───────────────
    _find_nebula() {
        for p in /root/nebula.blueprint /root/blueprints/nebula.blueprint \
                 /tmp/nebula.blueprint /var/www/pterodactyl/nebula.blueprint; do
            [ -f "$p" ] && echo "$p" && return 0
        done
        return 1
    }

    # ── Helper: download a blueprint from GitHub releases ────
    _download_bp_from_gh() {
        local BPFILE="$1"
        local DEST="/tmp/${BPFILE}"
        info "Downloading ${BPFILE} from GitHub..." >&2
        local URLS=(
            "${GH_RAW}/blueprints/${BPFILE}"
            "${GH_REL}/blueprints/${BPFILE}"
            "${GH_REL}/${BPFILE}"
        )
        for URL in "${URLS[@]}"; do
            if command -v curl &>/dev/null; then
                curl -fsSL --retry 2 -o "$DEST" "$URL" 2>/dev/null
            else
                wget -q --tries=2 -O "$DEST" "$URL" 2>/dev/null
            fi
            [ -s "$DEST" ] && { echo "$DEST"; return 0; }
            rm -f "$DEST"
        done
        return 1
    }

    # Download Blueprint.rar from GitHub if not found locally
    _ensure_bp_pack() {
        local RAR; RAR=$(_find_bp_pack)
        [ -n "$RAR" ] && { echo "$RAR"; return 0; }
        info "Blueprint.rar not found locally — downloading from GitHub..." >&2
        local DEST="/root/Blueprint.rar"
        local URLS=(
            "${GH_RAW}/blueprints/Blueprint.rar"
            "${GH_REL}/Blueprint.rar"
        )
        for URL in "${URLS[@]}"; do
            if command -v curl &>/dev/null; then
                curl -fsSL --retry 2 -o "$DEST" "$URL" 2>/dev/null
            else
                wget -q --tries=2 -O "$DEST" "$URL" 2>/dev/null
            fi
            [ -s "$DEST" ] && { ok "Downloaded Blueprint.rar" >&2; echo "$DEST"; return 0; }
            rm -f "$DEST"
        done
        err "Could not download Blueprint.rar from GitHub" >&2
        return 1
    }

    # ── Helper: ensure unrar is installed ────────────────────
    _ensure_unrar() {
        command -v unrar &>/dev/null && return 0
        info "Installing unrar..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y unrar &>/dev/null || \
        DEBIAN_FRONTEND=noninteractive apt-get install -y unrar-free &>/dev/null
        command -v unrar &>/dev/null
    }

    # ── Helper: extract one blueprint from RAR and install ───
    _install_one_from_rar() {
        local RAR="$1" BPFILE="$2"
        local TMPDIR="/tmp/bpinst_$$"
        mkdir -p "$TMPDIR"
        unrar e -y "$RAR" "Blueprint/${BPFILE}" "$TMPDIR/" &>/dev/null
        if [ ! -f "${TMPDIR}/${BPFILE}" ]; then
            err "Could not extract ${BPFILE} from RAR"
            rm -rf "$TMPDIR"; return 1
        fi
        cp "${TMPDIR}/${BPFILE}" /var/www/pterodactyl/
        rm -rf "$TMPDIR"
        cd /var/www/pterodactyl || return 1
        blueprint -install "$BPFILE"
        local RC=$?
        rm -f "/var/www/pterodactyl/${BPFILE}" 2>/dev/null
        return $RC
    }

    case "$TBM_OPT" in

        # ── [1] Nebula theme only ─────────────────────────────
        1)
            step "Install Nebula Theme"
            echo ""
            local NEBULA
            NEBULA=$(_find_nebula)

            # If not found standalone, try extracting from RAR
            if [ -z "$NEBULA" ]; then
                local RAR; RAR=$(_find_bp_pack)
                if [ -n "$RAR" ]; then
                    _ensure_unrar || { err "Cannot install unrar"; pause; return; }
                    info "Extracting nebula.blueprint from Blueprint.rar..."
                    mkdir -p /tmp/neb_$$
                    unrar e -y "$RAR" "Blueprint/nebula.blueprint" /tmp/neb_$$/ &>/dev/null
                    [ -f "/tmp/neb_$$/nebula.blueprint" ] && NEBULA="/tmp/neb_$$/nebula.blueprint"
                fi
            fi

            # Final fallback: try GitHub releases
            if [ -z "$NEBULA" ]; then
                info "Not found locally — trying GitHub releases..."
                NEBULA=$(_download_bp_from_gh "nebula.blueprint")
            fi

            if [ -z "$NEBULA" ]; then
                err "nebula.blueprint not found on this server!"
                echo ""
                echo -e "  ${WHITE}Upload it first — from your PC run:${RESET}"
                echo -e "  ${CYAN}  scp nebula.blueprint root@$(hostname -I | awk '{print $1}'):/root/${RESET}"
                echo -e "  ${DIM}  Or upload Blueprint.rar (full pack) to /root/ instead${RESET}"
                pause; return
            fi
            ok "Found: ${NEBULA}"

            cp "$NEBULA" /var/www/pterodactyl/nebula.blueprint
            rm -rf /tmp/neb_$$ 2>/dev/null
            cd /var/www/pterodactyl || { err "Panel not found"; pause; return; }

            info "Installing Nebula theme (takes ~2 min — panel rebuilds assets)..."
            blueprint -install nebula.blueprint
            local RC=$?
            rm -f /var/www/pterodactyl/nebula.blueprint 2>/dev/null

            if [ $RC -eq 0 ]; then
                ok "Nebula theme installed!"
                echo ""
                echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════╗${RESET}"
                echo -e "${BOLD}${CYAN}  ║  🎨  NEBULA THEME INSTALLED SUCCESSFULLY             ║${RESET}"
                echo -e "${BOLD}${CYAN}  ╠══════════════════════════════════════════════════════╣${RESET}"
                echo -e "${BOLD}${WHITE}  ║  Panel → Admin → Nebula  to configure it             ║${RESET}"
                echo -e "${BOLD}${WHITE}  ║  Users: Profile → Theme → select Nebula              ║${RESET}"
                echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════╝${RESET}"
            else
                err "Nebula install failed (exit ${RC})"
            fi
            ;;

        # ── [2] Full pack ─────────────────────────────────────
        2)
            step "Install Full Blueprint Pack (38 extensions)"
            _ensure_unrar || { err "unrar required but could not install"; pause; return; }

            local RAR; RAR=$(_ensure_bp_pack)
            if [ -z "$RAR" ]; then
                warn "Blueprint.rar unavailable — downloading blueprints individually from GitHub"
            else
                ok "Using pack: ${RAR}"
            fi

            warn "Installing all 38 blueprints — panel rebuilds assets each time"
            warn "This will take approximately 15-25 minutes"
            ask "Continue? [y/n]:"; read -r FC
            [[ "$FC" =~ ^[Yy]$ ]] || { info "Aborted."; pause; return; }

            local PASS=0 FAIL=0 FAIL_LIST="" IDX=0 TOTAL=${#ZYNR_BP_LIST[@]}
            for ENTRY in "${ZYNR_BP_LIST[@]}"; do
                IDX=$((IDX+1))
                local BPF; BPF=$(echo "$ENTRY" | cut -d'|' -f1)
                local BPD; BPD=$(echo "$ENTRY" | cut -d'|' -f2)
                echo ""
                echo -e "  ${BOLD}[${IDX}/${TOTAL}]${RESET} ${BPD}"
                local INSTALL_RC=1
                if [ -n "$RAR" ]; then
                    _install_one_from_rar "$RAR" "$BPF"
                    INSTALL_RC=$?
                else
                    # No RAR — download from GitHub releases
                    local DLPATH; DLPATH=$(_download_bp_from_gh "$BPF")
                    if [ -n "$DLPATH" ]; then
                        cp "$DLPATH" /var/www/pterodactyl/
                        cd /var/www/pterodactyl || continue
                        blueprint -install "$BPF"
                        INSTALL_RC=$?
                        rm -f "/var/www/pterodactyl/${BPF}" "$DLPATH" 2>/dev/null
                    else
                        err "Could not download ${BPF} from GitHub"
                        INSTALL_RC=1
                    fi
                fi
                if [ $INSTALL_RC -eq 0 ]; then
                    ok "${BPF} installed"; PASS=$((PASS+1))
                else
                    err "${BPF} failed"; FAIL=$((FAIL+1)); FAIL_LIST="${FAIL_LIST}\n    ✘ ${BPF}"
                fi
            done

            echo ""
            echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════╗${RESET}"
            echo -e "${BOLD}${CYAN}  ║      📦  Full Blueprint Pack — Done                  ║${RESET}"
            echo -e "${BOLD}${CYAN}  ╠══════════════════════════════════════════════════════╣${RESET}"
            echo -e "${BOLD}${GREEN}  ║  ✔  Installed : ${PASS} / ${TOTAL}${RESET}"
            [ $FAIL -gt 0 ] && echo -e "${BOLD}${RED}  ║  ✘  Failed    : ${FAIL}${RESET}" && \
                echo -e "${RED}${FAIL_LIST}${RESET}"
            echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════╝${RESET}"
            ;;

        # ── [3] Pick specific ─────────────────────────────────
        3)
            step "Pick Blueprints to Install"
            local RAR; RAR=$(_ensure_bp_pack)
            if [ -n "$RAR" ]; then
                _ensure_unrar || RAR=""
            fi
            [ -z "$RAR" ] && warn "No Blueprint.rar — will download each blueprint individually from GitHub"

            echo ""
            echo -e "  ${WHITE}Available blueprints:${RESET}"
            echo ""
            local IDX=0
            for ENTRY in "${ZYNR_BP_LIST[@]}"; do
                IDX=$((IDX+1))
                local BPF; BPF=$(echo "$ENTRY" | cut -d'|' -f1)
                local BPD; BPD=$(echo "$ENTRY" | cut -d'|' -f2)
                printf "  ${GREEN}[%2d]${RESET}  %-42s %s\n" "$IDX" "$BPF" "$BPD"
            done
            echo ""
            ask "Enter numbers to install (space-separated, e.g. 1 3 7):"; read -r PICKS

            for NUM in $PICKS; do
                if [[ "$NUM" =~ ^[0-9]+$ ]] && \
                   [ "$NUM" -ge 1 ] && [ "$NUM" -le "${#ZYNR_BP_LIST[@]}" ]; then
                    local ENTRY="${ZYNR_BP_LIST[$((NUM-1))]}"
                    local BPF; BPF=$(echo "$ENTRY" | cut -d'|' -f1)
                    local BPD; BPD=$(echo "$ENTRY" | cut -d'|' -f2)
                    echo ""; info "Installing: ${BPD}"
                    local INSTALL_RC=1
                    if [ -n "$RAR" ]; then
                        _install_one_from_rar "$RAR" "$BPF"
                        INSTALL_RC=$?
                    else
                        local DLPATH; DLPATH=$(_download_bp_from_gh "$BPF")
                        if [ -n "$DLPATH" ]; then
                            cp "$DLPATH" /var/www/pterodactyl/
                            cd /var/www/pterodactyl || continue
                            blueprint -install "$BPF"
                            INSTALL_RC=$?
                            rm -f "/var/www/pterodactyl/${BPF}" "$DLPATH" 2>/dev/null
                        fi
                    fi
                    [ $INSTALL_RC -eq 0 ] && ok "Done: ${BPF}" || err "Failed: ${BPF}"
                else
                    warn "Invalid: ${NUM} — skipped"
                fi
            done
            ok "Selection complete!"
            ;;

        # ── [4] List ──────────────────────────────────────────
        4)
            echo ""
            echo -e "  ${BOLD}${WHITE}ZynrCloud Blueprint Pack — ${#ZYNR_BP_LIST[@]} extensions:${RESET}"
            sep
            local IDX=0
            for ENTRY in "${ZYNR_BP_LIST[@]}"; do
                IDX=$((IDX+1))
                local BPF; BPF=$(echo "$ENTRY" | cut -d'|' -f1)
                local BPD; BPD=$(echo "$ENTRY" | cut -d'|' -f2)
                printf "  ${GREEN}%2d.${RESET}  %-42s ${DIM}%s${RESET}\n" "$IDX" "$BPF" "$BPD"
            done
            sep
            ;;

        # ── [5] Upload help ───────────────────────────────────
        5)
            local MY_IP; MY_IP=$(hostname -I | awk '{print $1}')
            echo ""
            echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
            echo -e "${BOLD}${CYAN}  ║  📤  HOW TO UPLOAD FILES TO YOUR SERVER                     ║${RESET}"
            echo -e "${BOLD}${CYAN}  ╠══════════════════════════════════════════════════════════════╣${RESET}"
            echo -e "${BOLD}${WHITE}  ║  Run these from your LOCAL PC terminal / PowerShell:         ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║                                                              ║${RESET}"
            echo -e "${BOLD}${CYAN}  ║  Upload full pack (recommended):                            ║${RESET}"
            echo -e "${BOLD}${GREEN}  ║    scp Blueprint.rar root@${MY_IP}:/root/             ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║                                                              ║${RESET}"
            echo -e "${BOLD}${CYAN}  ║  Upload Nebula theme only:                                  ║${RESET}"
            echo -e "${BOLD}${GREEN}  ║    scp nebula.blueprint root@${MY_IP}:/root/         ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║                                                              ║${RESET}"
            echo -e "${BOLD}${CYAN}  ║  Using FileZilla / WinSCP:                                  ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║    Host: ${MY_IP}  →  upload to /root/              ║${RESET}"
            echo -e "${BOLD}${WHITE}  ║    Then re-run this menu option [1] or [2]                  ║${RESET}"
            echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════════════╝${RESET}"
            ;;

        *) warn "Invalid option" ;;
    esac

    sep; echo -e "${CYAN}  ★ ZynrCloud — https://zynrcloud.com${RESET}"; pause
}

# ── Redis auto-fix helper ────────────────────────────────────
_fix_redis() {
    if [ ! -f /etc/redis/redis.conf ]; then
        warn "Redis config missing — reinstalling redis-server..."
        DEBIAN_FRONTEND=noninteractive apt-get purge -y redis-server redis-tools &>/dev/null
        DEBIAN_FRONTEND=noninteractive apt-get install -y redis-server &>/dev/null
        ok "Redis reinstalled"
    fi
    systemctl enable redis-server &>/dev/null
    systemctl start  redis-server &>/dev/null
    sleep 2
}

pause() {
    echo ""; ask "Press Enter to return to main menu..."; read -r; main_menu
}

# ═══════════════════════════════════════════════════════════════
#   ENTRY POINT
# ═══════════════════════════════════════════════════════════════
main_menu
