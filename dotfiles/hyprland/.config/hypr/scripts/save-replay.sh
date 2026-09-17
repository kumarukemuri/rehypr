#!/usr/bin/env bash
set -Eeuo pipefail
script_dir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
profile="$(bash "$script_dir/profile.sh")"
if [[ "$profile" != desktop ]]; then
    notify-send 'Replay unavailable' 'The replay service is configured for the desktop monitor.'
    exit 1
fi
if [[ ! -x "$HOME/.local/bin/save-gsr-replay" ]]; then
    notify-send 'Replay unavailable' 'Install ~/.local/bin/save-gsr-replay first.'
    exit 1
fi
exec "$HOME/.local/bin/save-gsr-replay"
