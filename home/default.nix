{ lib, ... }:
{
  imports = [
    ./shell/zsh.nix
    ./shell/starship.nix
    ./cli
    ./git
    ./ai
    ./terminal/wezterm.nix
    ./terminal/zellij.nix
    ./editor/neovim.nix
    ./fonts.nix
  ];

  options.myEnv = {
    isWSL = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "true when running inside WSL2 on a Windows host.";
    };
  };

  config = {
    programs.home-manager.enable = true;
  };
}
