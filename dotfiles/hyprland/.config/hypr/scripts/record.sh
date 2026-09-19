#!/usr/bin/env bash
set -Eeuo pipefail

readonly service=gpu-screen-recorder-record.service
readonly output_dir="$HOME/Videos/Recordings"

if [[ "${1:-}" == --run ]]; then
    mkdir -p "$output_dir"
    monitor="$(hyprctl monitors -j | jq -er 'first(.[] | select(.focused) | .name)')"
    exec /usr/bin/gpu-screen-recorder -v no -w "$monitor" \
        -f 60 -fm cfr -c mp4 -k hevc -encoder gpu -bm cbr -q 12000 \
        -ac opus -ab 192 \
        -a 'app-inverse:discord|app-inverse:vesktop|app-inverse:telegram|app-inverse:zen|app-inverse:spotify|app-inverse:mattermost|app-inverse:steam' \
        -cursor yes -cr limited -keyint 2 \
        -o "$output_dir/Recording-$(date +%Y-%m-%d_%H-%M-%S-%N).mp4"
fi

# Serialize key presses while the service starts or finalizes the MP4.
exec 9>"${XDG_RUNTIME_DIR:?}/rehypr-record.lock"
flock -n 9 || exit 0
if systemctl --user is-active --quiet "$service"; then
    if systemctl --user stop "$service" &&
        [[ "$(systemctl --user show --property=Result --value "$service")" == success ]]; then
        notify-send 'GPU Screen Recorder' "Recording saved to $output_dir"
    else
        notify-send -u critical 'GPU Screen Recorder' 'Recording failed; check the recording service journal'
        exit 1
    fi
else
    if systemctl --user start "$service"; then
        notify-send 'GPU Screen Recorder' 'Recording started. Press Super+Shift+R to stop.'
    else
        notify-send -u critical 'GPU Screen Recorder' 'Could not start recording; check the recording service journal'
        exit 1
    fi
fi
