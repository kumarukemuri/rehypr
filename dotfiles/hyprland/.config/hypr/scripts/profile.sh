#!/usr/bin/env bash
# Print the effective profile. A disconnected eDP connector still identifies a laptop.
set -Eeuo pipefail
profile=auto
file="$HOME/.config/rehypr/profile"
if [[ -e "$file" || -L "$file" ]]; then
    [[ -f "$file" && -r "$file" ]] || { printf 'Cannot read profile: %s\n' "$file" >&2; exit 1; }
    profile="$(cat -- "$file")"
fi
case "$profile" in
    desktop | laptop | fallback) printf '%s\n' "$profile" ;;
    auto)
        for connector in "${REHYPR_DRM_DIR:-/sys/class/drm}"/card*-eDP-*; do
            if [[ -d "$connector" ]]; then printf 'laptop\n'; exit 0; fi
        done
        # Only the known desktop gets its fixed three-monitor layout.
        host_file="${REHYPR_HOSTNAME_FILE:-/etc/hostname}"
        host=""
        if [[ -r "$host_file" ]]; then host="$(cat -- "$host_file")"; fi
        if [[ "$host" == parabellum ]]; then printf 'desktop\n'; else printf 'fallback\n'; fi
        ;;
    *) printf 'Invalid rehypr profile: %s (expected auto, desktop, laptop or fallback)\n' "$profile" >&2; exit 2 ;;
esac
