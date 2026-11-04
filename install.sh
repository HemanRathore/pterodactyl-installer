#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
# ============================================================
#  ZynrCloud — Pterodactyl Master Command
#  One-tap installer — run as root:
#
#    bash <(curl -fsSL https://raw.githubusercontent.com/HemanRathore/pterodactyl-installer/main/install.sh)
#
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; BOLD='\033[1m'; RESET='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
cat << 'EOF'
  ███████╗██╗   ██╗███╗   ██╗██████╗  ██████╗██╗      ██████╗ ██╗   ██╗██████╗
  ╚══███╔╝╚██╗ ██╔╝████╗  ██║██╔══██╗██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
    ███╔╝  ╚████╔╝ ██╔██╗ ██║██████╔╝██║     ██║     ██║   ██║██║   ██║██║  ██║
   ███╔╝    ╚██╔╝  ██║╚██╗██║██╔══██╗██║     ██║     ██║   ██║██║   ██║██║  ██║
  ███████╗   ██║   ██║ ╚████║██║  ██║╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
  ╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝
EOF
echo -e "${RESET}"
echo -e "${BOLD}${WHITE}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${WHITE}  ║   ⚡  ZynrCloud — Pterodactyl Master Command Installer  ⚡   ║${RESET}"
echo -e "${BOLD}${CYAN}  ║   🌐  https://zynrcloud.com  •  discord.gg/zynrcloud         ║${RESET}"
echo -e "${BOLD}${WHITE}  ╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# ── Root check ───────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}  [✘] This installer must be run as root.${RESET}"
    echo -e "${YELLOW}  [!] Run: sudo bash <(curl -fsSL https://raw.githubusercontent.com/HemanRathore/pterodactyl-installer/main/install.sh)${RESET}"
    exit 1
fi

# ── OS check ─────────────────────────────────────────────────
if [ ! -f /etc/os-release ]; then
    echo -e "${RED}  [✘] Cannot detect OS. /etc/os-release not found.${RESET}"
    exit 1
fi
. /etc/os-release
echo -e "${CYAN}  [•] Detected OS: ${ID} ${VERSION_ID:-}${RESET}"

case "${ID}:${VERSION_ID:-}" in
    ubuntu:22.04|ubuntu:24.04|ubuntu:26.04|debian:12|debian:13)
        ;;
    *)
        echo -e "${RED}  [✘] Unsupported operating system.${RESET}"
        echo -e "${YELLOW}  [!] Supported systems: Ubuntu 22.04/24.04/26.04 and Debian 12/13.${RESET}"
        exit 1
        ;;
esac

# ── Dependency check ─────────────────────────────────────────
echo -e "${CYAN}  [•] Checking dependencies...${RESET}"
if ! DEBIAN_FRONTEND=noninteractive apt-get update -y &>/dev/null; then
    echo -e "${RED}  [✘] apt-get update failed. Check repository configuration and network access.${RESET}"
    exit 1
fi
if ! DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget bash ca-certificates &>/dev/null; then
    echo -e "${RED}  [✘] Required bootstrap packages could not be installed.${RESET}"
    exit 1
fi

# ── Download master script ───────────────────────────────────
SCRIPT_URL="https://raw.githubusercontent.com/HemanRathore/pterodactyl-installer/main/zynrcloud-pterodactyl.sh"
SCRIPT_PATH="/root/zynrcloud-pterodactyl.sh"

echo -e "${CYAN}  [•] Downloading ZynrCloud Master Command...${RESET}"

TEMP_PATH="${SCRIPT_PATH}.download.$$"
rm -f "$TEMP_PATH"
if command -v curl &>/dev/null; then
    curl -fsSL --retry 3 --retry-all-errors -o "$TEMP_PATH" "$SCRIPT_URL"
elif command -v wget &>/dev/null; then
    wget -q --tries=3 -O "$TEMP_PATH" "$SCRIPT_URL"
else
    echo -e "${RED}  [✘] Neither curl nor wget found. Cannot download script.${RESET}"
    exit 1
fi

if [ ! -s "$TEMP_PATH" ]; then
    echo -e "${RED}  [✘] Download failed — check your internet connection.${RESET}"
    echo -e "${YELLOW}  [!] URL: ${SCRIPT_URL}${RESET}"
    exit 1
fi

mv -f "$TEMP_PATH" "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"
echo -e "${GREEN}  [✔] Downloaded to ${SCRIPT_PATH}${RESET}"
echo ""
echo -e "${BOLD}${WHITE}  Starting ZynrCloud Pterodactyl Master Command...${RESET}"
echo ""
sleep 1

exec bash "$SCRIPT_PATH"
