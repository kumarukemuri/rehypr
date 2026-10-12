#!/usr/bin/env bash
set -euo pipefail

# Track system mute, including changes made outside the keyboard shortcut.
if ! volume="$(LC_ALL=C wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)"; then
    printf '%s\n' '{"text":"●","class":"unavailable","tooltip":"Microphone unavailable"}'
elif [[ "$volume" == *MUTED* ]]; then
    printf '%s\n' '{"text":"●","class":"muted","tooltip":"Microphone muted"}'
else
    printf '%s\n' '{"text":"","class":"available","tooltip":""}'
fi
