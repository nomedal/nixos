{ pkgs, ... }: {
  # Timezone and locale
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";

  # Networking
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };

  # SSH — all hosts managed via key auth only
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Tailscale on all hosts
  services.tailscale.enable = true;

  # Shell
  programs.zsh.enable = true;

  # Security
  security.sudo.wheelNeedsPassword = true;
  security.sudo.extraRules = [
    {
      users = [ "user" ];
      commands = [{
        command = "/run/current-system/sw/bin/nixos-rebuild";
        options = [ "NOPASSWD" ];
      }];
    }
  ];
  security.polkit.enable = true;

  # Core packages — all hosts
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    unzip
    p7zip
    htop
    btop
    fastfetch
    tree
    jq
    pv
    rsync
    eza
    tldr
    pciutils
    usbutils
    lshw
    iw
  ];
}
