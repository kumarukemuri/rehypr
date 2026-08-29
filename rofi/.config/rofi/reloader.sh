#!/usr/bin/env bash
set -euo pipefail

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
