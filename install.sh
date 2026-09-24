#!/bin/bash
# ============================================================
#  MoradoSolution — Pterodactyl Master Command v4.5.0
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
  ███╗   ███╗ █████╗ ██████╗  █████╗ ██████╗  █████╗  ██████╗ █████╗ ██╗     ██╗   ██╗████████╗██╗ █████╗ ███╗  ██╗
  ████╗ ████║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██║     ██║   ██║╚══██╔══╝██║██╔══██╗████╗ ██║
  ██╔████╔██║██║  ██║██████╔╝███████║██║  ██║██║  ██║╚█████╗ ██║  ██║██║     ██║   ██║   ██║   ██║██║  ██║██╔██╗██║
  ██║╚██╔╝██║██║  ██║██╔══██╗██╔══██║██║  ██║██║  ██║ ╚═══██╗██║  ██║██║     ██║   ██║   ██║   ██║██║  ██║██║╚████║
  ██║ ╚═╝ ██║╚█████╔╝██║  ██║██║  ██║██████╔╝╚█████╔╝██████╔╝╚█████╔╝███████╗╚██████╔╝   ██║   ██║╚█████╔╝██║ ╚███║
  ╚═╝     ╚═╝ ╚════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚════╝ ╚═════╝  ╚════╝ ╚══════╝ ╚═════╝    ╚═╝   ╚═╝ ╚════╝ ╚═╝  ╚══╝
EOF
echo -e "${RESET}"
echo -e "${BOLD}${WHITE}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${WHITE}  ║   ⚡  MoradoSolution — Pterodactyl Master Command v4.5.0 Installer  ⚡   ║${RESET}"
echo -e "${BOLD}${CYAN}  ║   🌐  https://moradosolution.com  •  discord.gg/moradosolution         ║${RESET}"
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
echo -e "${CYAN}  [•] Detected OS: ${ID} ${VERSION_ID:-} (${VERSION_CODENAME:-unknown})${RESET}"

case "${ID}:${VERSION_ID}" in
    ubuntu:22.04|ubuntu:24.04|ubuntu:26.04)
        ;;
    debian:11|debian:12|debian:13)
        ;;
    *)
        echo -e "${RED}  [✘] Unsupported OS for this installer: ${ID} ${VERSION_ID:-}${RESET}"
        echo -e "${YELLOW}  [!] Supported: Ubuntu 22.04/24.04/26.04 and Debian 11/12/13.${RESET}"
        exit 1
        ;;
esac

# ── Dependency check ─────────────────────────────────────────
echo -e "${CYAN}  [•] Checking dependencies...${RESET}"
if ! DEBIAN_FRONTEND=noninteractive apt-get update -y &>/dev/null; then
    echo -e "${RED}  [✘] apt-get update failed. Fix APT sources before continuing.${RESET}"
    exit 1
fi
if ! DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget bash &>/dev/null; then
    echo -e "${RED}  [✘] Failed to install downloader dependencies.${RESET}"
    exit 1
fi

# ── Download master script ───────────────────────────────────
SCRIPT_URL="https://raw.githubusercontent.com/HemanRathore/pterodactyl-installer/main/moradosolution-pterodactyl.sh"
SCRIPT_PATH="/root/moradosolution-pterodactyl.sh"
TMP_SCRIPT_PATH="/root/.moradosolution-pterodactyl.sh.tmp"

echo -e "${CYAN}  [•] Downloading MoradoSolution Master Command...${RESET}"

if command -v curl &>/dev/null; then
    curl -fsSL --retry 3 -o "$TMP_SCRIPT_PATH" "$SCRIPT_URL" && mv -f "$TMP_SCRIPT_PATH" "$SCRIPT_PATH"
elif command -v wget &>/dev/null; then
    wget -q --tries=3 -O "$TMP_SCRIPT_PATH" "$SCRIPT_URL" && mv -f "$TMP_SCRIPT_PATH" "$SCRIPT_PATH"
else
    echo -e "${RED}  [✘] Neither curl nor wget found. Cannot download script.${RESET}"
    exit 1
fi

if [ ! -s "$SCRIPT_PATH" ]; then
    echo -e "${RED}  [✘] Download failed — check your internet connection.${RESET}"
    echo -e "${YELLOW}  [!] URL: ${SCRIPT_URL}${RESET}"
    exit 1
fi

if ! head -n 1 "$SCRIPT_PATH" | grep -q '^#!/bin/bash$'; then
    echo -e "${RED}  [✘] Downloaded master script failed validation.${RESET}"
    exit 1
fi

chmod +x "$SCRIPT_PATH"
echo -e "${GREEN}  [✔] Downloaded to ${SCRIPT_PATH}${RESET}"
echo ""
echo -e "${BOLD}${WHITE}  Starting MoradoSolution Pterodactyl Master Command...${RESET}"
echo ""
sleep 1

exec bash "$SCRIPT_PATH"
