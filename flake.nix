{
  description = "My Stable Nix Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-zenn-cli.url = "github:t0m0h1de/nix-zenn-cli";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixvim, nix-zenn-cli, ... }:
  let
    customOverlay = import ./overlays { inherit nix-zenn-cli; };
    mkPkgs = system: import nixpkgs {
      inherit system;
      overlays = [ customOverlay ];
    };
  in {
    homeConfigurations."linux" = home-manager.lib.homeManagerConfiguration {
      pkgs = mkPkgs "x86_64-linux";
      extraSpecialArgs = { isWork = false; };
      modules = [
        nixvim.homeModules.nixvim
        ./home.nix
      ];
    };

    homeConfigurations."darwin" = home-manager.lib.homeManagerConfiguration {
      pkgs = mkPkgs "aarch64-darwin";
      extraSpecialArgs = { isWork = false; };
      modules = [
        nixvim.homeModules.nixvim
        ./home.nix
      ];
    };
    
    homeConfigurations."work" = home-manager.lib.homeManagerConfiguration {
      pkgs = mkPkgs "aarch64-darwin";
      extraSpecialArgs = { isWork = true; };
      modules = [
        nixvim.homeModules.nixvim
        ./home.nix
      ];
    };
  };
}
