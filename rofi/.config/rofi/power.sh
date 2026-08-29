#!/usr/bin/env bash

chosen=$(printf "Reload\nPower Off\nRestart\nSleep\n" | rofi -dmenu -i -theme "$HOME/.config/rofi/power.rasi")

[ -z "$chosen" ] && exit 0

set_en_layout() {
    hyprctl switchxkblayout all 0 >/dev/null 2>&1
}

case "$chosen" in
    "Reload")
        bash "$HOME/.config/rofi/reloader.sh"
        ;;
    "Sleep")
        systemctl suspend
        ;;
    "Restart")
        systemctl reboot
        ;;
    "Power Off")
        systemctl poweroff
        ;;
    *)
        exit 1
        ;;
esac
