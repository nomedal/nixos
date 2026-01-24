{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=8";
    };
    syntaxHighlighting.enable = true;

    # Use XDG config directory for zsh files
    dotDir = "${config.xdg.configHome}/zsh";

    history = {
      size = 50000;
      save = 50000;
      path = "${config.home.homeDirectory}/.zsh_history";
      share = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
    };

    shellAliases = {
      # General
      ll = "ls -lh";
      la = "ls -lha";
      ".." = "cd ..";
      "..." = "cd ../..";
      c = "clear";
      please = "sudo $(fc -ln -1)";

      # Modern replacements
      ls = "eza --icons";
      cat = "bat";
      grep = "rg";
      find = "fd";

      # NixOS
      nrs = "sudo nixos-rebuild switch --flake .#";
      nrb = "sudo nixos-rebuild boot --flake .#";
      nrt = "sudo nixos-rebuild test --flake .#";
      ncg = "sudo nix-collect-garbage -d";
      nfu = "nix flake update";

      # Git shortcuts
      gs = "git status -sb";
      gl = "git log --oneline --graph --decorate";
      gc = "git commit";
      gco = "git checkout";
      gp = "git push";
      gpl = "git pull";
      ga = "git add";
      gaa = "git add --all";
      gd = "git diff";
      gds = "git diff --staged";
    };

    # New unified initContent with ordering via lib.mkBefore/mkAfter
    initContent = lib.mkMerge [
      # This runs first (instant prompt)
      (lib.mkBefore ''
        # Enable Powerlevel10k instant prompt
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      # This runs after (main config)
      ''
        # Better history search
        bindkey -e
        bindkey '^[[A' history-search-backward
        bindkey '^[[B' history-search-forward

        # Completion styling
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' group-name '''
        zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'

        # LS colors
        export LS_COLORS="$LS_COLORS:di=1;34:ln=36:so=35:pi=33:ex=1;32:bd=34;46:cd=34;43:su=37;41:sg=30;43:tw=30;42:ow=34;42"

        # Add local bin to path
        [[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)
        [[ -d "$HOME/bin" ]] && path=("$HOME/bin" $path)

        # Initialize zoxide (smarter cd)
        eval "$(zoxide init zsh)"

        # Source Powerlevel10k theme
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

        # Load p10k config if it exists
        [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
      ''
    ];

    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions;
        file = "share/zsh-completions/zsh-completions.zsh";
      }
    ];
  };

  # Powerlevel10k
  home.packages = [ pkgs.zsh-powerlevel10k ];

  # Copy your p10k config
  home.file.".p10k.zsh".source = ../../.p10k.zsh;
}
