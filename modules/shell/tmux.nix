{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    extraConfig = builtins.readFile ../../dotfiles/tmux.conf;
  };
}
