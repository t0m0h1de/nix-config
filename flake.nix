{
  description = "My Stable Nix Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-zenn-cli.url = "github:t0m0h1de/nix-zenn-cli";

    # modem-dev/hunk: ターミナル差分ビューア CLI(バイナリ hunk)。独自 flake(bun2nix ビルド)を利用。
    # nixpkgs を follows させて重複を避ける(bun2nix は hunk の nixpkgs を follows)。
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixvim, nix-zenn-cli, hunk, ... }:
    let
      customOverlay = import ./overlays { inherit nix-zenn-cli hunk; };
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
