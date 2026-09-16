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

## Repository layout

- `dotfiles/` contains GNU Stow packages mirroring paths under the user's home.
- `install/` contains setup, migration, package lists, Qt templates and
  system-wide Keyd configuration. These files are not linked into the home.
- Runtime helpers remain inside their application packages.

Setup requires Python 3 (`python` on Arch) for migration checks.
The isolated regression checks are `python3 install/tests/test_layout.py` and
`python3 install/tests/test_setup.py` (the latter also requires Matugen).

## Install

The entry point is [`hyprland.lua`](dotfiles/hyprland/.config/hypr/hyprland.lua).
This configuration requires Hyprland with support for the Lua `hl` API used
in the repository.

Clone the repository to `~/.rehypr`:

```bash
git clone https://github.com/kumarukemuri/rehypr.git ~/.rehypr
cd ~/.rehypr
```

Run `./install/setup.sh` from the repository root to choose installation,
restow, migration or exit from a numbered menu. Without an explicit action,
`--dry-run` also shows the menu and previews the selected action. EOF cancels
without making changes. Use the action flags below for non-interactive use.

Preview and run the installer from any directory:

```bash
~/.rehypr/install/setup.sh --install --dry-run
~/.rehypr/install/setup.sh --install
```

The installer:

- compares the package lists with the current system and installs only missing packages;
- installs the minimal Hyprland desktop, terminal utilities and Zen Browser;
- installs `yay` when it is missing;
- enables NetworkManager and Bluetooth;
- enables the PipeWire, PipeWire Pulse and WirePlumber user units;
- installs the Keyd mapping to `/etc/keyd/hypr.conf` and starts Keyd;
- enables graphical-session user services for the Hyprland components;
- checks for Stow conflicts before installation when Stow is available, and again
  after package installation before linking files;
- initializes missing application and Hyprland colors without reloading the desktop,
  reusing the existing `$image` when available and falling back to `woods.jpg`;
- creates Qt settings with palette paths for the current user;
- refreshes every dotfile package in the current user's home with `stow --restow`;
- sets Fish as the login shell;
- prepares automatic Hyprland startup on TTY1 through UWSM.

Use `--noconfirm` for non-interactive package installation. Run the script as
a regular user; it requests `sudo` only when needed.

`--dry-run` uses `pacman -Qq` to show which official and AUR packages are
already installed and which ones are missing. It does not install packages or
change system configuration. If Stow is available, it also simulates linking
the dotfiles and reports conflicts.

The minimal package profile includes:

- desktop essentials: Hyprland, Waybar, Rofi, Kitty, Fish and Nemo;
- terminal tools: Impala, Bluetui, Wiremix, btop, Fastfetch, jq and less;
- archive support: File Roller, the Nemo extension, 7zip, unrar, unzip, zip and cpio;
- desktop integration: PipeWire, NetworkManager, Bluetooth, GVFS and UDisks;
- utilities required by the configuration, including ddcutil and GPU Screen Recorder.

The authoritative package lists are
[`core.txt`](install/packages/core.txt) and
[`aur.txt`](install/packages/aur.txt).

Before starting Hyprland, check these files:

- [`outputs.lua`](dotfiles/hyprland/.config/hypr/config/outputs.lua) — shared main, left and right output names for Lua configs;
- [`monitors.lua`](dotfiles/hyprland/.config/hypr/config/monitors.lua) — monitor names, positions and scaling;
- [`workspaces.lua`](dotfiles/hyprland/.config/hypr/config/workspaces.lua) — workspace-to-monitor mapping;
- [`input.lua`](dotfiles/hyprland/.config/hypr/config/input.lua) — keyboard, mouse and touchpad settings;
- [`autostart.lua`](dotfiles/hyprland/.config/hypr/config/autostart.lua) — programs started with Hyprland;
- [`windowrules.lua`](dotfiles/hyprland/.config/hypr/config/windowrules.lua) — application placement rules.

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
is [`install/system/keyd/hypr.conf`](install/system/keyd/hypr.conf).

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

### GPU Screen Recorder replay

The bundled [replay service](dotfiles/hyprland/.config/systemd/user/gpu-screen-recorder-replay.service)
records `DP-1` at 60 FPS with a 120-second RAM buffer, HEVC video and Opus
audio, saving MP4 clips to `~/Videos/Replays`. Its audio filter excludes
Discord, Vesktop, Telegram, Zen, Spotify, Mattermost and Steam.

The installer installs GPU Screen Recorder but does not enable this service.
Review the monitor and recording options in the unit, then enable it from a
running graphical session:

```bash
mkdir -p "$HOME/Videos/Replays"
systemctl --user daemon-reload
systemctl --user enable --now gpu-screen-recorder-replay.service
systemctl --user status gpu-screen-recorder-replay.service
```

`Super + R` calls `~/.local/bin/save-gsr-replay`, which is not included in this
repository. Provide that helper or update the binding before using the shortcut.
The keybinding comment still mentions 30 seconds; the service configures 120.

## Keybindings

Modifiers below refer to the logical keys after Keyd remapping: physical Alt
acts as `Super`, and physical left Super acts as `Alt`.

