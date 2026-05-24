{ config, lib, pkgs, ... }:
{
  # programs.neovim.enable は使わない。LazyVim 設定 (~/.config/nvim) 全体を repo の
  # lazyvim/ に symlink したいが、programs.neovim を有効にすると HM が
  # ~/.config/nvim/init.lua などを送り込んでディレクトリを占拠してしまい、
  # symlink への置き換えと衝突する。代わりに neovim と依存ツールを直接入れる。
  home.packages = with pkgs; [
    neovim
    gcc
    gnumake
    unzip
    nodejs
    # ripgrep, fd, lazygit は home/cli, home/git 側で入る
  ];

  home.sessionVariables.EDITOR = "nvim";
  home.shellAliases = {
    vi = "nvim";
    vim = "nvim";
  };

  # LazyVim 設定は repo の lazyvim/ を ~/.config/nvim に symlink。
  # lazy.nvim が lazy-lock.json を書き戻すため Nix store 経由にできず、
  # activation 時に直接 ln -s する。空ディレクトリは安全に置き換える。
  home.activation.linkNvimConfig =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      src="${config.home.homeDirectory}/dotfiles/lazyvim"
      dst="${config.xdg.configHome}/nvim"
      if [ ! -d "$src" ]; then
        echo "[nvim] $src not found; skipping symlink." >&2
      elif [ -L "$dst" ]; then
        run ln -sfn "$src" "$dst"
      elif [ -d "$dst" ] && [ -z "$(ls -A "$dst" 2>/dev/null)" ]; then
        run rmdir "$dst"
        run ln -s "$src" "$dst"
      elif [ -e "$dst" ]; then
        echo "[nvim] $dst exists and is not empty; not overwriting." >&2
      else
        run mkdir -p "$(dirname "$dst")"
        run ln -s "$src" "$dst"
      fi
    '';
}
