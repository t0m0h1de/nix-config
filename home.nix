{ config, pkgs, ... }:

{
  home.stateVersion = "25.05";

  imports = [
    ./modules/core
    ./modules/dev
    ./modules/shell
    ./modules/editors/vim.nix
  ];

  home.username = "t0m0h1de";
  home.homeDirectory = "/home/t0m0h1de";
}