| Key | Action |
| --- | --- |
| `Super + Return` | Open Rofi |
| `Super + Escape` | Open Kitty |
| `Super + X` | Open Nemo |
| `Super + C` | Close the active window |
| `Super + F` | Toggle fullscreen |
| `Super + V` | Toggle floating mode |
| `Super + W/A/S/D` | Focus a window by direction |
| `Super + Shift + W/S` | Swap a window up/down |
| `Super + Shift + A/D` | Swap a window right/left |
| `Super + Delete` | Open the power menu |
| `Super + Shift + Delete` | Reload Hyprland and desktop services |
| `Super + Shift + L` | Lock with Hyprlock |
| `Super + Shift + P` | Choose a wallpaper |
| `Super + Shift + C` | Pick a color |
| `Super + 1/2/3` | Focus workspace 1/2/3 |
| `Super + Q/E` | Focus workspace 4/5 |
| `Super + Shift + workspace key` | Move a window to that workspace |
| `Super + Tab` | Focus the next monitor |
| `Super + R` | Run the external replay-save helper (see above) |
| `Print` | Screenshot the focused monitor |
| `Ctrl + Print` | Screenshot the active window |
| `Alt + Shift + S` | Screenshot a selected area |
| `Super + mouse button 1/2` | Move or resize a window |

See [`keybinds.lua`](dotfiles/hyprland/.config/hypr/config/keybinds.lua) for the complete
list, including volume, media and brightness controls.

Screenshots are copied to the clipboard and saved as timestamped PNG files in
`$(xdg-user-dir PICTURES)/Screenshots`, falling back to `~/Pictures/Screenshots`
when `xdg-user-dir` is unavailable. Area selection freezes the image while selecting.

## Wallpapers and colors

Press `Super + Shift + P` to choose an image from
`~/.config/hypr/wallpapers`.

The wallpaper script:

- applies the image to every configured monitor;
- generates a dark Matugen palette and writes `$image` to `~/.config/hypr/colors.conf`;
- shares that variable between Hyprpaper and Hyprlock without rewriting their configs;
- reloads Hyprland once and restarts only active Mako, Waybar and SwayOSD services.

Theme changes leave Hypridle, Polkit and the per-window layout helper running.
Generated Hyprland colors are local files ignored by Git, so choosing a wallpaper
does not change tracked configuration files.

Matugen can also generate the palette directly. Apply the generated colors
with the theme-only reload command:

```bash
matugen image --mode dark --prefer darkness --type scheme-tonal-spot /path/to/wallpaper.jpg
~/.config/rofi/reloader.sh --theme
```

This direct command sequence updates colors. Use the wallpaper picker to also
apply the image to the running Hyprpaper session.

btop and Qt color templates are included in the default setup. Vesktop is
optional; after installing it, generate the palette again and enable
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
set_brightness sec 50         # DP-2 and HDMI-A-1
```

The [brightness function](dotfiles/fish/.config/fish/functions/set_brightness.fish)
uses fixed I²C bus numbers: `7` for the main monitor and `4`/`8` for the
secondary monitors. Run `ddcutil detect` and adjust those numbers for your
hardware before using it.

## Update

When updating from the old repository layout, migrate links once after pulling:

```bash
./install/setup.sh --migrate --dry-run
./install/setup.sh --migrate
```

Migration replaces only links into the old layout of this checkout. It preserves
local generated files, restores legacy Qt links as ordinary settings, and updates
wallpaper paths inside generated Hyprland palettes. Conflicting files stop the
migration before links change. Backups and a path manifest are stored under
`${XDG_STATE_HOME:-$HOME/.local/state}/rehypr/migration-*`; failed application
restores the original links. Old local source files are retained for inspection.
If a Qt color directory was lost, choose a wallpaper again to regenerate colors.
Migration does not install packages or restart the desktop.

For subsequent updates, pull changes and refresh the Stow links:


```bash
git -C "$HOME/.rehypr" pull --ff-only
"$HOME/.rehypr/install/setup.sh" --restow --dry-run
"$HOME/.rehypr/install/setup.sh" --restow
```

From the repository root, use `./install/setup.sh --restow`. The script also works from any
other directory and checks for conflicts before changing links. All actions use
[`install/stow-packages.txt`](install/stow-packages.txt),
excluding README and service-only directories. The restow action does not install packages,
migrate Qt settings or restart services.

Qt5ct and Qt6ct settings are created from `install/templates/qtct/*.conf.in` by setup.
Their working configs are local files; repeated setup updates only the palette
path and preserves other settings. Run setup once when updating from the older
Stow-managed Qt configuration. Existing files and symlinks are preserved.

If package lists or installer actions changed, rerun `./install/setup.sh --install --dry-run`
and then `./install/setup.sh --install` to apply them.

Reload the running desktop configuration with:

```bash
~/.config/rofi/reloader.sh
```

To remove the links, run `stow --delete` with the packages listed in
`install/stow-packages.txt`.

## Notes

- The current monitor layout expects `DP-1`, `DP-2` and `HDMI-A-1`.
- Workspaces 1–3 use Dwindle on `DP-1`; workspace 4 on `HDMI-A-1` and
  workspace 5 on `DP-2` use vertical scrolling. Workspace 7 also maps to
  `HDMI-A-1` with Dwindle.
- The keyboard layout switches between `us` and `ru` with Caps Lock.
- Autostart launches Kitty, Zen Browser and Mattermost Desktop. Mattermost
  is not in the package lists; install it separately or remove its autostart entry.
- Hypridle turns displays off after 60 seconds of inactivity and restores them
  on activity. It locks before sleep; there is no timed idle-lock listener.
- Package installation is intended for Arch Linux and uses `sudo`, `pacman`
  and `yay`.
