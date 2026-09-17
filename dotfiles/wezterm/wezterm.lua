-- Pull in the wezterm API
local wezterm = require("wezterm")

local mux = wezterm.mux

-- Pull Nerd  font
local nerd_font = require("wezterm").font("Moralerspace Neon")

-- This table will hold the configuration.
local config = {}

-- Pull files
local keybinds = require("keybinds")
require("format")
-- require 'status'
require("event")
require("tabline")

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

local is_windows = wezterm.target_triple == "x86_64-pc-windows-msvc"

if is_windows then
	-- Windows の場合は PowerShell を指定
	config.default_prog = { "pwsh.exe", "-NoLogo" }
else
	-- Linux の場合は fish を指定（Ubuntu の fish は /usr/bin にある）
	config.default_prog = { "/usr/bin/fish", "-l" }
end

-- config.default_prog = { 'wsl', '-d', 'Arch' }
config.color_scheme = "Catppuccin Frappe"
config.font = nerd_font
config.font_size = 14.0
config.line_height = 0.85
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_frame = {
  font = wezterm.font({ family = "Moralerspace Neon", weight = "Bold" }),
  font_size = 13.0,
  active_titlebar_bg = "#303446",
  inactive_titlebar_bg = "#292c3c",
  active_titlebar_fg = "#c6d0f5",
  inactive_titlebar_fg = "#737994",
  button_bg = "#303446",
  button_fg = "#c6d0f5",
  button_hover_bg = "#414559",
  button_hover_fg = "#c6d0f5",
}
config.window_background_opacity = 0.85
config.enable_scroll_bar = true
config.min_scroll_bar_height = "2cell"

-- Tab Bar
config.use_fancy_tab_bar = true
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false
config.tab_max_width = 30

config.status_update_interval = 1000

config.disable_default_key_bindings = true
config.keys = keybinds.keys
config.key_tables = keybinds.key_tables

config.quote_dropped_files = is_windows and 'WindowsAlwaysQuoted' or 'Posix'
config.exit_behavior = "Close"
config.exit_behavior_messaging = "None"

wezterm.on("gui-startup", function(cmd)
  -- 1つ目: default_prog（Windowsなら pwsh、Linux なら fish）
  local tab, pane, window = mux.spawn_window(cmd or {})

  -- 2つ目: WSL2 タブは Windows のときだけ開く
  if not is_windows then
    return
  end
  local wsl_tab, wsl_pane, _ = window:spawn_tab {
    args = { "wsl.exe", "-d", "Ubuntu-24.04" },
  }

  -- 起動直後に WSL タブへ移動したいなら有効化
  wsl_tab:activate()
end)

return config
