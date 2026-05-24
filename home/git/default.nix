{ ... }:
{
  programs.git = {
    enable = true;

    settings = {
      user.name = "etherpoc";
      user.email = "etherpoc@users.noreply.github.com";

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.autocrlf = "input";
      rerere.enabled = true;

      alias = {
        st = "status -sb";
        lg = "log --oneline --graph --decorate --all";
        cm = "commit -m";
        co = "checkout";
        br = "branch";
        sw = "switch";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = true;
      syntax-theme = "ansi";
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      prompt = "enabled";
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      gui.theme = {
        activeBorderColor = [ "#cba6f7" "bold" ];
        inactiveBorderColor = [ "#6c7086" ];
        selectedLineBgColor = [ "#313244" ];
      };
    };
  };
}
