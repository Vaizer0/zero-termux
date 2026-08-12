#!/data/data/com.termux/files/usr/bin/bash
#
# mkwebapp – Create a Termux .deb package that launches a given URL
# Usage: mkwebapp --url <URL> --name <AppName> [options]

set -euo pipefail

# ========== ANSI Color Codes ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
RESET='\033[0m'

# ========== Banner ==========
echo -e "${CYAN}${BOLD}"
cat << "EOF"
                                                   
        .                 .                        
        |                 |                        
.--.--. |.-..  .    ._.-. |.-.  .-.  .,-. .,-. .--.
|  |  | |-.' \  \  / (.-' |   )(   ) |   )|   )`--.
'  '  `-'  `- `' `'   `--''`-'  `-'`-|`-' |`-' `--'
                                     |    |        
                                     '    '        
EOF
echo -e "${RESET}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"

# ========== Defaults ==========
DEFAULT_MAINTAINER="Alienkrishn [Anon4You]"
PREFIX="/data/data/com.termux/files/usr"

usage() {
    echo -e "\n${YELLOW}Usage:${RESET} $0 --url <URL> --name <APPNAME> [options]"
    echo -e "\n${BOLD}Required:${RESET}"
    echo "  --url <URL>       The website URL to open"
    echo "  --name <APPNAME>  Name of the application"
    echo -e "\n${BOLD}Options:${RESET}"
    echo "  --icon <FILE>     Path to a PNG icon file"
    echo "  --browser <CMD>   Browser command (e.g., firefox, chromium)"
    echo "  --maintainer <STR> Override default maintainer"
    echo "  --help            Show this help"
    echo ""
    exit 0
}

# ========== Parse Arguments ==========
while [[ $# -gt 0 ]]; do
    case $1 in
        --url) URL="$2"; shift 2 ;;
        --name) APPNAME="$2"; shift 2 ;;
        --icon) ICON_SOURCE="$2"; shift 2 ;;
        --browser) BROWSER_CMD="$2"; shift 2 ;;
        --maintainer) MAINTAINER="$2"; shift 2 ;;
        --help) usage ;;
        *) echo -e "${RED}Unknown option: $1${RESET}"; usage ;;
    esac
done

# Validate required
if [[ -z "${URL:-}" || -z "${APPNAME:-}" ]]; then
    echo -e "${RED}Error: --url and --name are required.${RESET}"
    usage
fi

# Set defaults for optional args
MAINTAINER="${MAINTAINER:-$DEFAULT_MAINTAINER}"
BROWSER_CMD="${BROWSER_CMD:-}"

# Sanitize app name
SAFE_NAME=$(echo "$APPNAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
PACKAGE_NAME="web-${SAFE_NAME}"

# ========== Build Environment ==========
echo -e "${BLUE}→ Preparing package:${RESET} ${BOLD}${PACKAGE_NAME}${RESET}"

BUILDDIR=$(mktemp -d)
trap "rm -rf $BUILDDIR" EXIT

# Create DEBIAN control file
mkdir -p "$BUILDDIR/DEBIAN"
cat > "$BUILDDIR/DEBIAN/control" <<EOF
Package: $PACKAGE_NAME
Version: 1.0.0
Architecture: all
Maintainer: $MAINTAINER
Depends: termux-tools
Recommends: firefox | chromium | www-browser
Description: Web app launcher for $APPNAME
 This package installs a launcher that opens $URL
 in your default web browser. Ideal for use with
 Termux:X11 and XFCE4 desktop.
EOF

# Minimal postrm
cat > "$BUILDDIR/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
# Purge hook (empty)
EOF
chmod 755 "$BUILDDIR/DEBIAN/postrm"
chmod 0755 "$BUILDDIR/DEBIAN"

# Create directory structure
mkdir -p "$BUILDDIR/$PREFIX/bin"
mkdir -p "$BUILDDIR/$PREFIX/share/applications"
mkdir -p "$BUILDDIR/$PREFIX/share/pixmap"

# ========== Launcher Script ==========
LAUNCHER="$BUILDDIR/$PREFIX/bin/$SAFE_NAME"
cat > "$LAUNCHER" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
URL="$URL"
APPNAME="$APPNAME"
BROWSER_CMD="$BROWSER_CMD"

# Try to detect an installed browser
if [ -n "\$BROWSER_CMD" ]; then
    \$BROWSER_CMD "\$URL"
else
    if command -v firefox >/dev/null 2>&1; then
        firefox --new-window "\$URL"
    elif command -v chromium >/dev/null 2>&1; then
        chromium --new-window "\$URL"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "\$URL"
    else
        echo "No suitable browser found. Please install firefox or chromium."
        exit 1
    fi
fi
EOF
chmod 755 "$LAUNCHER"
echo -e "${GREEN}  ✓ Launcher script created${RESET}"

# ========== .desktop File ==========
DESKTOP="$BUILDDIR/$PREFIX/share/applications/$SAFE_NAME.desktop"
cat > "$DESKTOP" <<EOF
[Desktop Entry]
Version=1.0
Name=$APPNAME
Comment=Opens $URL
Exec=$PREFIX/bin/$SAFE_NAME
Icon=$SAFE_NAME
Terminal=false
Type=Application
Categories=Network;
EOF
echo -e "${GREEN}  ✓ Desktop entry created${RESET}"

# ========== Icon Handling ==========
ICON_DEST="$BUILDDIR/$PREFIX/share/pixmap/$SAFE_NAME.png"

if [[ -n "${ICON_SOURCE:-}" && -f "$ICON_SOURCE" ]]; then
    cp "$ICON_SOURCE" "$ICON_DEST"
    echo -e "${GREEN}  ✓ Using user-provided icon${RESET}"
else
    echo -e "${YELLOW}  → No icon provided. Attempting to fetch favicon...${RESET}"
    DOMAIN=$(echo "$URL" | awk -F[/:] '{print $4}')
    [[ -z "$DOMAIN" ]] && DOMAIN=$(echo "$URL" | awk -F/ '{print $1}')
    FAVICON_URL="https://www.google.com/s2/favicons?domain=$DOMAIN&sz=64"
    TEMP_ICON=$(mktemp)
    if curl -L -f -s -o "$TEMP_ICON" "$FAVICON_URL" && file "$TEMP_ICON" | grep -qiE 'png|image'; then
        cp "$TEMP_ICON" "$ICON_DEST"
        echo -e "${GREEN}  ✓ Favicon downloaded and installed${RESET}"
    else
        echo -e "${RED}  ✗ Favicon download failed. No icon included.${RESET}"
    fi
    rm -f "$TEMP_ICON"
fi

# ========== Build Package ==========
DEB_FILE="${PACKAGE_NAME}_1.0.0_all.deb"
echo -e "${BLUE}→ Building package...${RESET}"
dpkg-deb --build "$BUILDDIR" "$DEB_FILE" >/dev/null
echo -e "${GREEN}✅ Package built successfully: ${BOLD}${DEB_FILE}${RESET}"
