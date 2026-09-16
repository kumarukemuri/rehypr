#!/usr/bin/env bash

set -Eeuo pipefail

readonly WALLPAPER_CONFIG="${HYPRPAPER_CONFIG:-$HOME/.config/hypr/hyprpaper.conf}"
readonly SELECTED_WALLPAPER="${1:-}"
readonly RELOAD_MODE="${2:-}"
[[ "$RELOAD_MODE" == "" || "$RELOAD_MODE" == "--no-reload" ]] || {
    printf 'Usage: %s IMAGE [--no-reload]\n' "$0" >&2
    exit 2
}

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
command -v matugen >/dev/null 2>&1 || fail "matugen was not found"

mapfile -t monitors < <(
    sed -nE 's/^[[:space:]]*monitor[[:space:]]*=[[:space:]]*(.+)[[:space:]]*$/\1/p' \
        "$WALLPAPER_CONFIG"
)

if ((${#monitors[@]} == 0)) && command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    mapfile -t monitors < <(hyprctl monitors -j | jq -r '.[].name')
fi

((${#monitors[@]} > 0)) || fail "No monitors were found"

selected_path="$(realpath -- "$SELECTED_WALLPAPER")"
# Matugen writes $image to colors.conf, shared by Hyprpaper and Hyprlock.
matugen image --mode dark --prefer darkness --type scheme-tonal-spot "$selected_path"

if [[ "$RELOAD_MODE" != "--no-reload" ]] && command -v hyprctl >/dev/null 2>&1; then
    for monitor in "${monitors[@]}"; do
        hyprctl hyprpaper wallpaper "$monitor,$selected_path,cover" >/dev/null 2>&1 || true
    done
fi

if [[ "$RELOAD_MODE" != "--no-reload" && -x "$HOME/.config/rofi/reloader.sh" ]]; then
    "$HOME/.config/rofi/reloader.sh" --theme
fi

if [[ "$RELOAD_MODE" != "--no-reload" ]]; then
    notify_result "Wallpaper changed" "$(basename "$selected_path") selected · Matugen theme generated"
fi
