{ pkgs, ... }: {
  users.users.user = {
    isNormalUser = true;
    description = "User";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "audio"
      "video"
      "input"
      "wireshark"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6/z35czC0VJr3fGx17cSK5HE5G+13rCL9R3o4BnYnk m@nomedal.com"
    ];
  };
}
