#!/bin/bash

set -ouex pipefail

# --- 1. Environment & Repository Configuration ---
export PIP_ROOT_USER_ACTION=ignore

COPR_REPOS=(
    "ashbuk/Hyprland-Fedora"
    "lionheartp/Hyprland"
    "nett00n/hyprland"
    "errornointernet/quickshell"
    "atim/starship"
    "brycensranch/gpu-screen-recorder-git"
    "lihaohong/yazi"
    "dejan/lazygit"
    "atim/lazydocker"
)

echo ":: Configuring External Repositories..."

for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr enable "$repo"
done

# Exclude broken Hyprland packages from lionheartp so we only get Noctalia from it
for repo_file in /etc/yum.repos.d/*lionheartp*Hyprland*.repo; do
    if [ -f "$repo_file" ]; then
        echo "exclude=hypr* aquamarine* xdg-desktop-portal-hyprland*" >> "$repo_file"
    fi
done

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

cat << 'EOF' > /etc/yum.repos.d/charm.repo
[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key
EOF

dnf5 makecache

# --- 2. Package List Definitions ---

SYSTEM_UTILS=(
    7zip
    accountsservice
    at
    bat
    bluez
    bluez-tools
    brightnessctl
    btop
    cava
    cliphist
    cronie
    ddcutil
    dua-cli
    duf
    evolution-data-server
    fastfetch
    fd-find
    file
    fzf
    gh
    git-credential-oauth
    glib2
    glow
    grim
    hyprland
    hyprland-guiutils
    hyprpicker
    hyprshot
    inotify-tools
    jq
    libnotify
    lm_sensors
    lsd
    micro
    pandoc
    pandoc-cli
    pipewire-utils
    playerctl
    podman-compose
    polkit
    ripgrep
    slurp
    socat
    starship
    stow
    tesseract
    tesseract-langpack-*
    trash-cli
    unzip
    ufw
    wayscriber
    wayscriber-configurator
    wev
    wf-recorder
    wget
    wireplumber
    wl-clipboard
    wl-mirror
    wlsunset
    xclip
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    zbar
    zerotier-one
    zoxide
    zsh
)

APPLICATIONS=(
    file-roller
    gparted
    gpu-screen-recorder-ui
    ImageMagick
    imv
    kitty
    lazydocker
    lazygit
    libqalculate
    libqalculate-devel
    mpv
    neovim
    noctalia-shell
    noctalia
    pavucontrol
    python3-neovim
    swappy
    wlogout
    yazi
)

FONTS=(
    dejavu-sans-fonts
    dejavu-sans-mono-fonts
    fontawesome-fonts-all
    google-noto-color-emoji-fonts
    google-noto-emoji-fonts
)

DEVELOPMENT=(
    git
    glew
    python3
    qt6-qt5compat
    qt6-qt5compat-devel
    qt6-qtbase
    qt6-qtbase-devel
    qt6-qtdeclarative
    qt6-qtdeclarative-devel
    qt6-qtimageformats
    qt6-qtmultimedia
    qt6-qtsvg
    qt6-qtsvg-devel
    qt6ct
    R-rsvg
    sassc
    xdg-utils
)

# --- 3. Main Installation ---

mkdir -p /var/opt/cloudflare-warp
ln -sf /var/opt/cloudflare-warp /opt/cloudflare-warp

echo ":: Installing RPM packages..."
dnf5 install -y \
    "${SYSTEM_UTILS[@]}" \
    "${APPLICATIONS[@]}" \
    "${FONTS[@]}" \
    "${DEVELOPMENT[@]}"

# --- 4. Manual Binary Installation ---

echo ":: Installing External RPM packages..."

fetch_github_release_url() {
    local repo=$1
    local pattern=$2

    # Attempt 1: GitHub REST API
    local url
    url=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | jq -r '.assets[]?.browser_download_url // empty' | grep -iE "$pattern" | head -n 1 || true)

    if [ -n "$url" ]; then
        echo "$url"
        return 0
    fi

    # Attempt 2: HTML scrape of latest release page (bypasses GitHub REST API rate limits)
    local rel_path
    rel_path=$(curl -sL "https://github.com/$repo/releases/latest" | grep -oE "/$repo/releases/download/[^\"]+" | grep -iE "$pattern" | head -n 1 || true)

    if [ -n "$rel_path" ]; then
        echo "https://github.com$rel_path"
        return 0
    fi

    return 1
}

get_latest_github_rpm() {
    local repo=$1
    fetch_github_release_url "$repo" '\.rpm$' | grep -iE 'amd64|x86_64|noarch' | head -n 1 || true
}

GITHUB_RPMS=(
    # "jooaf/thoth"
    # "SourcewareLab/Toney"
)

echo "Fetching and installing dynamic RPMs from GitHub..."
for repo in "${GITHUB_RPMS[@]}"; do
    LATEST_URL=$(get_latest_github_rpm "$repo")

    if [ -n "$LATEST_URL" ]; then
        echo "   Installing $repo: $LATEST_URL"
        dnf5 install -y "$LATEST_URL"
    else
        echo "   WARNING: Failed to find a compatible RPM for $repo. Skipping."
    fi
done

STATIC_RPMS=(
    "https://launchpad.net/veracrypt/trunk/1.26.24/+download/veracrypt-1.26.24-Fedora-40-x86_64.rpm"
)

echo "Installing static external RPMs..."
for rpm in "${STATIC_RPMS[@]}"; do
    dnf5 install -y "$rpm"
done

echo ":: Installing nmgui..."
curl -L "https://github.com/s-adi-dev/nmgui/releases/latest/download/main.bin" -o /usr/bin/nmgui
chmod +x /usr/bin/nmgui

echo ":: Installing eza..."
curl -L "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" | tar xz -C /tmp
mv /tmp/eza /usr/bin/eza
chmod +x /usr/bin/eza
ln -sf /usr/bin/eza /usr/bin/exa

echo ":: Installing curlie..."
CURLIE_URL=$(fetch_github_release_url "rs/curlie" "linux_amd64\.tar\.gz")
if [ -n "$CURLIE_URL" ]; then
    curl -L "$CURLIE_URL" | tar xz -C /tmp
    mv /tmp/curlie /usr/bin/curlie
    chmod +x /usr/bin/curlie
else
    echo "WARNING: Failed to fetch curlie release URL. Skipping."
fi

echo ":: Installing walk..."
WALK_URL=$(fetch_github_release_url "antonmedv/walk" "linux_amd64")
if [ -n "$WALK_URL" ]; then
    curl -L "$WALK_URL" -o /usr/bin/walk
    chmod +x /usr/bin/walk
else
    echo "WARNING: Failed to fetch walk release URL. Skipping."
fi

echo ":: Installing satty..."
SATTY_URL=$(fetch_github_release_url "gabm/Satty" "linux-gnu.*\.tar\.gz|x86_64.*\.tar\.gz|satty.*\.tar\.gz")
if [ -n "$SATTY_URL" ]; then
    curl -L "$SATTY_URL" | tar xz -C /tmp
    find /tmp -type f -name "satty" -exec mv {} /usr/bin/satty \;
    chmod +x /usr/bin/satty
else
    echo "WARNING: Failed to fetch satty release URL. Skipping."
fi

echo ":: Installing swww..."
dnf5 install -y lz4 || true
SWWW_URL=$(fetch_github_release_url "LGFae/swww" "linux-x86_64|x86_64.*unknown-linux|\.tar\.lz4|\.tar\.gz")
if [ -n "$SWWW_URL" ]; then
    rm -rf /tmp/swww*
    curl -L "$SWWW_URL" -o /tmp/swww_archive
    if file /tmp/swww_archive | grep -q "LZ4"; then
        lz4 -d /tmp/swww_archive /tmp/swww.tar || true
        tar -xf /tmp/swww.tar -C /tmp || true
    else
        tar -xzf /tmp/swww_archive -C /tmp || true
    fi
    find /tmp -type f -name "swww" -exec mv {} /usr/bin/swww \; || true
    find /tmp -type f -name "swww-daemon" -exec mv {} /usr/bin/swww-daemon \; || true
    chmod +x /usr/bin/swww /usr/bin/swww-daemon || true
else
    echo "WARNING: Failed to fetch swww release URL. Skipping."
fi

# --- Fonts ---

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
systemctl enable podman.socket
systemctl enable zerotier-one
systemctl enable crond
systemctl enable atd

# --- 6. Cleanup ---

echo ":: Cleaning up repositories and cache..."
for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr disable "$repo"
done

sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/wayscriber.repo
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/charm.repo

dnf5 clean all

echo "Build script completed successfully."
