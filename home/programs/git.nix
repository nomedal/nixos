{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;

    # New settings structure
    settings = {
      user = {
        name = "Your Name";  # TODO: Change this
        email = "your.email@example.com";  # TODO: Change this
      };

      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;

      core = {
        editor = "nvim";
        autocrlf = "input";
      };

      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";

      # Aliases (moved under settings)
      alias = {
        st = "status -sb";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        lg = "log --oneline --graph --decorate --all";
        amend = "commit --amend --no-edit";
      };
    };
  };

  # Delta (now a separate program)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "gruvbox-dark";
    };
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };
}
