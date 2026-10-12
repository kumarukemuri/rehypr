#!/usr/bin/env bash
set -euo pipefail

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

MIC="@DEFAULT_AUDIO_SOURCE@"

wpctl set-mute "$MIC" toggle
