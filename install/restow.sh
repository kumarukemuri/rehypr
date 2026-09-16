#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_PATH="$(realpath -- "${BASH_SOURCE[0]}")"
readonly INSTALL_DIR="$(dirname -- "$SCRIPT_PATH")"
readonly REPO_DIR="$(dirname -- "$INSTALL_DIR")"
dry_run=false
migrate=false

usage() {
    printf 'Usage: %s [--dry-run] [--migrate] [--help]\n' "${0##*/}"
    printf 'Refresh the repository dotfile links in HOME. --dry-run only simulates changes.\n'
}

for arg in "$@"; do
    case "$arg" in
        --migrate) migrate=true ;;
        --dry-run) dry_run=true ;;
        -h | --help) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
    esac
done

command -v stow >/dev/null 2>&1 || {
    printf 'Required command was not found: stow\n' >&2
    exit 1
}

mapfile -t packages < "$INSTALL_DIR/stow-packages.txt"
((${#packages[@]})) || { printf 'The Stow package list is empty.\n' >&2; exit 1; }
for package in "${packages[@]}"; do
    [[ "$package" =~ ^[a-zA-Z0-9_-]+$ && -d "$REPO_DIR/dotfiles/$package" ]] || {
        printf 'Invalid or missing Stow package: %s\n' "$package" >&2
        exit 1
    }
done

command -v python3 >/dev/null 2>&1 || { printf 'Required command was not found: python3\n' >&2; exit 1; }
if $migrate; then
    args=()
    if $dry_run; then args+=(--dry-run); fi
    exec python3 "$INSTALL_DIR/migrate.py" "${args[@]}"
fi
python3 "$INSTALL_DIR/migrate.py" --check

stow --simulate --verbose --dir="$REPO_DIR/dotfiles" --target="$HOME" --restow "${packages[@]}"
if $dry_run; then
    exit 0
fi

mkdir -p -- "$HOME/.config" "$HOME/.local/share/themes"
stow --verbose --dir="$REPO_DIR/dotfiles" --target="$HOME" --restow "${packages[@]}"
