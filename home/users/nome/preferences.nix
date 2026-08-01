{ ... }: {
  home.username = "user";
  home.homeDirectory = "/home/user";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
