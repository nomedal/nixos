{
  description = "NixOS configuration for desktop (NVIDIA) and laptop (Intel Arc)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plasma Manager for declarative KDE config
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, home-manager, plasma-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      # Helper function to create NixOS configurations
      mkHost = { hostname, extraModules ? [] }: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${hostname}/configuration.nix
          ./modules/base.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.user = import ./home/home.nix;
          }
        ] ++ extraModules;
      };
    in
    {
      nixosConfigurations = {
        # Desktop with NVIDIA GPU
        desktop = mkHost {
          hostname = "desktop";
          extraModules = [ ./modules/hardware/nvidia.nix ];
        };

        # Laptop with Intel Arc
        laptop = mkHost {
          hostname = "laptop";
          extraModules = [ ./modules/hardware/intel-arc.nix ];
        };
      };
    };
}
