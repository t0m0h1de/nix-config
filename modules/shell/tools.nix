{ pkgs, ... }:
{
  home.packages = with pkgs; [ sheldon ];

  xdg.configFile."sheldon/plugins.toml".source = ../../dotfiles/sheldon/plugins.toml;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
