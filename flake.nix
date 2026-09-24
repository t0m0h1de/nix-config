{
  description = "My Stable Nix Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-zenn-cli.url = "github:t0m0h1de/nix-zenn-cli";

    # hunk のビルド(bun2nix)は flake-parts で全 system を評価するため、x86_64-darwin を削除した
    # nixpkgs(26.11 以降)に follows させると x86_64-darwin の評価だけで失敗する。
    # そこで hunk のビルド用 nixpkgs だけ x86_64-darwin をまだ含む rev(2026-07-05, 前回 hunk が
    # ビルドできた版)に固定する。メインの nixpkgs は最新のまま(=herdr 0.7.3)にできる。
    # 将来 upstream(hunk/bun2nix)が x86_64-darwin を systems から外したら follows に戻してよい。
    nixpkgs-hunk.url = "github:nixos/nixpkgs/c4013e501c048ae7c4a8940c92837636042bf6c3";

    # modem-dev/hunk: ターミナル差分ビューア CLI(バイナリ hunk)。独自 flake(bun2nix ビルド)を利用。
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs-hunk";
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
      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays = [ customOverlay ];
      };
      mkHome = { system, isWork ? false }: home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs system;
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

      # overlay で定義したパッケージを単体で公開する(その system で使えるものだけ)。
      # nix-update(.github/workflows/update.yml の bump)が `packages.<system>.<name>` を参照するのと、
      # `nix build .#<name>` で個別にビルド確認するため。
      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ] (system:
        let
          pkgs = mkPkgs system;
        in
        nixpkgs.lib.filterAttrs
          (_: nixpkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform)
          (builtins.intersectAttrs (customOverlay pkgs pkgs) pkgs));
    };
}
