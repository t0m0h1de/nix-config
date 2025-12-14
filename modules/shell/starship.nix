{ pkgs, ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  xdg.configFile."starship.toml".source = ../../dotfiles/starship.toml;
}
