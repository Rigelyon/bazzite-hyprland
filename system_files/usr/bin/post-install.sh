#!/bin/bash

STATE_DIR="$HOME/.config/bazzite-hyprland"
STATE_FILE="$STATE_DIR/last_run_version"

CURRENT_VERSION=$(grep -E '^IMAGE_VERSION=' /usr/lib/os-release | cut -d '=' -f 2 | tr -d '"')

mkdir -p "$STATE_DIR"

if [[ -f "$STATE_FILE" ]]; then
    LAST_RUN_VERSION=$(cat "$STATE_FILE")
    if [[ "$CURRENT_VERSION" == "$LAST_RUN_VERSION" ]]; then
        exit 0
    fi
fi

if [[ "$1" != "--in-terminal" ]]; then
    sleep 3

    exec kitty -- "$0" --in-terminal
    exit 0
fi

echo "Running post-install script for version $CURRENT_VERSION..."

bash <(curl -sSL https://raw.githubusercontent.com/SpotX-Official/SpotX-Bash/main/spotx.sh)

curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | tee /etc/yum.repos.d/cloudflare-warp.repo
rpm-ostree install cloudflare-warp
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/cloudflare-warp.repo

if command -v notify-send &> /dev/null; then
    notify-send "System Updated" "Post-install script running for version $CURRENT_VERSION"
fi

echo "$CURRENT_VERSION" > "$STATE_FILE"

echo "Post-install script completed. Press Enter to close this terminal."
read -p ""
