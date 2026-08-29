#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_DIR="$(cd -- "$SCRIPT_DIR/../../../.." && pwd)"
readonly PACKAGES_DIR="$SCRIPT_DIR/packages"
readonly TARGET_USER="$(id -un)"
readonly TARGET_HOME="$HOME"
readonly KEYD_CONFIG="$REPO_DIR/system/keyd/hypr.conf"
readonly -a STOW_PACKAGES=(
    fish
    hyprland
    kitty
    mako
    mangohud
    matugen
    mimeapps
    qtct
    rofi
    swayosd
    themes
    uwsm
    waybar
)
readonly -a USER_SERVICES=(
    hypridle.service
    hyprland-per-window-layout.service
    hyprpaper.service
    mako.service
    polkit-gnome-authentication-agent.service
    swayosd-server.service
    waybar.service
)
readonly -a AUDIO_USER_UNITS=(
    pipewire.socket
    pipewire-pulse.socket
    wireplumber.service
)
readonly -a MATUGEN_OUTPUT_DIRS=(
    "$TARGET_HOME/.config/btop/themes"
    "$TARGET_HOME/.config/qt5ct/colors"
    "$TARGET_HOME/.config/qt6ct/colors"
    "$TARGET_HOME/.config/vesktop/themes"
)

dry_run=false
noconfirm=false

usage() {
    cat <<'EOF'
Usage: setup.sh [options]

Installs and configures the minimal rehypr desktop for the current user.

Options:
  --dry-run      Show packages and post-install actions without changing the system
  --noconfirm    Pass --noconfirm to pacman, yay and makepkg
  -h, --help     Show this help
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) dry_run=true ;;
        --noconfirm) noconfirm=true ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if ((EUID == 0)); then
    printf 'Run this script as a regular user, not with sudo.\n' >&2
    exit 1
fi

read_package_file() {
    grep -Ev '^[[:space:]]*($|#)' "$1"
}

compare_packages() {
    local package
    local -n requested_packages="$1"
    local -n installed_matches="$2"
    local -n missing_matches="$3"

    for package in "${requested_packages[@]}"; do
        if [[ -v "installed_packages[$package]" ]]; then
            installed_matches+=("$package")
        else
            missing_matches+=("$package")
        fi
    done
}

print_package_group() {
    local title="$1"
    local -n packages="$2"

    printf '%s (%d):\n' "$title" "${#packages[@]}"
    if ((${#packages[@]})); then
        printf '  %s\n' "${packages[@]}"
    else
        printf '  none\n'
    fi
}

for package_file in "$PACKAGES_DIR/core.txt" "$PACKAGES_DIR/aur.txt"; do
    [[ -f "$package_file" ]] || {
        printf 'Package list was not found: %s\n' "$package_file" >&2
        exit 1
    }
done

[[ -f "$KEYD_CONFIG" ]] || {
    printf 'Keyd configuration was not found: %s\n' "$KEYD_CONFIG" >&2
    exit 1
}

mapfile -t native_packages < <(read_package_file "$PACKAGES_DIR/core.txt")
mapfile -t aur_packages < <(read_package_file "$PACKAGES_DIR/aur.txt")

command -v pacman >/dev/null 2>&1 || {
    printf 'Required command was not found: pacman\n' >&2
    exit 1
}

declare -A installed_packages=()
while IFS= read -r package; do
    installed_packages["$package"]=1
done < <(pacman -Qq)

native_installed=()
native_missing=()
aur_installed=()
aur_missing=()
compare_packages native_packages native_installed native_missing
compare_packages aur_packages aur_installed aur_missing

printf 'Package comparison against the current system:\n\n'
print_package_group 'Official packages already installed' native_installed
printf '\n'
print_package_group 'Official packages to install' native_missing
printf '\n'
print_package_group 'AUR packages already installed' aur_installed
printf '\n'
print_package_group 'AUR packages to install' aur_missing

if $dry_run; then
    cat <<EOF

Post-install actions:
  enable NetworkManager.service and bluetooth.service
  install $KEYD_CONFIG to /etc/keyd/hypr.conf and restart keyd.service
  restow ${STOW_PACKAGES[*]} from $REPO_DIR into $TARGET_HOME
  enable and start audio user units: ${AUDIO_USER_UNITS[*]}
  enable user services: ${USER_SERVICES[*]}
  create optional Matugen output directories
  set Fish as the login shell for $TARGET_USER
  create the standard XDG user directories
EOF
    exit 0
fi

for command in sudo git; do
    command -v "$command" >/dev/null 2>&1 || {
        printf 'Required command was not found: %s\n' "$command" >&2
        exit 1
    }
done

sudo -v

pacman_args=(-S --needed)
yay_args=(-S --needed)
makepkg_args=(-si)
if $noconfirm; then
    pacman_args+=(--noconfirm)
    yay_args+=(--noconfirm)
    makepkg_args+=(--noconfirm)
fi

if ((${#native_missing[@]})); then
    printf '\nInstalling %d official repository packages...\n' "${#native_missing[@]}"
    sudo pacman "${pacman_args[@]}" -- "${native_missing[@]}"
else
    printf '\nAll official repository packages are already installed.\n'
fi

if ! command -v yay >/dev/null 2>&1; then
    printf 'Installing yay from the AUR...\n'
    build_dir="$(mktemp -d --tmpdir rehypr-yay.XXXXXXXX)"
    cleanup() {
        rm -rf -- "$build_dir"
    }
    trap cleanup EXIT
    git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
    (
        cd "$build_dir/yay"
        makepkg "${makepkg_args[@]}"
    )
fi

if ((${#aur_missing[@]})); then
    printf 'Installing %d AUR packages...\n' "${#aur_missing[@]}"
    yay "${yay_args[@]}" -- "${aur_missing[@]}"
else
    printf 'All AUR packages are already installed.\n'
fi

printf 'Enabling network and Bluetooth services...\n'
sudo systemctl enable --now NetworkManager.service bluetooth.service

printf 'Installing the keyd Alt/Super mapping...\n'
sudo install -Dm644 -- "$KEYD_CONFIG" /etc/keyd/hypr.conf
sudo systemctl enable keyd.service
sudo systemctl restart keyd.service

printf 'Linking dotfiles from %s...\n' "$REPO_DIR"
mkdir -p -- "$TARGET_HOME/.config" "$TARGET_HOME/.local/share/themes"
stow --dir="$REPO_DIR" --target="$TARGET_HOME" --restow "${STOW_PACKAGES[@]}"
mkdir -p -- "${MATUGEN_OUTPUT_DIRS[@]}"

printf 'Enabling graphical session services for %s...\n' "$TARGET_USER"
systemctl --user daemon-reload
systemctl --user disable --now hyprpolkitagent.service 2>/dev/null || true
systemctl --user enable --now "${AUDIO_USER_UNITS[@]}"
systemctl --user enable "${USER_SERVICES[@]}"

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update
fi

fish_path="$(command -v fish)"
current_shell="$(getent passwd "$TARGET_USER" | cut -d: -f7)"
if [[ "$current_shell" != "$fish_path" ]]; then
    printf 'Setting Fish as the login shell for %s...\n' "$TARGET_USER"
    sudo chsh -s "$fish_path" "$TARGET_USER"
fi

cat <<'EOF'

rehypr installation completed.
Log out and sign in on TTY1. Fish will start Hyprland through UWSM automatically.
EOF
