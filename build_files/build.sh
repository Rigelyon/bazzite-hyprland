#!/bin/bash

set -ouex pipefail

# --- 1. Environment & Repository Configuration ---
export PIP_ROOT_USER_ACTION=ignore

COPR_REPOS=(
    "sdegler/hyprland"
    "errornointernet/quickshell"
    "atim/starship"
    "brycensranch/gpu-screen-recorder-git"
    "lihaohong/yazi"
    "dejan/lazygit"
    "atim/lazydocker"
    "heus-sueh/packages"
    "komapro/lazyssh"
)

echo ":: Configuring External Repositories..."

for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr enable "$repo"
done

dnf5 config-manager setopt copr:copr.fedorainfracloud.org:heus-sueh:packages.priority=200

curl -sL -o /etc/yum.repos.d/_copr_SwayNotificationCenter.repo \
    "https://copr.fedorainfracloud.org/coprs/erikreider/SwayNotificationCenter/repo/fedora-$(rpm -E %fedora)/erikreider-SwayNotificationCenter-fedora-$(rpm -E %fedora).repo"

cat <<EOF > /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

cat <<EOF > /etc/yum.repos.d/antigravity.repo
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
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
    hyprsunset
    wl-clipboard
    cliphist
    wev
    wf-recorder
    grim
    slurp
    swww
    wireplumber
    pipewire-utils
)

APPLICATIONS=(
    hyprpanel
    quickshell
    waybar
    SwayNotificationCenter
    rofi
    fuzzel
    aylurs-gtk-shell2
    wlogout
    pavucontrol
    thunar
    thunar-archive-plugin
    file-roller
    yazi
    gparted
    code
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
    texlive
    latexmk
    antigravity
)

FONTS=(
    fontawesome-fonts-all
    google-noto-color-emoji-fonts
    google-noto-emoji-fonts
)

DEVELOPMENT=(
    git
    sassc
    xdg-utils
    R-rsvg
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
)

# --- 3. Main Installation ---

echo ":: Installing RPM packages..."
rpm-ostree install \
    "${SYSTEM_UTILS[@]}" \
    "${APPLICATIONS[@]}" \
    "${FONTS[@]}" \
    "${DEVELOPMENT[@]}"

# --- 4. Manual Binary Installation ---

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

# --- 5. Post-Install Configuration ---

echo ":: Configuring system symlinks and permissions..."
ln -sf /usr/bin/sassc /usr/bin/sass
chmod -R a+r /usr/lib/python*/site-packages/
fc-cache -fv

echo ":: Enabling Systemd Units..."
systemctl enable podman.socket
systemctl --global enable post-install.service
chmod +x /usr/bin/post-install.sh

# --- 6. Cleanup ---

echo ":: Cleaning up repositories and cache..."
for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr disable "$repo"
done

sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/_copr_SwayNotificationCenter.repo
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/vscode.repo
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/antigravity.repo

dnf5 clean all
rpm-ostree cleanup -m

echo "Build script completed successfully."
