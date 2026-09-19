#!/usr/bin/env bash

set -Eeuo pipefail

readonly WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/.config/hypr/wallpapers}"
readonly ROFI_THEME="${ROFI_THEME:-$HOME/.config/rofi/wallpaper.rasi}"
readonly SET_WALLPAPER="${SET_WALLPAPER:-$HOME/.config/hypr/scripts/set-wallpaper.sh}"
readonly THUMBNAIL_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/rehypr/wallpapers"

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
readonly CELL_WIDTH=188
window_width=$((column_count * CELL_WIDTH + (column_count - 1) * 6 + 16))
theme_override="window { width: ${window_width}px; } listview { columns: ${column_count}; }"

thumbnail() {
    local source="$1" key target temporary
    # Include the full path, size and nanosecond modification time, plus the format version.
    key="$(printf '%s\0%s\0v1-360x204' "$source" "$(stat -Lc '%s:%y' -- "$source")" | sha256sum)"
    target="$THUMBNAIL_DIR/${key%% *}.png"
    if [[ ! -s "$target" ]]; then
        temporary="$(mktemp "$THUMBNAIL_DIR/.thumbnail-XXXXXX.png")"
        if ffmpeg -nostdin -hide_banner -loglevel error -y -i "$source" \
            -vf 'scale=360:204:force_original_aspect_ratio=decrease' \
            -frames:v 1 -threads 1 -update 1 "$temporary"; then
            mv -f -- "$temporary" "$target"
        else
            rm -f -- "$temporary"
            printf '%s' "$source"
            return
        fi
    fi
    printf '%s' "$target"
}

command -v ffmpeg >/dev/null 2>&1 || {
    notify_error 'Install ffmpeg to generate wallpaper thumbnails'
    exit 1
}
mkdir -p "$THUMBNAIL_DIR"

selected_index="$({
    for wallpaper in "${wallpapers[@]}"; do
        printf '%s\0icon\x1f%s\n' "$(basename "$wallpaper")" "$(thumbnail "$wallpaper")"
    done
} | rofi -dmenu -i -no-custom -show-icons -format i \
    -p "Wallpaper" -theme "$ROFI_THEME" -theme-str "$theme_override" || true)"

[[ -n "$selected_index" ]] || exit 0
[[ "$selected_index" =~ ^[0-9]+$ ]] || exit 1
((selected_index < ${#wallpapers[@]})) || exit 1

exec "$SET_WALLPAPER" "${wallpapers[$selected_index]}"
