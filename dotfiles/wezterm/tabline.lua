local wezterm = require 'wezterm'

-- tabline.wez
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
tabline.setup({
  options = {
    icons_enabled = false,
    theme = "Catppuccin Frappe",
    tabs_enabled = true,
    color_overrides = {
      tab = {
        active = { bg = "#4a4f6a", fg = "#e2e6f8" },
        inactive = { bg = "#393d54", fg = "#a5adce" },
        inactive_hover = { bg = "#444860", fg = "#e2e6f8" },
      },
      normal_mode = { bg = "#575c78", fg = "#e2e6f8" },
    },
    section_separators = {
      left = "",
      right = "",
    },
    component_separators = {
      left = "",
      right = "",
    },
    tab_separators = {
      left = "",
      right = "",
    },
  },
  sections = {
    tabline_a = {},
    tab_active = {
      'index',
      { 'process', padding = { left = 1, right = 1 } },
    },
    tab_inactive = {
      'index',
      { 'process', padding = { left = 1, right = 1 } },
    },
    tabline_x = {},
    tabline_y = {
      'datetime',
      style = '%H:%M',
    },
    tabline_z = {},
  },
})
