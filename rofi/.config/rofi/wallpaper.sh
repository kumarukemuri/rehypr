#!/usr/bin/env bash

set -Eeuo pipefail

readonly WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/.config/hypr/wallpapers}"
readonly ROFI_THEME="${ROFI_THEME:-$HOME/.config/rofi/wallpaper.rasi}"
readonly SET_WALLPAPER="${SET_WALLPAPER:-$HOME/.config/hypr/scripts/set-wallpaper.sh}"

notify_error() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Rofi Wallpaper" "Wallpaper" "$1"
    fi
}

command -v rofi >/dev/null 2>&1 || exit 1
[[ -d "$WALLPAPER_DIR" ]] || {
    notify_error "Wallpaper directory was not found: $WALLPAPER_DIR"
    exit 1
}
[[ -x "$SET_WALLPAPER" ]] || {
    notify_error "Wallpaper setter was not found: $SET_WALLPAPER"
    exit 1
}

mapfile -d '' -t wallpapers < <(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        -print0 | sort -z
)

((${#wallpapers[@]} > 0)) || {
    notify_error "No wallpapers were found"
    exit 1
}

column_count=${#wallpapers[@]}
((column_count > 6)) && column_count=6
readonly CELL_WIDTH=186
window_width=$((column_count * CELL_WIDTH + (column_count - 1) * 10 + 24))
theme_override="window { width: ${window_width}px; } listview { columns: ${column_count}; }"

selected_index="$({
    for wallpaper in "${wallpapers[@]}"; do
        printf '%s\0icon\x1f%s\n' "$(basename "$wallpaper")" "$wallpaper"
    done
} | rofi -dmenu -i -no-custom -show-icons -format i \
    -p "Wallpaper" -theme "$ROFI_THEME" -theme-str "$theme_override" || true)"

[[ -n "$selected_index" ]] || exit 0
[[ "$selected_index" =~ ^[0-9]+$ ]] || exit 1
((selected_index < ${#wallpapers[@]})) || exit 1

exec "$SET_WALLPAPER" "${wallpapers[$selected_index]}"
