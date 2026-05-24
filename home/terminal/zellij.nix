{ ... }:
{
  programs.zellij = {
    enable = true;
    settings = {
      theme = "catppuccin-mocha";
      default_shell = "zsh";
      default_layout = "default";
      pane_frames = false;
      simplified_ui = false;
      copy_on_select = true;
    };
  };

  xdg.configFile."zellij/layouts/dev.kdl".text = ''
    layout {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        pane split_direction="vertical" {
            pane size="70%" name="editor"
            pane split_direction="horizontal" size="30%" {
                pane name="ai"
                pane name="shell"
            }
        }
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
  '';
}
