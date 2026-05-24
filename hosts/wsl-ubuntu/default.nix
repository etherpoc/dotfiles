{ lib, ... }:
let
  # $USER から自動検出する。--impure フラグが必要 (なければフォールバック)。
  envUser = builtins.getEnv "USER";
  user = if envUser != "" then envUser else "etherpoc";
in
{
  imports = [ ../../home ];

  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "25.05";

  myEnv.isWSL = true;
}
