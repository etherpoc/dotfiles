{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    fd
    dust
    procs
    jq
    yq-go
    xh
    tldr
    # mise は programs.mise (シェル統合付き) で別途管理
  ];

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
    globalConfig = {
      settings = {
        experimental = true;
        idiomatic_version_file_enable_tools = [ "node" "python" "go" "rust" ];
      };
      tools = {
        node = "22";        # 現行 LTS。プロジェクトごとに上書き可
        python = "3.13";    # スクリプトや global tool 用の素の Python
        uv = "latest";      # 高速 Python パッケージマネージャ (pip / poetry / pyenv を一掃)
        pnpm = "latest";    # 効率的な Node パッケージマネージャ
        rust = "latest";    # rustup 経由で cargo / rustc / rust-std を一式
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    fileWidgetCommand = "fd --type f --hidden --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
      style = "numbers,changes,header";
    };
  };
}
