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

Colour is the exception: never hand-edit a generated `colors.*` file. Edit
`~/.config/theme/palette.toml`, run `theme-apply`, then `./sync.sh`. See
**Theming**.

## Programs used

- Hyprland with Lua configuration support, Hyprlock, Waybar, Python 3
- PyGObject, GTK 4, libadwaita and libnm introspection (Fedora: `python3-gobject`,
  `gtk4`, `libadwaita`, `NetworkManager-libnm`), plus `nmcli` for connection actions
- `flock` (util-linux), used to prevent duplicate Waybar supervisors
- `swaybg`, used to display the wallpaper on every monitor
- Fuzzel, WezTerm, kitty, Dolphin
- systemd user services, `dbus-update-activation-environment`,
  `xdg-desktop-portal`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`,
  `xdg-desktop-portal-kde` (file dialogs), `plasma-integration` (Qt theming)
- SwayNotificationCenter (`swaync`), NetworkManager applet and connection editor,
  Blueman
- WirePlumber (`wpctl`), `kcmshell6 kcm_pulseaudio`, `brightnessctl`, `playerctl`
- `grim`, `slurp`, `wl-copy`, `notify-send`, `xdg-user-dir`
- JetBrains Mono, Noto Sans and Symbols Nerd Font Mono (Waybar and terminals)
- `breeze-gtk` and `breeze-icon-theme` -- the GTK/Qt widget theme is recoloured
  from the palette rather than replaced (see **Theming**)
- Optional: `hyprshutdown`
- Optional: Apidog AppImage at `~/.local/bin/Apidog.AppImage`

## Theming

`.config/theme/palette.toml` is the single source of truth for colour; nothing
else contains a raw hex value. `theme-apply` renders every themed component and
live-reloads what it can:

```sh
theme-apply              # render all configs and reload
theme-apply --dry-run    # show what would change
theme-apply --check      # verify colour contracts only
```

Each component is themed through its own native include mechanism, so the
hand-edited configs stay hand-editable and are never overwritten -- only the
small generated colour file each one pulls in:

| Component | Mechanism | Generated |
| --- | --- | --- |
| Hyprland | `require("theme")` | `hypr/theme.lua` |
| Hyprlock | `source =` | `hypr/theme-colors.conf` |
| Waybar / SwayNC | `@import url()` | `*/colors.css` |
| Fuzzel | `include=` | `fuzzel/colors.ini` |
| WezTerm | `color_scheme =` | `wezterm/colors/palette.toml` |
| kitty | `include` | `kitty/current-theme.conf` |
| GTK 3/4 | `@import 'colors.css'` | `gtk-{3,4}.0/colors.css` |
| Qt / KDE | `[Colors:*]` blocks | `kdeglobals`, `color-schemes/*.colors` |
| Wallpaper | path file | `hypr/theme-wallpaper` |

A palette maps raw colours onto semantic names in three blocks -- `[roles]` for
UI surfaces, `[terminal]` for the sixteen ANSI slots, `[extra]` for cursor and
link colours. Renderers read only those mappings, never palette keys, so adding
a theme is a data change rather than a code change. `theme-apply` refuses to run
if a mapping points at a colour that does not exist.

Saved palettes: `palette-akane.toml` (current), `palette-kanagawa.toml`,
`palette-catppuccin-mocha.toml`. Switch with:

```sh
cp ~/.config/theme/palette-<name>.toml ~/.config/theme/palette.toml && theme-apply
```

Two details worth knowing. **GTK is Breeze-shaped but palette-coloured**: the
Breeze GTK theme references ~86 `@*_breeze` variables it never defines (upstream
they come from `colorreload-gtk-module` reading the KDE scheme), so we generate
them instead -- which is why GTK follows the palette with no Catppuccin or Akane
GTK package installed. Run `theme-apply --check` after a `breeze-gtk` update.
**Qt reads `kdeglobals`, not the `.colors` file**: `ColorScheme=` is only a
label, so applying a scheme means merging its `[Colors:*]` blocks into
`kdeglobals`, which `theme-apply` does.

Generated files are committed so a fresh clone works before `theme-apply` has
been run -- `hyprland.lua` calls `require("theme")` and Hyprland will not start
without `hypr/theme.lua`.

## Hardware settings

Appearance is driven entirely by `.config/theme/palette.toml` (see **Theming**
below). The current palette is **Akane**, ported from
[omarchy-akane-theme](https://github.com/Grenish/omarchy-akane-theme): vermillion
accents on dusk navy, with a warm foreground rather than grey. Waybar follows
omarchy's flat language -- no pills, solid ground, separation by margin.
Keyboard layouts, shortcuts, monitor assignments and existing panel actions are preserved.

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
the saved user target supplies it. File dialogs are routed to the KDE portal by
`.config/xdg-desktop-portal/hyprland-portals.conf`, which gives the Dolphin-style
chooser with a shared Places sidebar; screencopy stays with the Hyprland portal
and `org.freedesktop.impl.portal.Settings` stays with GTK so apps still read
"prefer dark". Sandboxed apps such as Telegram can still select real
home-directory files.
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

## Panel and notifications

The notification button (or Super+N) opens the themed SwayNotificationCenter:
quick access to connections, Bluetooth, lock and power; volume with optional
per-app controls; laptop brightness; and media artwork when a player is active.
Its configuration and CSS are mirrored under `.config/swaync/`.
The stylesheet extends `/etc/xdg/swaync/style.css` (SwayNC 0.12.6).

Both bars are now identical -- same height (28), same modules -- so the laptop no
longer runs a reduced set. Volume shows as `{icon} {volume}%`: scroll to adjust
in 5% steps, click to mute, right-click for sound settings. The brightness module
is hidden; its definition remains in `config.jsonc` and can be restored by
re-adding the name to `modules-right`. MPRIS is an icon-only transport button: it shows a pause
glyph while playing, a play glyph when paused, and hides itself when no player is
running. Click toggles, right-click skips, scroll moves between tracks.
The application button opens Fuzzel; existing keyboard shortcuts stay the same.
Restore `.config/swaync/` alongside the other configs and reload SwayNC with
`swaync-client -R` and `swaync-client -rs`.

## Lock, idle and sleep

**Super+L** runs `hypr/lock.sh`, which locks the session and then blanks the
displays. Any input wakes them -- Hyprland re-enables DPMS on activity.

The script goes through `loginctl lock-session` rather than calling `hyprlock`
directly, so the lock, the sleep hook and any idle timeout all run the same
code path. `hypridle` provides that path and must be running:

```sh
systemctl --user enable --now hypridle.service
```

Its unit ships with the `hypridle` package and is bound to
`graphical-session.target`, which `hyprland-session.target` activates.

`hypr/hypridle.conf` sets `before_sleep_cmd = loginctl lock-session`, so the
machine locks *before* suspending and never resumes onto an unlocked desktop --
this is what was missing when sleep did not appear to shut the UI down.
hypridle holds a sleep inhibitor until it observes the Wayland session lock
(via `ext-session-lock`, not `LockedHint`, which hyprlock does not set), then
releases it so suspend proceeds. `after_sleep_cmd` re-enables DPMS on resume.

Idle timeouts (lock, blank, suspend) are present in the config but commented
out; uncomment a `listener` block to enable one.

Note the dispatcher syntax. This configuration uses Hyprland's Lua API, where
`hyprctl dispatch dpms off` is parsed as Lua and fails. The working form is:

```sh
hyprctl dispatch 'hl.dsp.dpms("off")'
```

`hl.dsp.dpms("off")` on its own only *builds* a dispatcher object; `hyprctl
dispatch` is what wraps it in `hl.dispatch(...)` and executes it.

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

## Laptop layout

The laptop uses a 1600×900 logical desktop at 120% scale. The flat bar fits the
full module set at that width, which the previous rounded capsules could not --
removing the pill padding recovered roughly 40% of the horizontal space. The
external display runs the same bar at 100% scale.

The wallpaper is named by `theme/palette.toml` and resolved into
`hypr/theme-wallpaper`, which both `start-wallpaper.sh` and Hyprlock's
`$wallpaper` read -- so desktop and lock screen always agree. The original vector
wallpaper `hypr/wallpapers/lavender-dunes.svg` is retained as the fallback used
when a palette declares none. The wallpaper is run by the systemd user
unit `hypr-wallpaper.service`, started by `hypr/start-panel.sh`, and stopped
with the Hyprland session. After restoring run `systemctl --user daemon-reload`
and `systemctl --user start hypr-wallpaper.service` inside Hyprland.
The helper accepts system swaybg or `~/.local/bin/swaybg`.
