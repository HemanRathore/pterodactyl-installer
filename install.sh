#!/bin/bash
# ============================================================
#  MoradoSolution — Pterodactyl Master Command v4.5.0
#  One-tap installer — run as root:
#
#    bash <(curl -fsSL https://raw.githubusercontent.com/HemanRathore/pterodactyl-installer/main/install.sh)
#
#  GitHub Raw is used as the primary source.
#  GitHub API is used automatically as a fallback when
#  raw.githubusercontent.com is unavailable.
#
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

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
    echo -e "${YELLOW}  [!] Run as root or use sudo.${RESET}"
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

# ── Download configuration ───────────────────────────────────
SCRIPT_NAME="moradosolution-pterodactyl.sh"

SCRIPT_PATH="/root/${SCRIPT_NAME}"
TMP_SCRIPT_PATH="/root/.${SCRIPT_NAME}.tmp"

RAW_URL="https://raw.githubusercontent.com/HemanRathore/pterodactyl-installer/main/${SCRIPT_NAME}"

API_URL="https://api.github.com/repos/HemanRathore/pterodactyl-installer/contents/${SCRIPT_NAME}?ref=main"

echo ""
echo -e "${CYAN}  [•] Downloading MoradoSolution Master Command...${RESET}"
echo ""

# Always start clean.
rm -f "$TMP_SCRIPT_PATH"

DOWNLOAD_OK=false
DOWNLOAD_METHOD=""

# ── Method 1: GitHub Raw ─────────────────────────────────────
echo -e "${CYAN}  [•] Trying GitHub Raw...${RESET}"

if command -v curl &>/dev/null; then
    if curl -4 -fsSL \
        --retry 2 \
        --retry-delay 2 \
        --connect-timeout 10 \
        --max-time 90 \
        -o "$TMP_SCRIPT_PATH" \
        "$RAW_URL"; then

        if [ -s "$TMP_SCRIPT_PATH" ] && \
           head -n 1 "$TMP_SCRIPT_PATH" | grep -q '^#!/bin/bash$'; then

            DOWNLOAD_OK=true
            DOWNLOAD_METHOD="GitHub Raw"

        else
            rm -f "$TMP_SCRIPT_PATH"
        fi
    fi
fi

# ── Method 2: GitHub API fallback ────────────────────────────
if [ "$DOWNLOAD_OK" = false ]; then

    echo -e "${YELLOW}  [!] GitHub Raw unavailable.${RESET}"
    echo -e "${CYAN}  [•] Trying GitHub API fallback...${RESET}"

    rm -f "$TMP_SCRIPT_PATH"

    if command -v curl &>/dev/null; then
        if curl -4 -fsSL \
            --retry 2 \
            --retry-delay 2 \
            --connect-timeout 10 \
            --max-time 90 \
            -H "Accept: application/vnd.github.raw" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            -o "$TMP_SCRIPT_PATH" \
            "$API_URL"; then

            if [ -s "$TMP_SCRIPT_PATH" ] && \
               head -n 1 "$TMP_SCRIPT_PATH" | grep -q '^#!/bin/bash$'; then

                DOWNLOAD_OK=true
                DOWNLOAD_METHOD="GitHub API"

            else
                rm -f "$TMP_SCRIPT_PATH"
            fi
        fi
    fi
fi

# ── Download failure ─────────────────────────────────────────
if [ "$DOWNLOAD_OK" = false ]; then

    rm -f "$TMP_SCRIPT_PATH"

    echo ""
    echo -e "${RED}  [✘] Failed to download the MoradoSolution Master Command.${RESET}"
    echo ""
    echo -e "${YELLOW}  Both download methods failed:${RESET}"
    echo -e "${WHITE}  • GitHub Raw${RESET}"
    echo -e "${WHITE}  • GitHub API${RESET}"
    echo ""
    echo -e "${YELLOW}  Check your server's outbound HTTPS connectivity.${RESET}"
    echo ""
    echo -e "${WHITE}  Repository:${RESET}"
    echo -e "${CYAN}  https://github.com/HemanRathore/pterodactyl-installer${RESET}"
    echo ""

    exit 1
fi

# ── Final validation ─────────────────────────────────────────
if [ ! -s "$TMP_SCRIPT_PATH" ]; then
    rm -f "$TMP_SCRIPT_PATH"

    echo -e "${RED}  [✘] Downloaded file is empty.${RESET}"
    exit 1
fi

if ! head -n 1 "$TMP_SCRIPT_PATH" | grep -q '^#!/bin/bash$'; then
    rm -f "$TMP_SCRIPT_PATH"

    echo -e "${RED}  [✘] Downloaded master script failed validation.${RESET}"
    echo -e "${YELLOW}  [!] The downloaded content was not recognized as a Bash script.${RESET}"
    exit 1
fi

# ── Install downloaded script ────────────────────────────────
mv -f "$TMP_SCRIPT_PATH" "$SCRIPT_PATH"

chmod +x "$SCRIPT_PATH"

echo ""
echo -e "${GREEN}  [✔] Master Command downloaded successfully.${RESET}"
echo -e "${GREEN}  [✔] Source: ${DOWNLOAD_METHOD}${RESET}"
echo -e "${GREEN}  [✔] Installed: ${SCRIPT_PATH}${RESET}"

echo ""
echo -e "${BOLD}${WHITE}  Starting MoradoSolution Pterodactyl Master Command...${RESET}"
echo ""

sleep 1

exec bash "$SCRIPT_PATH"
