{ pkgs, ... }:
{
  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.jbang/bin"
    "$HOME/.cargo/bin"
  ];
}
