#!/bin/bash

set -ouex pipefail

# --- 1. Environment & Repository Configuration ---
export PIP_ROOT_USER_ACTION=ignore

COPR_REPOS=(
    "sdegler/hyprland"
    "lionheartp/Hyprland"
    "errornointernet/quickshell"
    "atim/starship"
    "brycensranch/gpu-screen-recorder-git"
    "lihaohong/yazi"
    "dejan/lazygit"
    "atim/lazydocker"
    "komapro/lazyssh"
    "jkinred/satty"
)

echo ":: Configuring External Repositories..."

for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr enable "$repo"
done


curl -fsSl https://pkg.cloudflareclient.com/cloudflare-warp-ascii.repo | tee /etc/yum.repos.d/cloudflare-warp.repo

cat <<EOF > /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

# cat <<EOF > /etc/yum.repos.d/antigravity.repo
# [antigravity-rpm]
# name=Antigravity RPM Repository
# baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
# enabled=1
# gpgcheck=0
# EOF

cat <<'EOF' > /etc/yum.repos.d/wayscriber.repo
[wayscriber]
name=Wayscriber Repo
baseurl=https://wayscriber.com/rpm
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://wayscriber.com/rpm/RPM-GPG-KEY-wayscriber.asc
EOF

cat << 'EOF' > /etc/yum.repos.d/zerotier.repo
[zerotier]
name=ZeroTier, Inc. RPM Release Repository
baseurl=https://download.zerotier.com/redhat/fc/$releasever
enabled=1
gpgcheck=1
gpgkey=https://download.zerotier.com/contact@zerotier.com.gpg
EOF

dnf5 makecache

# --- 2. Package List Definitions ---

SYSTEM_UTILS=(
    bat
    btop
    fastfetch
    fd-find
    fzf
    gh
    git-credential-oauth
    micro
    ripgrep
    starship
    trash-cli
    wget
    zoxide
    zsh
    unzip
    7zip
    jq
    file
    lsd
    stow
    bluez
    bluez-tools
    brightnessctl
    ddcutil
    lm_sensors
    inotify-tools
    socat
    glib2
    polkit
    accountsservice
    libnotify
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    hyprpicker
    wlsunset
    hyprland-guiutils
    hyprshot
    wl-clipboard
    cliphist
    wev
    wf-recorder
    grim
    slurp
    swww
    wireplumber
    pipewire-utils
    cloudflare-warp
    tesseract
    tesseract-langpack-*
    satty
    cava
    evolution-data-server
    wayscriber
    wayscriber-configurator
    s-tui
    playerctl
    zbar
    zerotier-one
    cronie
    at
)

APPLICATIONS=(
    # hyprpanel
    # quickshell
    noctalia-shell
    # waybar
    # rofi
    # fuzzel
    wlogout
    pavucontrol
    thunar
    thunar-archive-plugin
    file-roller
    yazi
    gparted
    # code
    neovim
    python3-neovim
    lazygit
    lazydocker
    lazyssh
    imv
    swappy
    gpu-screen-recorder-ui
    ImageMagick
    libqalculate
    libqalculate-devel
    # antigravity
    kitty
)

FONTS=(
    fontawesome-fonts-all
    google-noto-color-emoji-fonts
    google-noto-emoji-fonts
    dejavu-sans-fonts
    dejavu-sans-mono-fonts
)

DEVELOPMENT=(
    git
    sassc
    xdg-utils
    R-rsvg
    python3
    qt6ct
    qt6-qtbase
    qt6-qtdeclarative
    qt6-qtsvg
    qt6-qt5compat
    qt6-qtmultimedia
    qt6-qtimageformats
    qt6-qtbase-devel
    qt6-qtdeclarative-devel
    qt6-qtsvg-devel
    qt6-qt5compat-devel
    glew

)

# --- 3. Main Installation ---

mkdir -p /var/opt/cloudflare-warp
ln -sf /var/opt/cloudflare-warp /opt/cloudflare-warp

