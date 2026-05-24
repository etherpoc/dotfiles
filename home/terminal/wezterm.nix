{ config, lib, ... }:
let
  cfg = config.myEnv;
  weztermLua = builtins.readFile ../../windows/wezterm.lua;
in
{
  # WSL2 構成では WezTerm 本体も設定も Windows ホスト側で扱う。
  # windows/wezterm.lua を手動で %USERPROFILE%\.wezterm.lua にコピーする運用(README 参照)。
  # ここでは macOS / 非 WSL Linux でだけ Nix から本体 + 設定を入れる。
  config = lib.mkIf (!cfg.isWSL) {
    programs.wezterm = {
      enable = true;
      extraConfig = weztermLua;
    };
  };
}
