# Hyprland dotfiles

My Hyprland Lua configuration, Waybar panels, Fuzzel launcher, lock screen,
and desktop helper scripts. Configuration files retain their paths under `.config/`.

## Update before committing

Edit the live files in `~/.config/`, then run:

```sh
cd ~/Desktop/hyprland-dotfiles
./sync.sh
git diff
```

`sync.sh` copies the selected files from `${XDG_CONFIG_HOME:-$HOME/.config}`
into this folder. It overwrites the saved copies; it does not install files,
commit, or push. Backups, logs, and generated workspace state are excluded.
It also copies the Apidog application launcher from
`${XDG_DATA_HOME:-$HOME/.local/share}/applications/apidog.desktop`.
Future assistant changes to these live files should also run this command.

## Programs used

- Hyprland with Lua configuration support, Hyprlock, Waybar, Python 3
- PyGObject, GTK 4, libadwaita and libnm introspection (Fedora: `python3-gobject`,
  `gtk4`, `libadwaita`, `NetworkManager-libnm`), plus `nmcli` for connection actions
- `flock` (util-linux), used to prevent duplicate Waybar supervisors
- `swaybg`, used to display the sci-fi wallpaper on every monitor
- Fuzzel, WezTerm, Dolphin
- SwayNotificationCenter (`swaync`), NetworkManager applet and connection editor,
  Blueman
- WirePlumber (`wpctl`), `kcmshell6 kcm_pulseaudio`, `brightnessctl`, `playerctl`
- `grim`, `slurp`, `wl-copy`, `notify-send`, `xdg-user-dir`
- Noto Sans and Symbols Nerd Font Mono fonts (Waybar icons)
- Optional: `hyprshutdown`
- Optional: Apidog AppImage at `~/.local/bin/Apidog.AppImage`

## Hardware settings

The Orbital theme uses a generated wallpaper at
`.config/hypr/wallpapers/orbital-ring.png`, cyan/violet window borders, and
matching Waybar and Fuzzel colors. The panel startup script restores the
wallpaper at login. Install `swaybg` with your package manager when restoring;
the script also accepts a user-local executable at `~/.local/bin/swaybg`.

Hyprland starts the panel script automatically at login. The script keeps one
Waybar supervisor running for the Wayland session and restarts Waybar after an
unexpected exit, with a two-second delay between attempts. Logs are written to
`~/.local/state/hypr-panel/waybar.log` (or under `$XDG_STATE_HOME`).

The configuration currently uses `HDMI-A-1` for workspaces 1–5 and `eDP-1`
for workspaces 6–10. Monitor resolutions, refresh rates, positions, and scales
are set in `.config/hypr/hyprland.lua`.

Waybar uses battery `BAT0` and laptop backlight `amdgpu_bl1`. Both bars display
the laptop brightness control. The minimum brightness value is calculated for
this laptop's backlight. Adjust these settings for another machine.

## Restore

Install the required programs, back up the corresponding existing files under
`~/.config/`, then copy the contents of this repository's `.config/` there.
Review the monitor, battery, and backlight settings before reloading Hyprland
and Waybar. This configuration uses Hyprland's Lua API.

The Apidog launcher is saved separately under `.local/share/applications/`.
When restoring it for a different user, update its absolute Exec and Icon paths.
Its helper, `.config/hypr/launch-apidog.sh`, runs Apidog and its GTK file chooser
on native Wayland so they avoid XWayland blur when moving between the 100%
external display and the 150% laptop display. Quit and reopen Apidog from the
launcher after installing this change; existing processes retain their backend.
Apidog modal dialogs (including its file picker) float, center, and use 80% of
the monitor width and 75% of its height. When the AOC (`HDMI-A-1`) is connected
at config load, they open there. Otherwise they fit the selected display.

## Connections

Click the network icon on either bar or press **Super+Shift+N** to open the
Orbital connection manager (`hypr/connections.py`). Right-click the bar icon
or choose Advanced for the NetworkManager connection editor.

The manager shows nearby Wi-Fi with band, signal strength and weak-signal
warnings, plus saved Wi-Fi, Ethernet and VPN connections.
Active connections appear first under Current connections, with a Settings button.
There is no periodic refresh timer. Use Refresh for a new scan; connection and
scan-completion events update the display. Automatic connection settings remain
controlled by NetworkManager.
Connect, disconnect, toggle Wi-Fi, and use the switch beside a saved connection to change automatic
connection. Its menu provides settings, password entry and a confirmed Forget
action. Passwords are passed to NetworkManager through standard input, never
saved in these dotfiles. Existing profiles and credentials stay in NetworkManager.
