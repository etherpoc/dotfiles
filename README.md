# dotfiles

Nix + Home Manager で管理する個人開発環境。Windows 11 + WSL2 (Ubuntu) を主、macOS / Linux は将来追加。

---

## 構成

```
.
├── flake.nix                 # homeConfigurations を公開
├── hosts/
│   └── wsl-ubuntu/           # WSL2 用 host 設定
├── home/                     # Home Manager モジュール
│   ├── shell/{zsh,starship}.nix
│   ├── cli/                  # ripgrep, fd, fzf, zoxide, eza, bat, mise など
│   ├── git/                  # git, gh, lazygit, delta
│   ├── ai/                   # claude-code
│   ├── terminal/{wezterm,zellij}.nix
│   ├── editor/neovim.nix
│   └── fonts.nix
├── lazyvim/                  # LazyVim 設定。~/.config/nvim へ activation で symlink
├── windows/wezterm.lua       # Windows ホスト側に手動配置
└── scripts/register-zsh.sh   # /etc/shells 登録 + chsh の一回限りスクリプト
```

## 採用ツール

- **シェル**: Zsh + Starship(+ autosuggestions, syntax-highlighting)
- **ターミナル**: WezTerm(Windows 側) / 多重化は Zellij
- **エディタ**: Neovim + LazyVim、テーマは Catppuccin Mocha
- **CLI**: ripgrep, fd, fzf, zoxide, eza, bat, lazygit, delta, mise, gh, jq, yq, xh, tldr, dust, procs
- **AI**: Claude Code(Zellij の別ペインで使う前提)、GitHub Copilot(LazyVim Extras で後付け)
- **ランタイム**: mise で node / python / uv / pnpm / rust を global 管理
- **フォント**: JetBrainsMono Nerd Font + PlemolJP Console NF
- **配色**: Catppuccin Mocha で統一

## 役割分担

| レイヤー | 管理 |
|---|---|
| Windows ホスト(WSL2 / WezTerm 本体 / フォント) | winget + 手動 |
| WSL2 内の Ubuntu ユーザー領域 | Nix + Home Manager |
| `~/.wezterm.lua` | `windows/wezterm.lua` を PowerShell でコピー |
| `/etc/shells`, `chsh` など system 領域 | `scripts/register-zsh.sh`(一度だけ) |

---

## セットアップ

### 1. Windows 側

PowerShell(管理者)で:

```powershell
wsl --install -d Ubuntu
winget install --id wez.wezterm -e
winget install --id Git.Git -e
```

フォントは手動 DL してインストール:
- JetBrainsMono Nerd Font: https://www.nerdfonts.com/font-downloads
- PlemolJP_NF: https://github.com/yuru7/PlemolJP/releases

repo を clone して `wezterm.lua` を配置:

```powershell
git clone git@github.com:etherpoc/dotfiles.git $env:USERPROFILE\dotfiles
Copy-Item -Path $env:USERPROFILE\dotfiles\windows\wezterm.lua `
          -Destination $env:USERPROFILE\.wezterm.lua -Force
```

PC を再起動 → スタートメニューから Ubuntu を初回起動 → Unix ユーザー名(`etherpoc`)とパスワードを設定。

### 2. WSL2 内

```bash
sudo apt update && sudo apt install -y curl git xz-utils

# Nix (Determinate Systems Installer)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
# → 新しいシェルを開き直す

git clone git@github.com:etherpoc/dotfiles.git ~/dotfiles
cd ~/dotfiles
nix run home-manager/master -- switch --flake .#wsl-ubuntu --impure

# シェル切替(/etc/shells 登録 + chsh、sudo パスを 1 度聞かれる)
bash scripts/register-zsh.sh

# mise 管理の runtime を取得
mise install

# Claude Code 認証
claude

# Copilot 認証
nvim
# :Copilot auth
```

`--impure` は `home.username` を `$USER` から取るために必要。

---

## 日常運用

```bash
# 設定を変えた時
cd ~/dotfiles
$EDITOR home/...
nix run home-manager/master -- switch --flake .#wsl-ubuntu --impure
git add . && git commit -m "..." && git push

# パッケージ更新
nix flake update
nix run home-manager/master -- switch --flake .#wsl-ubuntu --impure
git add flake.lock && git commit -m "Update flake.lock" && git push

# mise 管理の runtime 更新
mise upgrade
```

LazyVim 設定(`lazyvim/`)は symlink なので、編集すれば `home-manager switch` 不要で即反映。

---

## トラブルシュート

| 症状 | 対処 |
|---|---|
| `experimental Nix feature 'nix-command' is disabled` | `mkdir -p ~/.config/nix && echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf` |
| `home-manager switch` で `path ... is not part of a flake` | 違うブランチに居る or `~/dotfiles` 以外にいる |
| `[nvim] ... exists and is not a symlink` | `~/.config/nvim` が実ディレクトリで残っている → `mv ~/.config/nvim ~/.config/nvim.bak && ln -s ~/dotfiles/lazyvim ~/.config/nvim` |
| `chsh: invalid shell` | `scripts/register-zsh.sh` を実行 |
| `wezterm.lua` の更新が反映されない | PowerShell でステップ 1 の `Copy-Item` を再実行 |

---

## TODO

- [ ] `windows/bootstrap.ps1` — winget / フォント / WSL2 / wezterm.lua 配置を冪等にまとめる
- [ ] `install.sh` — WSL2 内の Nix 導入から home-manager switch までを一気通貫
- [ ] macOS 対応(`hosts/macbook/`、Home Manager のみで開始)
- [ ] bat / delta の Catppuccin Mocha テーマファイル取り込み
- [ ] Zellij `dev.kdl` レイアウトに Neovim / Claude Code / shell ペインを配置
