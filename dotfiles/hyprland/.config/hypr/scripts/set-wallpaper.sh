#!/usr/bin/env bash

set -Eeuo pipefail

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
command -v matugen >/dev/null 2>&1 || fail "matugen was not found"

selected_path="$(realpath -- "$SELECTED_WALLPAPER")"
# This path is also embedded in line-oriented Hyprland configuration and IPC.
# Reject syntax characters instead of interpreting filenames as configuration.
if [[ "$selected_path" == *[[:cntrl:]]* || "$selected_path" == *'"'* ||
      "$selected_path" == *'\'* || "$selected_path" == *'#'* ||
      "$selected_path" == *'$'* || "$selected_path" == *','* ]]; then
    fail 'Wallpaper path contains unsupported configuration characters; rename the file'
fi

monitors=()
if [[ "$RELOAD_MODE" != "--no-reload" ]]; then
    command -v hyprctl >/dev/null 2>&1 || fail "hyprctl was not found"
    command -v jq >/dev/null 2>&1 || fail "jq was not found"
    monitor_json="$(hyprctl monitors -j)" || fail "Could not query connected monitors"
    monitor_names="$(jq -er '[.[] | select(.disabled != true) | .name] | if length > 0 then .[] else error("No active monitors") end' <<< "$monitor_json")" || fail "No active monitors were found"
    mapfile -t monitors <<< "$monitor_names"
fi

# Matugen writes $image to colors.conf, shared by Hyprpaper and Hyprlock.
matugen image --mode dark --prefer darkness --type scheme-tonal-spot "$selected_path" || fail "Matugen failed; wallpaper was not applied"

if [[ "$RELOAD_MODE" != "--no-reload" ]] && command -v hyprctl >/dev/null 2>&1; then
    for monitor in "${monitors[@]}"; do
        hyprctl hyprpaper wallpaper "$monitor,$selected_path,cover" || fail "Could not apply wallpaper to $monitor"
    done
fi

if [[ "$RELOAD_MODE" != "--no-reload" && -x "$HOME/.config/rofi/reloader.sh" ]]; then
    "$HOME/.config/rofi/reloader.sh" --theme
fi

if [[ "$RELOAD_MODE" != "--no-reload" ]]; then
    notify_result "Wallpaper changed" "$(basename "$selected_path") selected · Matugen theme generated"
fi
