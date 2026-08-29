#!/usr/bin/env bash

set -Eeuo pipefail

readonly WALLPAPER_CONFIG="${HYPRPAPER_CONFIG:-$HOME/.config/hypr/hyprpaper.conf}"
readonly HYPRLOCK_CONFIG="${HYPRLOCK_CONFIG:-$HOME/.config/hypr/hyprlock.conf}"
readonly SELECTED_WALLPAPER="${1:-}"

notify_result() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Hyprland Wallpaper" "$1" "${2:-}"
    fi
}

fail() {
    notify_result "Wallpaper" "$1"
    exit 1
}

[[ -n "$SELECTED_WALLPAPER" ]] || fail "No wallpaper was selected"
[[ -f "$SELECTED_WALLPAPER" ]] || fail "Wallpaper was not found: $SELECTED_WALLPAPER"
[[ -f "$WALLPAPER_CONFIG" ]] || fail "Hyprpaper config was not found: $WALLPAPER_CONFIG"
[[ -f "$HYPRLOCK_CONFIG" ]] || fail "Hyprlock config was not found: $HYPRLOCK_CONFIG"
command -v matugen >/dev/null 2>&1 || fail "matugen was not found"

# GNU Stow may expose these files through symlinks. Resolve their targets so
# replacing a temporary file does not remove the Stow link itself.
wallpaper_target="$(realpath -- "$WALLPAPER_CONFIG")"
hyprlock_target="$(realpath -- "$HYPRLOCK_CONFIG")"

mapfile -t monitors < <(
    sed -nE 's/^[[:space:]]*monitor[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$/\1/p' \
        "$WALLPAPER_CONFIG"
)

if ((${#monitors[@]} == 0)) && command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    mapfile -t monitors < <(hyprctl monitors -j | jq -r '.[].name')
fi

((${#monitors[@]} > 0)) || fail "No monitors were found"

selected_path="$(realpath -- "$SELECTED_WALLPAPER")"
temporary_config="$(mktemp "${wallpaper_target}.XXXXXX")"
temporary_lock_config="$(mktemp "${hyprlock_target}.XXXXXX")"
cleanup() {
    rm -f -- "$temporary_config" "$temporary_lock_config"
}
trap cleanup EXIT

{
    for monitor in "${monitors[@]}"; do
        cat <<EOF
wallpaper {
    monitor = $monitor
    path = $selected_path
    fit_mode = cover
}

EOF
    done
    printf 'splash = false\n'
} >"$temporary_config"

WALLPAPER_PATH="$selected_path" awk '
    /^[[:space:]]*background[[:space:]]*\{/ {
        in_background = 1
    }

    in_background && !updated && /^[[:space:]]*path[[:space:]]*=/ {
        equals = index($0, "=")
        print substr($0, 1, equals) " " ENVIRON["WALLPAPER_PATH"]
        updated = 1
        next
    }

    in_background && /^[[:space:]]*}/ {
        in_background = 0
    }

    { print }

    END {
        if (!updated) exit 1
    }
' "$hyprlock_target" >"$temporary_lock_config" ||
    fail "Hyprlock background path was not found"

chmod --reference="$wallpaper_target" "$temporary_config" 2>/dev/null || true
chmod --reference="$hyprlock_target" "$temporary_lock_config" 2>/dev/null || true
mv -- "$temporary_config" "$wallpaper_target"
mv -- "$temporary_lock_config" "$hyprlock_target"

if command -v hyprctl >/dev/null 2>&1; then
    for monitor in "${monitors[@]}"; do
        hyprctl hyprpaper wallpaper "$monitor,$selected_path,cover" >/dev/null 2>&1 || true
    done
fi

matugen image --mode dark --prefer darkness --type scheme-tonal-spot "$selected_path"

if [[ -x "$HOME/.config/rofi/reloader.sh" ]]; then
    "$HOME/.config/rofi/reloader.sh" >/dev/null 2>&1 &
fi

notify_result "Wallpaper changed" "$(basename "$selected_path") · dark Matugen theme generated"
