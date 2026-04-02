{
  description = "My Stable Nix Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim/nixos-25.05";
  };

  outputs = { self, nixpkgs, home-manager, nixvim, ... }: {
    homeConfigurations."linux" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        nixvim.homeModules.nixvim
        ./home.nix
      ];
    };

    homeConfigurations."darwin" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        nixvim.homeModules.nixvim
        ./home.nix
      ];
    };
  };
}
