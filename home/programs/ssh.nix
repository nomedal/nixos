{ config, pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;        # ← This silences the warning

    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        AddKeysToAgent = "yes";
      };

      "*" = {
        AddKeysToAgent = "yes";
      };
    };
  };

  services.ssh-agent.enable = true;
}
