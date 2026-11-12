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
- systemd user services, `dbus-update-activation-environment`,
  `xdg-desktop-portal`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`
- SwayNotificationCenter (`swaync`), NetworkManager applet and connection editor,
  Blueman
- WirePlumber (`wpctl`), `kcmshell6 kcm_pulseaudio`, `brightnessctl`, `playerctl`
- `grim`, `slurp`, `wl-copy`, `notify-send`, `xdg-user-dir`
- Noto Sans and Symbols Nerd Font Mono fonts (Waybar icons)
- Optional: `hyprshutdown`
- Optional: Apidog AppImage at `~/.local/bin/Apidog.AppImage`

## Hardware settings

The Material You appearance uses lavender primary accents, rounded tonal Waybar
controls, a matching Fuzzel launcher and Hyprlock screen, and soft window shadows.
Keyboard layouts, shortcuts, monitor assignments and existing panel actions are preserved.
This adapts the appearance to the existing Fedora desktop; the full HyprYou shell
and automatic wallpaper color generation are not installed.

The wallpaper `.config/hypr/wallpapers/material-you.jpg` comes from
[HyprYou](https://github.com/koeqaife/hyprland-material-you), whose license is
saved in `THIRD_PARTY/HyprYou-LICENSE`. The original Orbital wallpaper is retained.
`swaybg` displays the wallpaper at login (system executable or `~/.local/bin/swaybg`).

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

Run `systemctl --user daemon-reload` after restoring the systemd user target.
Hyprland runs `hypr/start-portals.sh` at login to export its display environment,
start `hyprland-session.target` (which activates `graphical-session.target`),
and start the desktop portal. It stops the session target at shutdown.
This Fedora installation does not ship a built-in `hyprland-session.target`;
the saved user target supplies it. The GTK portal provides the file picker,
allowing sandboxed apps such as Telegram to select real home-directory files.
To apply this to an existing session, run `sh ~/.config/hypr/start-portals.sh`
after `daemon-reload`, then fully quit and reopen Telegram.
If a future Hyprland package supplies automatic systemd session management,
remove this custom target and the startup/shutdown hooks in favor of it.

The Apidog launcher is saved separately under `.local/share/applications/`.
When restoring it for a different user, update its absolute Exec and Icon paths.
Its helper, `.config/hypr/launch-apidog.sh`, runs Apidog and its GTK file chooser
on native Wayland so they avoid XWayland blur when moving between the 100%
external display and the 150% laptop display. Quit and reopen Apidog from the
launcher after installing this change; existing processes retain their backend.
Apidog modal dialogs (including its file picker) float, center, and use 80% of
the monitor width and 75% of its height. When the AOC (`HDMI-A-1`) is connected
at config load, they open there. Otherwise they fit the selected display.

JetBrains Toolbox floats and opens centered on its monitor. Its main window
ignores X11 configure requests so tray placement cannot move it off-screen
with the external display to the left of the scaled laptop display.

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

## Material You polish

The notification button (or Super+N) opens the themed SwayNotificationCenter:
quick access to connections, Bluetooth, lock and power; volume with optional
per-app controls; laptop brightness; and media artwork when a player is active.
Its configuration and CSS are mirrored under `.config/swaync/`.
The stylesheet extends `/etc/xdg/swaync/style.css` (SwayNC 0.12.6).

The bar groups sound/brightness and connectivity into tonal capsules. The laptop
bar omits CPU/RAM readouts to fit the scaled screen; the external bar retains them.
Waybar's MPRIS module shows actual track information only when a player is available.
The application button opens Fuzzel; existing keyboard shortcuts stay the same.
Restore `.config/swaync/` alongside the other configs and reload SwayNC with
`swaync-client -R` and `swaync-client -rs`.

## CPU temperature

Both panels display AMD CPU Tctl temperature using Waybar's temperature module,
refreshed every five seconds. Amber starts at 80°C and red at 95°C; these are
display thresholds. The sensor is resolved under `/sys/devices/pci0000:00/0000:00:18.3/hwmon`
with `temp1_input`, so hwmon numbering changes do not affect it.
On different hardware, update `hwmon-path-abs` and `input-filename` in both bars.

## Notification popups

SwayNC's default popup timeout is 30 seconds for normal, low and critical
notifications. Expired popups remain in the notification center (Super+N).
Hovering pauses the popup timer; leaving starts it again. Applications that
explicitly request a positive expiration time override SwayNC's defaults.
