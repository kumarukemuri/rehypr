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
    desktop | laptop) printf '%s\n' "$profile" ;;
    auto)
        for connector in "${REHYPR_DRM_DIR:-/sys/class/drm}"/card*-eDP-*; do
            if [[ -d "$connector" ]]; then printf 'laptop\n'; exit 0; fi
        done
        printf 'desktop\n'
        ;;
    *) printf 'Invalid rehypr profile: %s (expected auto, desktop or laptop)\n' "$profile" >&2; exit 2 ;;
esac