echo ":: Installing RPM packages..."
    # --nogpgcheck --repofrompath "terra-tmp,https://repos.fyralabs.com/terra$(rpm -E %fedora)" \
dnf5 install -y \
    "${SYSTEM_UTILS[@]}" \
    "${APPLICATIONS[@]}" \
    "${FONTS[@]}" \
    "${DEVELOPMENT[@]}"

# --- 4. Manual Binary Installation ---

echo ":: Installing nmgui..."
curl -L "https://github.com/s-adi-dev/nmgui/releases/latest/download/main.bin" -o /usr/bin/nmgui
chmod +x /usr/bin/nmgui

echo ":: Installing eza..."
curl -L "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp
mv /tmp/eza /usr/bin/eza
chmod +x /usr/bin/eza
ln -sf /usr/bin/eza /usr/bin/exa

echo ":: Installing Nerd Fonts (JetBrainsMono)..."
FONT_DIR="/usr/share/fonts/JetBrainsMonoNerdFont"
mkdir -p "$FONT_DIR"
wget -qO /tmp/jb_font.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o /tmp/jb_font.zip -d "$FONT_DIR"
rm /tmp/jb_font.zip

echo ":: Installing Nerd Fonts (CodeNewRoman)..."
FONT_DIR="/usr/share/fonts/CodeNewRomanNerdFont"
mkdir -p "$FONT_DIR"
wget -qO /tmp/cnr_font.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CodeNewRoman.zip
unzip -o /tmp/cnr_font.zip -d "$FONT_DIR"
rm /tmp/cnr_font.zip

echo ":: Installing Nerd Fonts (Noto)..."
FONT_DIR="/usr/share/fonts/NotoNerdFont"
mkdir -p "$FONT_DIR"
wget -qO /tmp/noto_font.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Noto.zip
unzip -o /tmp/noto_font.zip -d "$FONT_DIR"
rm /tmp/noto_font.zip

echo ":: Installing Nerd Fonts (RobotoMono)..."
FONT_DIR="/usr/share/fonts/RobotoMonoNerdFont"
mkdir -p "$FONT_DIR"
wget -qO /tmp/roboto_font.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/RobotoMono.zip
unzip -o /tmp/roboto_font.zip -d "$FONT_DIR"
rm /tmp/roboto_font.zip

echo ":: Installing Nerd Fonts (Tinos)..."
FONT_DIR="/usr/share/fonts/TinosNerdFont"
mkdir -p "$FONT_DIR"
wget -qO /tmp/tinos_font.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Tinos.zip
unzip -o /tmp/tinos_font.zip -d "$FONT_DIR"
rm /tmp/tinos_font.zip

echo ":: Installing Nerd Fonts (AdwaitaMono)..."
FONT_DIR="/usr/share/fonts/AdwaitaMonoNerdFont"
mkdir -p "$FONT_DIR"
wget -qO /tmp/adwaita_font.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/AdwaitaMono.zip
unzip -o /tmp/adwaita_font.zip -d "$FONT_DIR"
rm /tmp/adwaita_font.zip

# --- 5. Post-Install Configuration ---

echo ":: Configuring system symlinks and permissions..."
ln -sf /usr/bin/sassc /usr/bin/sass
chmod -R a+r /usr/lib/python*/site-packages/
fc-cache -fv

echo ":: Enabling Systemd Units..."
systemctl enable warp-svc.service
systemctl enable podman.socket
systemctl enable zerotier-one
systemctl enable crond
systemctl enable atd
systemctl --global enable post-install.service
chmod +x /usr/bin/post-install.sh

# --- 6. Cleanup ---

echo ":: Cleaning up repositories and cache..."
for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr disable "$repo"
done

# sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/_copr_SwayNotificationCenter.repo
# sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/vscode.repo
# sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/antigravity.repo
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/wayscriber.repo

dnf5 clean all

echo "Build script completed successfully."
