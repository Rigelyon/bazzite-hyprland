#!/bin/bash

set -ouex pipefail

export PIP_ROOT_USER_ACTION=ignore

### 1. Enable Repositories (COPR & External)
echo "Configuring External Repositories..."

# Cloudflare WARP Repo & Key
# Mengikuti instruksi update key 2025/2026
# rpm --import https://pkg.cloudflareclient.com/pubkey.gpg
# curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | tee /etc/yum.repos.d/cloudflare-warp.repo

# echo ":: Importing GPG Keys..."
# rpm --import https://pkg.cloudflareclient.com/pubkey.gpg
# rpm --import https://packages.microsoft.com/keys/microsoft.asc
# curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | tee /etc/yum.repos.d/cloudflare-warp.repo
# sed -i 's/$releasever/8/g' /etc/yum.repos.d/cloudflare-warp.repo

# Enable COPRs
dnf5 -y copr enable solopasha/hyprland
dnf5 -y copr enable atim/starship
dnf5 -y copr enable brycensranch/gpu-screen-recorder-git
dnf5 -y copr enable lihaohong/yazi
dnf5 -y copr enable dejan/lazygit

# Add Visual Studio Code Repository
cat <<EOF > /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# Add Antigravity Repository
tee /etc/yum.repos.d/antigravity.repo << EOL
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
EOL

dnf5 makecache

### 2. Define Package Lists

# Core System & Shell Utilities
SYSTEM_PACKAGES=(
	# cloudflare-warp
    bat
    btop
    fastfetch
    fd-find
    fzf
    gh
    micro
    ripgrep
    starship
    tmux
    trash-cli
    wget
    zoxide
    zsh
    unzip
    7zip
    inotify-tools
    jq
    socat
    file
    glib2
    libnotify
    accountsservice
    brightnessctl
    ddcutil
    lm_sensors
    bluez
    bluez-tools
    stow
)

# Desktop Environment & Utils
DESKTOP_PACKAGES=(
    hyprland
    hyprpicker
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    wl-clipboard
    cliphist
    foot
    fuzzel
    pavucontrol
    wireplumber
    pipewire-utils
    grim
    slurp
    swappy
    gpu-screen-recorder-ui
    wlogout
)

# File Management & GUI Apps
APP_PACKAGES=(
    thunar
    thunar-archive-plugin
    file-roller
    yazi
    lazygit
    imv
    neovim
    python3-neovim
    libqalculate
    libqalculate-devel
    ImageMagick
    code
    antigravity
)

FONT_PACKAGES=(
    fontawesome-fonts-all
    google-noto-color-emoji-fonts
    google-noto-emoji-fonts
)

DEV_PACKAGES=(
    git
    sassc
    xdg-utils
    R-rsvg
)

### 3. Install Packages
rpm-ostree install \
    "${SYSTEM_PACKAGES[@]}" \
    "${DESKTOP_PACKAGES[@]}" \
    "${APP_PACKAGES[@]}" \
    "${FONT_PACKAGES[@]}" \
    "${DEV_PACKAGES[@]}"

### 4. Manual Packages Install
echo "Installing eza"
curl -L "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp
mv /tmp/eza /usr/bin/eza
chmod +x /usr/bin/eza
ln -sf /usr/bin/eza /usr/bin/exa

### 5. Post-Install Configuration

echo ":: configuring sassc link..."
ln -sf /usr/bin/sassc /usr/bin/sass


echo ":: installing Nerd Fonts (JetBrainsMono)..."
FONT_DIR="/usr/share/fonts/JetBrainsMonoNerdFont"
mkdir -p "$FONT_DIR"
wget -P "$FONT_DIR" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o "$FONT_DIR/JetBrainsMono.zip" -d "$FONT_DIR"
rm "$FONT_DIR/JetBrainsMono.zip"

echo ":: updating font cache..."
fc-cache -fv

chmod -R a+r /usr/lib/python*/site-packages/

### 5. Cleanup
dnf5 -y copr disable solopasha/hyprland
dnf5 -y copr disable atim/starship
dnf5 -y copr disable brycensranch/gpu-screen-recorder-git
dnf5 -y copr disable lihaohong/yazi
dnf5 -y copr disable dejan/lazygit

rpm-ostree cleanup -m

### 6. Systemd Units
systemctl enable podman.socket

echo "Build script completed successfully."
