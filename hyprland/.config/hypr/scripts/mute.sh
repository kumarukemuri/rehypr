#!/usr/bin/env bash
set -euo pipefail

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

MIC="@DEFAULT_AUDIO_SOURCE@"
OSDMON="$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')"

wpctl set-mute "$MIC" toggle

if wpctl get-volume "$MIC" 2>/dev/null | grep -q MUTED; then
  swayosd-client --monitor "$OSDMON" \
    --custom-icon microphone-sensitivity-muted \
    --custom-progress 0
else
  swayosd-client --monitor "$OSDMON" \
    --custom-icon microphone-sensitivity-high \
    --custom-progress 1
fi