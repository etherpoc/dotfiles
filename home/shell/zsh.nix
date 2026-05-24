{ ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      share = true;
    };

    shellAliases = {
      ls = "eza";
      ll = "eza -l --git";
      la = "eza -la --git";
      lt = "eza -T --git-ignore";
      cat = "bat --paging=never";
      grep = "rg";
      find = "fd";
      du = "dust";
      ps = "procs";
      lg = "lazygit";
      g = "git";
    };

    initContent = ''
      setopt AUTO_CD INTERACTIVE_COMMENTS NO_BEEP
      setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS

      bindkey -e
    '';
  };
}
