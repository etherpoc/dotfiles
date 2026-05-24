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
├── windows/
│   ├── bootstrap.ps1         # Windows ホスト側の冪等セットアップ (管理者 PS で実行)
│   └── wezterm.lua           # bootstrap.ps1 が %USERPROFILE%\.wezterm.lua に配置
└── scripts/
    ├── install.sh            # WSL2 内の Nix 導入 〜 home-manager switch を一気通貫
    └── register-zsh.sh       # /etc/shells 登録 + chsh (install.sh から呼ばれる)
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

管理者 PowerShell で:

```powershell
irm https://raw.githubusercontent.com/etherpoc/dotfiles/main/windows/bootstrap.ps1 | iex
```

`windows/bootstrap.ps1` がやること(冪等):
- winget で WSL2 + Ubuntu / WezTerm / Git / Windows Terminal をインストール
- JetBrainsMono Nerd Font と PlemolJP Console NF をユーザースコープで配置
- repo を `$env:USERPROFILE\dotfiles` に clone
- `windows/wezterm.lua` を `%USERPROFILE%\.wezterm.lua` にコピー

完了後、必要なら PC 再起動 → スタートメニューから WezTerm を起動(Ubuntu 初回ならその場で Unix ユーザー(`etherpoc`)とパスワードを聞かれる)。

### 2. WSL2 内

```bash
curl -fsSL https://raw.githubusercontent.com/etherpoc/dotfiles/main/scripts/install.sh | bash
```

`scripts/install.sh` がやること(冪等):
- apt prereqs(curl / git / xz-utils)
- Nix を Determinate Systems Installer でインストール
- repo を `~/dotfiles` に clone(既にあれば pull)
- `nix run home-manager/master -- switch --flake .#wsl-ubuntu --impure`
- `scripts/register-zsh.sh` で `/etc/shells` 登録 + `chsh`
- `mise install` で global runtime を取得

完了後の手動ステップは Claude Code 認証(`claude`)と Copilot 認証(`nvim` → `:Copilot auth`)のみ。

> `--impure` は `home.username` を `$USER` から取るために必要。

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

- [ ] macOS 対応(`hosts/macbook/`、Home Manager のみで開始)
- [ ] bat / delta の Catppuccin Mocha テーマファイル取り込み
- [ ] Zellij `dev.kdl` レイアウトに Neovim / Claude Code / shell ペインを配置
