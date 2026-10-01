#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    --theme)
        hyprctl reload
        for service in mako.service waybar.service swayosd-server.service; do
            if systemctl --user is-active --quiet "$service"; then
                systemctl --user restart "$service"
            fi
        done
        exit 0
        ;;
    "") ;;
    *) printf 'Usage: %s [--theme]\n' "$0" >&2; exit 2 ;;
esac

hyprctl reload
systemctl --user daemon-reload
systemctl --user restart \
    hypridle.service \
    hyprland-per-window-layout.service \
    hyprpaper.service \
    mako.service \
    polkit-gnome-authentication-agent.service \
    swayosd-server.service \
    waybar.service

notify-send "Hyprland reloaded"
