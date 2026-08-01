{ inputs, outputs, hostname, nome, ... }: {
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs outputs hostname nome; };
    users.user = import ../../home/${hostname}.nix;
  };
}
