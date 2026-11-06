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

`sync.sh` copies the nine selected files from `${XDG_CONFIG_HOME:-$HOME/.config}`
into this folder. It overwrites the saved copies; it does not install files,
commit, or push. Backups, logs, and generated workspace state are excluded.
Future assistant changes to these live files should also run this command.

## Programs used

- Hyprland with Lua configuration support, Hyprlock, Waybar, Python 3
- Fuzzel, WezTerm, Dolphin
- SwayNotificationCenter (`swaync`), NetworkManager applet and connection editor,
  Blueman
- WirePlumber (`wpctl`), `kcmshell6 kcm_pulseaudio`, `brightnessctl`, `playerctl`
- `grim`, `slurp`, `wl-copy`, `notify-send`, `xdg-user-dir`
- Noto Sans font
- Optional: `hyprshutdown`

## Hardware settings

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
