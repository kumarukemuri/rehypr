#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_PATH="$(realpath -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(dirname -- "$SCRIPT_PATH")"
readonly REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
readonly PACKAGES_DIR="$SCRIPT_DIR/packages"
readonly TARGET_USER="$(id -un)"
readonly TARGET_HOME="$HOME"
readonly KEYD_CONFIG="$REPO_DIR/install/system/keyd/hypr.conf"
mapfile -t STOW_PACKAGES < "$SCRIPT_DIR/stow-packages.txt"
readonly -a STOW_PACKAGES
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
action=""
selected_profile=""

usage() {
    cat <<'EOF'
Usage: setup.sh [--install | --restow | --migrate | --profile NAME] [options]

Manage the rehypr desktop for the current user. Without an action, show a menu.

Actions:
  --install     Install packages and configure the desktop
  --restow      Refresh dotfile links only
  --migrate     Migrate legacy links and refresh dotfile links
  --profile NAME  Save auto, desktop or laptop locally (no session restart)

Options:
  --dry-run      Preview the selected action without changing the system
  --noconfirm    Pass --noconfirm to pacman, yay and makepkg
  -h, --help     Show this help
EOF
}

while (($#)); do
    case "$1" in
        --profile)
            [[ -z "$action" && $# -ge 2 ]] || { printf 'Use --profile auto|desktop|laptop as a separate action.\n' >&2; exit 2; }
            action=profile
            selected_profile="$2"
            shift
            ;;
        --install | --restow | --migrate)
            [[ -z "$action" ]] || { printf 'Choose only one action.\n' >&2; exit 2; }
            action="${1#--}"
            ;;
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

if [[ -z "$action" ]]; then
    while true; do
        printf '\nrehypr\n  1) Install and configure desktop\n  2) Restow dotfiles\n  3) Migrate legacy links and restow\n  4) Choose device profile\n  0) Exit\n'
        printf 'Select action [0-4]: '
        if ! IFS= read -r choice; then
            printf '\nNo action selected. Use --install, --restow or --migrate.\n' >&2
            exit 2
        fi
        case "$choice" in
            1) action=install; break ;;
            2) action=restow; break ;;
            3) action=migrate; break ;;
            4)
                printf 'Profile [auto/desktop/laptop]: '
                IFS= read -r selected_profile || exit 2
                action=profile
                break
                ;;
            0) exit 0 ;;
            *) printf 'Enter 0, 1, 2, 3 or 4.\n' >&2 ;;
        esac
    done
fi

if $noconfirm && [[ "$action" != install ]]; then
    printf '%s\n' '--noconfirm is only supported with --install.' >&2
    exit 2
fi

readonly PROFILE_FILE="$TARGET_HOME/.config/rehypr/profile"
readonly PROFILE_HELPER="$REPO_DIR/dotfiles/hyprland/.config/hypr/scripts/profile.sh"
if [[ "$action" == profile ]]; then
    case "$selected_profile" in
        auto | desktop | laptop) ;;
        *) printf 'Invalid profile: %s\n' "$selected_profile" >&2; exit 2 ;;
    esac
    if $dry_run; then
        printf 'Would save profile %s to %s\n' "$selected_profile" "$PROFILE_FILE"
    else
        mkdir -p -- "$(dirname -- "$PROFILE_FILE")"
        profile_temp="$(mktemp "${PROFILE_FILE}.XXXXXX")"
        printf '%s\n' "$selected_profile" > "$profile_temp"
        mv -- "$profile_temp" "$PROFILE_FILE"
        printf 'Profile saved: %s (effective: %s). Reload Hyprland to apply.\n' "$selected_profile" "$(bash "$PROFILE_HELPER")"
    fi
    exit 0
fi
# Validate local overrides without changing them during install/restow.
effective_profile="$(bash "$PROFILE_HELPER")"
printf 'Device profile: %s\n' "$effective_profile"

