# rehypr

Personal Hyprland dotfiles for Arch Linux.

The setup uses Lua-based Hyprland configuration, GNU Stow, UWSM and a shared
Matugen color palette. It is made for my own hardware and workflow, so review
the monitor, input and autostart files before using it.

## Included

- Hyprland, Hypridle, Hyprlock and Hyprpaper;
- Waybar, Rofi, Mako and SwayOSD;
- Kitty and Fish;
- Impala, Bluetui, Wiremix, btop and Fastfetch;
- Nemo with File Roller and common archive formats;
- Zen Browser;
- Matugen themes for the desktop applications;
- PipeWire audio, NetworkManager and Bluetooth support;
- system-wide Alt/Super remapping through Keyd;
- helper scripts for screenshots, wallpapers and session controls.

## Install

Clone the repository to `~/.rehypr`:

```bash
git clone https://github.com/kumarukemuri/rehypr.git ~/.rehypr
cd ~/.rehypr
```

Preview and run the installer from any directory:

```bash
~/.rehypr/hyprland/.config/hypr/scripts/setup.sh --dry-run
~/.rehypr/hyprland/.config/hypr/scripts/setup.sh
```

The installer:

- compares the package lists with the current system and installs only missing packages;
- installs the minimal Hyprland desktop, terminal utilities and Zen Browser;
- installs `yay` when it is missing;
- enables NetworkManager and Bluetooth;
- enables the PipeWire, PipeWire Pulse and WirePlumber user units;
- installs the Keyd mapping to `/etc/keyd/hypr.conf` and starts Keyd;
- enables graphical-session user services for the Hyprland components;
- refreshes every dotfile package in the current user's home with `stow --restow`;
- sets Fish as the login shell;
- prepares automatic Hyprland startup on TTY1 through UWSM.

Use `--noconfirm` for non-interactive package installation. Run the script as
a regular user; it requests `sudo` only when needed.

`--dry-run` uses `pacman -Qq` to show which official and AUR packages are
already installed and which ones are missing. It does not install packages or
change system configuration.

The minimal package profile includes:

- desktop essentials: Hyprland, Waybar, Rofi, Kitty, Fish and Nemo;
- terminal tools: Impala, Bluetui, Wiremix, btop, Fastfetch, jq and less;
- archive support: File Roller, the Nemo extension, 7zip, unrar, unzip, zip and cpio;
- desktop integration: PipeWire, NetworkManager, Bluetooth, GVFS and UDisks;
- utilities required by the configuration, including ddcutil and GPU Screen Recorder.

The authoritative package lists are
[`core.txt`](hyprland/.config/hypr/scripts/packages/core.txt) and
[`aur.txt`](hyprland/.config/hypr/scripts/packages/aur.txt).

Before starting Hyprland, check these files:

- [`monitors.lua`](hyprland/.config/hypr/config/monitors.lua) — monitor names, positions and scaling;
- [`workspaces.lua`](hyprland/.config/hypr/config/workspaces.lua) — workspace-to-monitor mapping;
- [`input.lua`](hyprland/.config/hypr/config/input.lua) — keyboard, mouse and touchpad settings;
- [`autostart.lua`](hyprland/.config/hypr/config/autostart.lua) — programs started with Hyprland;
- [`windowrules.lua`](hyprland/.config/hypr/config/windowrules.lua) — application placement rules.

Display and input names can be found with:

```bash
hyprctl monitors
hyprctl devices
```

Existing files in `~/.config` may conflict with Stow. Back them up before
running the installer. When setup finishes, log out and sign in on TTY1;
Fish starts Hyprland automatically.

Waybar, Hyprpaper, Hypridle, Mako, SwayOSD, the per-window layout helper and
the GNOME Polkit agent run as systemd user services tied to the UWSM graphical
session. The installer enables them without starting them immediately.

PipeWire, PipeWire Pulse and WirePlumber are enabled and started immediately
in the user service manager. Keyd runs as a system service and maps both Alt
keys to Super while mapping the left Super key to Alt. Its source configuration
is [`system/keyd/hypr.conf`](system/keyd/hypr.conf).

