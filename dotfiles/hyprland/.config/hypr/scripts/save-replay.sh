#!/usr/bin/env bash
set -Eeuo pipefail
script_dir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
profile="$(bash "$script_dir/profile.sh")"
if [[ "$profile" != desktop ]]; then
    notify-send 'Replay unavailable' 'The replay service is configured for the desktop monitor.'
    exit 1
fi
if systemctl --user kill --kill-whom=main --signal=SIGUSR1 gpu-screen-recorder-replay.service; then
    notify-send -t 1800 -u low 'GPU Screen Recorder' 'Saving the last 30 seconds'
else
    notify-send -t 2500 -u critical 'GPU Screen Recorder' 'Replay service is not running'
    exit 1
fi
