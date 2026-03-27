{ config, pkgs, lib, ... }:

{
  home.stateVersion = "25.05";

  imports = [
    ./modules/core
    ./modules/dev
    ./modules/shell
    ./modules/editors/vim.nix
  ];

  home.username = "t0m0h1de";
  home.homeDirectory = lib.mkDefault (
    if pkgs.stdenv.isDarwin
    then "/Users/t0m0h1de"
    else "/home/t0m0h1de"
  );
}