((${#STOW_PACKAGES[@]})) || { printf 'The Stow package list is empty.\n' >&2; exit 1; }
for package in "${STOW_PACKAGES[@]}"; do
    [[ "$package" =~ ^[a-zA-Z0-9_-]+$ && -d "$REPO_DIR/dotfiles/$package" ]] || {
        printf 'Invalid or missing Stow package: %s\n' "$package" >&2
        exit 1
    }
done

command -v python3 >/dev/null 2>&1 || {
    printf 'Required command was not found: python3 (Arch package: python)\n' >&2
    exit 1
}

if [[ "$action" != install ]]; then
    command -v stow >/dev/null 2>&1 || { printf 'Required command was not found: stow\n' >&2; exit 1; }
    if [[ "$action" == migrate ]]; then
        args=()
        if $dry_run; then args+=(--dry-run); fi
        exec python3 "$SCRIPT_DIR/migrate.py" "${args[@]}"
    fi
    python3 "$SCRIPT_DIR/migrate.py" --check
    stow --simulate --dir="$REPO_DIR/dotfiles" --target="$TARGET_HOME" --restow "${STOW_PACKAGES[@]}"
    if $dry_run; then exit 0; fi
    mkdir -p -- "$TARGET_HOME/.config" "$TARGET_HOME/.local/share/themes"
    stow --dir="$REPO_DIR/dotfiles" --target="$TARGET_HOME" --restow "${STOW_PACKAGES[@]}"
    printf 'Dotfile links refreshed.\n'
    exit 0
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

installed_package_names="$(pacman -Qq)" || {
    printf 'Failed to query installed packages.\n' >&2
    exit 1
}

declare -A installed_packages=()
while IFS= read -r package; do
    if [[ -n "$package" ]]; then
        installed_packages["$package"]=1
    fi
done <<< "$installed_package_names"

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

check_stow_conflicts() {
    command -v python3 >/dev/null 2>&1 || {
        printf 'Required command was not found: python3 (Arch package: python)\n' >&2
        exit 1
    }
    python3 "$SCRIPT_DIR/migrate.py" --check
    if command -v stow >/dev/null 2>&1; then
        stow --simulate --dir="$REPO_DIR/dotfiles" --target="$TARGET_HOME" --restow "${STOW_PACKAGES[@]}"
    else
        printf 'Stow conflict check deferred until Stow is installed.\n'
    fi
}

check_stow_conflicts

if $dry_run; then
    cat <<EOF

Post-install actions:
  enable NetworkManager.service and bluetooth.service
  install $KEYD_CONFIG to /etc/keyd/hypr.conf and restart keyd.service
  restow ${STOW_PACKAGES[*]} from $REPO_DIR into $TARGET_HOME
  enable and start audio user units: ${AUDIO_USER_UNITS[*]}
  enable user services: ${USER_SERVICES[*]}
  create or update Qt color paths while preserving existing settings
  set GTK and Qt interface fonts to JetBrainsMono Nerd Font Propo 12
  create Matugen output directories
  initialize missing theme colors and wallpaper paths without reloading the desktop
  leave optional Kraken and replay services disabled unless already enabled
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

# Check again now that Stow is guaranteed to be installed.
check_stow_conflicts

printf 'Linking dotfiles from %s...\n' "$REPO_DIR"
mkdir -p -- "$TARGET_HOME/.config" "$TARGET_HOME/.local/share/themes"
stow --dir="$REPO_DIR/dotfiles" --target="$TARGET_HOME" --restow "${STOW_PACKAGES[@]}"
mkdir -p -- "${MATUGEN_OUTPUT_DIRS[@]}"

# Qt stores absolute palette paths; preserve all other user settings.
for qt_version in 5 6; do
    qt_dir="$TARGET_HOME/.config/qt${qt_version}ct"
    qt_config="$qt_dir/qt${qt_version}ct.conf"
    mkdir -p -- "$qt_dir"
    if [[ ! -f "$qt_config" ]]; then
        cp -- "$SCRIPT_DIR/templates/qtct/qt${qt_version}ct.conf.in" "$qt_config"
    fi
    qt_target="$(realpath -- "$qt_config")"
    qt_temp="$(mktemp "${qt_target}.XXXXXX")"
    if COLOR_SCHEME_PATH="$qt_dir/colors/matugen.conf" awk '
        /^\[Appearance\]$/ { appearance = 1; print; print "color_scheme_path=" ENVIRON["COLOR_SCHEME_PATH"]; next }
        /^\[/ { appearance = 0 }
        appearance && /^color_scheme_path=/ { next }
        { print }
    ' "$qt_target" > "$qt_temp"; then
        chmod --reference="$qt_target" "$qt_temp"
        mv -- "$qt_temp" "$qt_target"
    else
        rm -f -- "$qt_temp"
        exit 1
    fi
done

# Match the Waybar interface font; keep all other GTK/Qt settings.
python3 - "$TARGET_HOME" <<'PYFONT'
import configparser
from pathlib import Path
import sys

config = Path(sys.argv[1]) / '.config'
for version in (3, 4, 5, 6):
    gtk = version < 5
    path = config / (f'gtk-{version}.0/settings.ini' if gtk else f'qt{version}ct/qt{version}ct.conf')
    settings = configparser.ConfigParser(interpolation=None, strict=False)
    settings.optionxform = str
    settings.read(path)
    section, key = ('Settings', 'gtk-font-name') if gtk else ('Fonts', 'general')
    if not settings.has_section(section):
        settings.add_section(section)
    if gtk:
        value = 'JetBrainsMono Nerd Font Propo 12'
    else:
        parts = settings.get(section, key, fallback='"Sans,12,-1,5,50,0,0,0,0,0"').strip('"').split(',')
        parts[:2] = ['JetBrainsMono Nerd Font Propo', '12']
        value = '"' + ','.join(parts) + '"'
    settings.set(section, key, value)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('w') as stream:
        settings.write(stream, space_around_delimiters=False)
PYFONT

if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]] && command -v gsettings >/dev/null 2>&1; then
    for schema in org.gnome.desktop.interface org.cinnamon.desktop.interface; do
        if gsettings list-schemas | grep -Fx "$schema" >/dev/null; then
            gsettings set "$schema" font-name 'JetBrainsMono Nerd Font Propo 12'
        fi
    done
fi

# Generated colors are not tracked, so a fresh checkout needs an initial palette.
if [[ ! -f "$TARGET_HOME/.config/hypr/colors.conf" ||
      ! -f "$TARGET_HOME/.config/hypr/config/colors.lua" ||
      ! -f "$TARGET_HOME/.config/rofi/colors.rasi" ||
      ! -f "$TARGET_HOME/.config/kitty/colors.conf" ||
      ! -f "$TARGET_HOME/.config/mako/mako-colors" ||
      ! -f "$TARGET_HOME/.config/waybar/colors.css" ||
      ! -f "$TARGET_HOME/.config/swayosd/colors.css" ]]; then
    printf 'Initializing wallpaper and application colors...\n'
    wallpaper=""
    if [[ -f "$TARGET_HOME/.config/hypr/colors.conf" ]]; then
        wallpaper="$(sed -n 's/^\$image = //p' "$TARGET_HOME/.config/hypr/colors.conf" | head -n 1)"
    fi
    if [[ ! -f "$wallpaper" ]]; then
        wallpaper="$TARGET_HOME/.config/hypr/wallpapers/woods.jpg"
    fi
    "$REPO_DIR/dotfiles/hyprland/.config/hypr/scripts/set-wallpaper.sh" "$wallpaper" --no-reload
fi

printf 'Enabling network and Bluetooth services...\n'
sudo systemctl enable --now NetworkManager.service bluetooth.service

printf 'Installing the keyd Alt/Super mapping...\n'
sudo install -Dm644 -- "$KEYD_CONFIG" /etc/keyd/hypr.conf
sudo systemctl enable keyd.service
sudo systemctl restart keyd.service

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
