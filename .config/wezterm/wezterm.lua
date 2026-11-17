-- WezTerm configuration.
-- Colours come from ~/.config/theme/palette.toml via `theme-apply`, which
-- generates colors/palette.toml here. This file is yours to hand-edit.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Generated scheme (see colors/palette.toml)
config.color_scheme = "Palette"

-- Typography
config.font = wezterm.font_with_fallback({
    "JetBrains Mono",
    "0xProto Nerd Font",
    "Symbols Nerd Font Mono",
    "Noto Color Emoji",
})
config.font_size = 11.5
config.line_height = 1.1

-- Surface: matches the Hyprland window treatment
config.window_background_opacity = 0.95
config.window_padding = { left = 14, right = 14, top = 12, bottom = 10 }
config.window_decorations = "NONE"

-- Tab bar: slim, themed by the generated scheme
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_max_width = 28
config.show_new_tab_button_in_tab_bar = false

-- Behaviour
config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.audible_bell = "Disabled"
config.check_for_updates = false
config.warn_about_missing_glyphs = false

return config
