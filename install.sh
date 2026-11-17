#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo "     Feeds2ebook Automated Installer     "
echo "========================================="

# 1. Clean Up Legacy Lowercase Installation & Shortcuts
OLD_INSTALL_DIR="$HOME/.feed2ebook"
if [ -d "$OLD_INSTALL_DIR" ]; then
    echo "[+] Removing legacy directory: $OLD_INSTALL_DIR"
    rm -rf "$OLD_INSTALL_DIR"
fi

rm -f "${PREFIX:-/data/data/com.termux/files/usr}/bin/feed2ebook" "$HOME/.local/bin/feed2ebook" 2>/dev/null || true
if [ -f "/usr/local/bin/feed2ebook" ]; then
    if [ -w "/usr/local/bin" ]; then
        rm -f "/usr/local/bin/feed2ebook"
    elif command -v sudo >/dev/null 2>&1; then
        sudo rm -f "/usr/local/bin/feed2ebook"
    fi
fi

# 2. Detect Environment & Install System Packages
if [ -d "/data/data/com.termux/files/usr" ]; then
    echo "[+] Termux environment detected."
    termux-setup-storage || true
    pkg update -y
    pkg install python libxml2 libxslt python-lxml clang make git curl libjpeg-turbo zlib python-pillow -y
else
    echo "[+] Standard Linux environment detected."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y
        sudo apt-get install -y python3 python3-pip python3-lxml python3-pil libxml2-dev libxslt1-dev git curl libjpeg-dev zlib1g-dev
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y python3 python3-pip python3-lxml python3-pillow libxml2-devel libxslt-devel git curl libjpeg-turbo-devel zlib-devel
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm python python-pip python-lxml python-pillow libxml2 libxslt git curl libjpeg-turbo zlib
    else
        echo "[!] Unsupported package manager. Ensure python3, pip, curl, and libxml2/libxslt are installed."
    fi
fi

# 3. Install Python Dependencies
echo ""
echo "[+] Installing required Python libraries..."
if command -v python3 >/dev/null 2>&1; then
    PY_CMD="python3"
else
    PY_CMD="python"
fi

"$PY_CMD" -m pip install --upgrade requests beautifulsoup4 readability-lxml feedparser ebooklib pillow --break-system-packages 2>/dev/null || \
"$PY_CMD" -m pip install --upgrade requests beautifulsoup4 readability-lxml feedparser ebooklib pillow

# 4. Setup Directory & Fetch Latest Script directly via GitHub API (Bypasses CDN Cache)
INSTALL_DIR="$HOME/.Feeds2ebook"
mkdir -p "$INSTALL_DIR"

PYTHON_SCRIPT_OLD="$INSTALL_DIR/Feed2ebook.py"
PYTHON_SCRIPT="$INSTALL_DIR/Feeds2ebook.py"

echo ""
echo "[+] Cleaning up previous script version..."
rm -f "$PYTHON_SCRIPT_OLD" "$PYTHON_SCRIPT"

echo "[+] Downloading fresh Feeds2ebook.py from GitHub API..."
curl -sSLf -H "Accept: application/vnd.github.v3.raw" \
    "https://api.github.com/repos/ajay9634/Feeds2ebook/contents/Feeds2ebook.py" \
    -o "$PYTHON_SCRIPT"

chmod +x "$PYTHON_SCRIPT"

# 5. Create / Update Terminal Shortcut Command
echo ""
echo "[+] Updating shortcut command 'Feeds2ebook'..."

if [ -d "/data/data/com.termux/files/usr/bin" ]; then
    BIN_DIR="/data/data/com.termux/files/usr/bin"
elif [ -w "/usr/local/bin" ] || command -v sudo >/dev/null 2>&1; then
    BIN_DIR="/usr/local/bin"
else
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
fi

WRAPPER_PATH="$BIN_DIR/Feeds2ebook"

WRAPPER_CONTENT='#!/usr/bin/env bash
INSTALL_DIR="$HOME/.Feeds2ebook"
PY_SCRIPT="$INSTALL_DIR/Feeds2ebook.py"

if [ "${1:-}" = "--update" ] || [ "${1:-}" = "-u" ]; then
    echo "[+] Force updating Feeds2ebook from GitHub..."
    curl -sSLf -H "Accept: application/vnd.github.v3.raw" \
        "https://api.github.com/repos/ajay9634/Feeds2ebook/contents/Feeds2ebook.py" \
        -o "$PY_SCRIPT.tmp" && mv "$PY_SCRIPT.tmp" "$PY_SCRIPT"
    chmod +x "$PY_SCRIPT"
    echo "[+] Update complete!"
    exit 0
fi

if command -v python3 >/dev/null 2>&1; then
    python3 "$PY_SCRIPT" "$@"
else
    python "$PY_SCRIPT" "$@"
fi'

if [ -w "$BIN_DIR" ]; then
    printf '%s\n' "$WRAPPER_CONTENT" > "$WRAPPER_PATH"
    chmod +x "$WRAPPER_PATH"
else
    printf '%s\n' "$WRAPPER_CONTENT" | sudo tee "$WRAPPER_PATH" > /dev/null
    sudo chmod +x "$WRAPPER_PATH"
fi

echo ""
echo "========================================="
echo "   [+] Installation Completed!           "
echo "   Launch the app anytime by typing:     "
echo "        Feeds2ebook                      "
echo "   Update anytime with:                  "
echo "        Feeds2ebook --update             "
echo "========================================="
