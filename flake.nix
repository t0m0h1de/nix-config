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

    # 一時的: eMudhra 中間 CA 秘密鍵漏洩(2026-10-20 公表)の修正版(cacert 3.131.1, go 1.26.10,
    # nodejs 26.12.1, uv 0.13.4, gh 2.102.1)が nixpkgs-unstable に来るまで、該当パッケージだけ master から取る。
    # nixpkgs 全体を master にすると swift などのビルドが走るため、末端のパッケージだけに限っている。
    # unstable が追いついたら、この input と extraSpecialArgs の pkgsMaster、各モジュールの参照を消す。
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

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

  outputs = { self, nixpkgs, nixpkgs-master, home-manager, nixvim, nix-zenn-cli, hunk, ... }:
    let
      customOverlay = import ./overlays { inherit nix-zenn-cli hunk; };
      mkPkgs = system: import nixpkgs {
        inherit system;
        overlays = [ customOverlay ];
      };
      mkHome = { system, isWork ? false, homeUsername ? null }: home-manager.lib.homeManagerConfiguration {
        pkgs = mkPkgs system;
        extraSpecialArgs = {
          inherit isWork;
          pkgsMaster = nixpkgs-master.legacyPackages.${system};
        };
        modules = [
          nixvim.homeModules.nixvim
          ./home.nix
          ({ lib, ... }: lib.mkIf (homeUsername != null) {
            home.username = homeUsername;
          })
        ];
      };
    in
    {
      homeConfigurations = {
        linux = mkHome { system = "x86_64-linux"; };
        game = mkHome { system = "x86_64-linux"; homeUsername = "sawada"; };
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
