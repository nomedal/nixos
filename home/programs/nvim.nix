{ inputs, ... }: {
  xdg.configFile."nvim" = {
    source = "${inputs.dotfiles}/nvim";
    recursive = true;
  };
}
