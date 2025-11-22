{
  description = "My Stable Nix Configuration";

  inputs = {
    # 安定版 (Stable) に固定
    # ※ 2025年11月時点の最新リリースに合わせてください (例: nixos-25.05)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home Manager も同じブランチを指定
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    homeConfigurations."wsl" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ 
        ./home.nix
        {
          home.username = "t0m0h1de";
          home.homeDirectory = "/home/t0m0h1de";
        }
      ];
    };
  };
}
