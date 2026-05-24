#!/usr/bin/env bash
# Nix で入れた zsh を /etc/shells に登録し、ログインシェルを切り替える。
# Home Manager は user 権限で動くので /etc/shells 編集と chsh はできない。
# このスクリプトを一度だけ手動で実行する(初回 home-manager switch の直後)。
#
# Usage:
#   bash scripts/register-zsh.sh
#
# 冪等: 何度実行しても安全。

set -euo pipefail

ZSH_PATH="$HOME/.nix-profile/bin/zsh"

if [ ! -x "$ZSH_PATH" ]; then
  echo "Error: $ZSH_PATH not found or not executable." >&2
  echo "       Run 'nix run home-manager/master -- switch --flake .#wsl-ubuntu --impure' first." >&2
  exit 1
fi

# 1. /etc/shells に登録
if grep -Fxq "$ZSH_PATH" /etc/shells; then
  echo "[register-zsh] $ZSH_PATH is already in /etc/shells."
else
  echo "[register-zsh] Adding $ZSH_PATH to /etc/shells (sudo password may be required)..."
  echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

# 2. ログインシェルを変更
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
  echo "[register-zsh] Login shell is already $ZSH_PATH."
else
  echo "[register-zsh] Changing login shell from $CURRENT_SHELL to $ZSH_PATH..."
  # chsh は Ubuntu の PAM 設定で root でも認証を要求することがあるため、
  # usermod で /etc/passwd を直接書き換える。
  sudo usermod -s "$ZSH_PATH" "$USER"
fi

echo
echo "Done. Open a new terminal session (or run 'exec zsh -l') to start using zsh."
