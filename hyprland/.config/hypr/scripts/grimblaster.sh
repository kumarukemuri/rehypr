#!/usr/bin/env bash

set -Eeuo pipefail

readonly MODE="${1:-}"

usage() {
    printf 'Usage: %s {screen|active|area}\n' "${0##*/}" >&2
}

get_pictures_dir() {
    if command -v xdg-user-dir >/dev/null 2>&1; then
        xdg-user-dir PICTURES
    else
        printf '%s/Pictures\n' "$HOME"
    fi
}

case "$MODE" in
    screen)
        target="output"
        ;;
    active)
        target="active"
        ;;
    area)
        target="area"
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        usage
        exit 2
        ;;
esac

command -v grimblast >/dev/null 2>&1 || {
    printf 'Error: grimblast not found in PATH\n' >&2
    exit 127
}

readonly SCREENSHOTS_DIR="$(get_pictures_dir)/Screenshots"
readonly TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S_%3N')"
readonly OUTPUT_FILE="$SCREENSHOTS_DIR/$TIMESTAMP.png"

mkdir -p -- "$SCREENSHOTS_DIR"

grimblast_args=(--notify)

if [[ "$MODE" == "area" ]]; then
    grimblast_args+=(--freeze)
fi

exec grimblast \
    "${grimblast_args[@]}" \
    copysave \
    "$target" \
    "$OUTPUT_FILE"
