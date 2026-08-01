{
  description = "NixOS configuration for desktop (NVIDIA) and laptop (Intel Arc)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms.url = "github:AvengeMedia/DankMaterialShell";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:gerg-l/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    sysc-greet = {
      url = "github:Nomadcxx/sysc-greet";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotfiles = {
      url = "git+https://git.nomedal.com/nome/dotfiles.git";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, dms, disko, nixos-hardware, ... }@inputs:
    let
      nome = {
        lib.mkHome = import ./lib/mkHome.nix { inherit inputs; };
      };

      mkHost = { hostname, system ? "x86_64-linux", extraModules ? [] }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs hostname nome;
            outputs = self;
          };
          modules = [
            ./hosts/common
            ./hosts/${hostname}/configuration.nix
          ] ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        desktop = mkHost {
          hostname = "desktop";
          extraModules = [
            ./hosts/common/home-manager.nix
            ./modules/hardware/nvidia.nix
            disko.nixosModules.disko
            ./hosts/desktop/disko.nix
          ];
        };

        laptop = mkHost {
          hostname = "laptop";
          extraModules = [
            ./hosts/common/home-manager.nix
            ./modules/hardware/intel-arc.nix
          ];
        };

        rpi4 = mkHost {
          hostname = "rpi4";
          system   = "aarch64-linux";
          extraModules = [ nixos-hardware.nixosModules.raspberry-pi-4 ];
        };

      };
    };
}