## Optional post-install actions

### NZXT Kraken X63

The default installation does not install Liquidctl or enable the Kraken pump
service. To apply the bundled liquid-temperature pump curve at the start of the
user session, run:

```bash
sudo pacman -S --needed liquidctl
systemctl --user daemon-reload
systemctl --user enable --now liquidctl-kraken.service
```

Check the service and current cooler status with:

```bash
systemctl --user status liquidctl-kraken.service
liquidctl --match "Kraken X" status
```

## Keybindings

| Key | Action |
| --- | --- |
| `Super + Return` | Open Rofi |
| `Super + Escape` | Open Kitty or close the active special workspace |
| `Super + X` | Open Nemo |
| `Super + C` | Close the active window |
| `Super + F` | Toggle fullscreen |
| `Super + V` | Toggle floating mode |
| `Super + W/A/S/D` | Focus a window by direction |
| `Super + Shift + arrow` | Swap a window by direction |
| `Super + Delete` | Open the power menu |
| `Super + Shift + L` | Lock with Hyprlock |
| `Super + Shift + P` | Choose a wallpaper |
| `Super + Shift + C` | Pick a color |
| `Super + 1/2/3` | Focus workspace 1/2/3 |
| `Super + Q/E` | Focus workspace 4/5 |
| `Super + Shift + workspace key` | Move a window to that workspace |
| `Super + Tab` | Focus the next monitor |
| `Super + R` | Save the last 30 seconds of replay |
| `Print` | Screenshot all monitors |
| `Ctrl + Print` | Screenshot the active window |
| `Alt + Shift + S` | Screenshot a selected area |
| `Super + mouse button 1/2` | Move or resize a window |

See [`keybinds.lua`](hyprland/.config/hypr/config/keybinds.lua) for the complete
list, including volume, media and brightness controls.

## Wallpapers and colors

Press `Super + Shift + P` to choose an image from
`~/.config/hypr/wallpapers`.

The wallpaper script:

- applies the image to every configured monitor;
- updates the Hyprlock background;
- generates a dark Matugen palette;
- reloads the themed desktop components.

Matugen can also be run directly:

```bash
matugen image --mode dark /path/to/wallpaper.jpg
```

Templates for btop, Qt and Vesktop are kept even though those applications are
not all part of the minimal install. btop is installed by default; after
installing Vesktop, generate the palette again and enable
`midnight-discord.css` once in Vencord. Later palette changes update the same
file automatically.

## Terminal utilities

The minimal profile provides several focused TUI tools:

```bash
impala       # Wi-Fi and NetworkManager
bluetui      # Bluetooth
wiremix      # PipeWire audio routing
btop         # system monitor
fastfetch    # system summary
```

Monitor brightness over DDC/CI can be changed from Fish:

```fish
set_brightness 50             # all monitors
set_brightness main 50        # DP-1
set_brightness secondary 50   # DP-2 and HDMI-A-1
```

## Update

Pull changes and refresh the Stow links:

```bash
git -C "$HOME/.rehypr" pull --ff-only
mkdir -p "$HOME/.local/share/themes"
stow --dir="$HOME/.rehypr" --restow --target="$HOME" fish hyprland kitty mako mangohud matugen mimeapps qtct rofi swayosd themes uwsm waybar
```

Reload the running desktop configuration with:

```bash
~/.config/rofi/reloader.sh
```

To remove the links, run `stow --delete` with the same package list.

## Notes

- The current monitor layout expects `DP-1`, `DP-2` and `HDMI-A-1`.
- Workspaces 1–3 belong to `DP-1`, workspace 4 to `HDMI-A-1`, and workspace 5
  to `DP-2`.
- The keyboard layout switches between `us` and `ru` with Caps Lock.
- Kitty and Zen Browser start with the Hyprland session.
- Package installation is intended for Arch Linux and uses `sudo`, `pacman`
  and `yay`.
