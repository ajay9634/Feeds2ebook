#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo "    Feeds2ebook Quick Script Installer   "
echo "========================================="

# 0. Pre-flight Check for Required Tools
if ! command -v curl >/dev/null 2>&1; then
    echo "[!] Error: 'curl' is required but not installed."
    exit 1
fi

if command -v python3 >/dev/null 2>&1; then
    PY_CMD="python3"
elif command -v python >/dev/null 2>&1; then
    PY_CMD="python"
else
    echo "[!] Error: Python 3 is not installed. Please run the full installer first."
    exit 1
fi

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

# 2. Setup Directory & Fetch Latest Script Atomically via GitHub API
INSTALL_DIR="$HOME/.Feeds2ebook"
mkdir -p "$INSTALL_DIR"

PYTHON_SCRIPT_OLD="$INSTALL_DIR/Feed2ebook.py"
PYTHON_SCRIPT="$INSTALL_DIR/Feeds2ebook.py"

rm -f "$PYTHON_SCRIPT_OLD"

echo "[+] Downloading fresh Feeds2ebook.py from GitHub API..."
curl -sSLf -H "Accept: application/vnd.github.v3.raw" \
    "https://api.github.com/repos/ajay9634/Feeds2ebook/contents/Feeds2ebook.py" \
    -o "$PYTHON_SCRIPT.tmp"

mv "$PYTHON_SCRIPT.tmp" "$PYTHON_SCRIPT"
chmod +x "$PYTHON_SCRIPT"

# 3. Create / Update Terminal Shortcut Command
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

# 4. Verify Python Libraries Exist (Non-blocking warning)
if ! "$PY_CMD" -c "import requests, bs4, readability, feedparser, ebooklib, PIL" >/dev/null 2>&1; then
    echo ""
    echo "[!] Warning: One or more Python dependencies are missing."
    echo "    Run your full automated installer if Feeds2ebook fails to start."
fi

echo ""
echo "========================================="
echo "   [+] Installation Completed!           "
echo "   Launch the app anytime by typing:     "
echo "        Feeds2ebook                      "
echo "   Update anytime with:                  "
echo "        Feeds2ebook --update             "
echo "========================================="
