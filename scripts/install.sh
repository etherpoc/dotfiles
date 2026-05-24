#!/usr/bin/env bash
# WSL2 (Ubuntu) bootstrap. clone から home-manager switch までを一気通貫。
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/etherpoc/dotfiles/main/scripts/install.sh | bash
#
#   または手動 clone 後:
#   bash ~/dotfiles/scripts/install.sh
#
# 冪等: 既にインストール済みのステップはスキップする。

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/etherpoc/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
HOST="${HOST:-wsl-ubuntu}"

step() { printf "\n\e[1;36m=== %s ===\e[0m\n" "$1"; }

# 1. apt prereqs
step "Installing apt prerequisites"
sudo apt update
sudo apt install -y curl git xz-utils

# 2. Nix (Determinate Systems Installer)
if ! command -v nix >/dev/null 2>&1; then
  step "Installing Nix (Determinate Systems Installer)"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
else
  step "Nix already installed; skipping"
fi

# experimental-features を念のためユーザ設定にも書く(Determinate ならシステム側で有効化済みだが防御的に)
mkdir -p "$HOME/.config/nix"
if ! grep -qs "experimental-features" "$HOME/.config/nix/nix.conf" 2>/dev/null; then
  echo "experimental-features = nix-command flakes" >> "$HOME/.config/nix/nix.conf"
fi

# 3. Clone or update repo
if [ -d "$DOTFILES_DIR/.git" ]; then
  step "Repo exists at $DOTFILES_DIR; pulling latest"
  git -C "$DOTFILES_DIR" pull --ff-only
else
  step "Cloning $REPO_URL to $DOTFILES_DIR"
  git clone "$REPO_URL" "$DOTFILES_DIR"
fi
cd "$DOTFILES_DIR"

# 4. Home Manager switch
step "Running home-manager switch (host: $HOST)"
nix run home-manager/master -- switch --flake ".#$HOST" --impure

# 以降のステップで Nix 管理下のバイナリ(mise 等)を使うため PATH を明示
export PATH="$HOME/.nix-profile/bin:$PATH"

# 5. Zsh をログインシェルに(/etc/shells 登録 + chsh)
step "Registering Zsh as login shell"
bash "$DOTFILES_DIR/scripts/register-zsh.sh"

# 6. mise の global runtime インストール
if command -v mise >/dev/null 2>&1; then
  step "Installing mise-managed runtimes (node / python / uv / pnpm / rust)"
  mise install
fi

cat <<'EOF'

=== Setup complete ===

残りの手動ステップ:
  1. Claude Code 認証:
       claude
  2. GitHub Copilot 認証 (Neovim 内):
       nvim
       :Copilot auth
  3. 新規ターミナルを開いて Zsh + 新 PATH を反映

EOF
