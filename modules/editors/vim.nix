{ pkgs, ... }:
{
  programs.vim = {
    enable = true;
    defaultEditor = true;
    extraConfig = builtins.readFile ../../dotfiles/vimrc;
  };
}
