-- WezTerm 設定。Windows ホスト側に手動で配置する単一情報源。
--
-- 配置先:
--   Windows: %USERPROFILE%\.wezterm.lua
--   macOS / Linux: ~/.config/wezterm/wezterm.lua  (Nix 経由で配置される)
--
-- 更新時は repo を pull したあと、PowerShell で次のコマンドを再実行:
--   Copy-Item -Path $env:USERPROFILE\dotfiles\windows\wezterm.lua `
--             -Destination $env:USERPROFILE\.wezterm.lua -Force

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Fonts: 英数字 → JetBrainsMono Nerd Font / 日本語 → PlemolJP Console NF
config.font = wezterm.font_with_fallback {
  'JetBrainsMono Nerd Font',
  'PlemolJP Console NF',
}
config.font_size = 12.0
config.line_height = 1.1

-- Theme
config.color_scheme = 'Catppuccin Mocha'

-- Window
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_decorations = 'RESIZE'
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false  -- タブ 1 個でもバーを残して、空白部分をドラッグして移動できるようにする
config.window_background_opacity = 0.97

-- WSL2: 起動時に Ubuntu の Zsh に入る。
-- WSL ドメインの default_cwd を明示しないと wezterm.exe 起動時の Windows 側 cwd
-- (=/mnt/c/Users/ether) で WSL に入ってしまい、9P 経由で遅くなる。
config.default_domain = 'WSL:Ubuntu'
config.wsl_domains = {
  {
    name = 'WSL:Ubuntu',
    distribution = 'Ubuntu',
    default_cwd = '/home/etherpoc',
  },
}

-- Keybindings (defaults + a few splits)
local act = wezterm.action
config.keys = {
  { key = 'd', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'D', mods = 'CTRL|SHIFT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
  { key = 'h', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left'  },
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
  { key = 'k', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up'    },
  { key = 'j', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down'  },
}

return config
