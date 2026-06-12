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
      mkHome = { system, isWork ? false }: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ customOverlay ];
        };
        extraSpecialArgs = { inherit isWork; };
        modules = [
          nixvim.homeModules.nixvim
          ./home.nix
        ];
      };
    in
    {
      homeConfigurations = {
        linux = mkHome { system = "x86_64-linux"; };
        darwin = mkHome { system = "aarch64-darwin"; };
        work = mkHome { system = "aarch64-darwin"; isWork = true; };
      };
    };
}
