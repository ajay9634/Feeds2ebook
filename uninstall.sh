#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo "    Feeds2ebook Automated Uninstaller     "
echo "========================================="
echo ""

# 1. Remove Application Directories (checking both lowercase and capitalized variants)
INSTALL_DIRS=(
    "$HOME/.feed2ebook"
    "$HOME/.Feeds2ebook"
)

for dir in "${INSTALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "[+] Removing installation directory: $dir"
        rm -rf "$dir"
    else
        echo "[-] Directory not found (skipped): $dir"
    fi
done

echo ""

# 2. Remove Terminal Shortcut Wrappers
BIN_NAMES=("feed2ebook" "Feeds2ebook")

# Check for Termux environment first
if [ -d "/data/data/com.termux/files/usr/bin" ]; then
    for name in "${BIN_NAMES[@]}"; do
        WRAPPER_PATH="/data/data/com.termux/files/usr/bin/$name"
        if [ -f "$WRAPPER_PATH" ]; then
            echo "[+] Removing Termux shortcut: $name"
            rm -f "$WRAPPER_PATH"
        fi
    done
else
    # Standard Linux / Desktop / Proot environments
    POSSIBLE_BINS=(
        "$HOME/.local/bin"
        "/usr/local/bin"
        "/usr/bin"
    )

    for bin_dir in "${POSSIBLE_BINS[@]}"; do
        for name in "${BIN_NAMES[@]}"; do
            WRAPPER_PATH="$bin_dir/$name"
            if [ -f "$WRAPPER_PATH" ]; then
                echo "[+] Removing binary shortcut: $WRAPPER_PATH"
                if [ -w "$bin_dir" ]; then
                    rm -f "$WRAPPER_PATH"
                elif command -v sudo >/dev/null 2>&1; then
                    sudo rm -f "$WRAPPER_PATH"
                else
                    echo "[!] Warning: No write permission for $bin_dir and sudo is unavailable. Skipping $WRAPPER_PATH."
                fi
            fi
        done
    done
fi

echo ""
echo "========================================="
echo "   [+] Uninstallation Complete!          "
echo "========================================="
