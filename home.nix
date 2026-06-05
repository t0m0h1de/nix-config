{ config, pkgs, lib, isWork ? false, ... }:

{
  home.stateVersion = "25.05";

  imports = [
    ./modules/core
    ./modules/dev
    ./modules/shell
    ./modules/editors
  ];

  home.username = lib.mkDefault (
    if isWork then "tomohide.sawada" else "t0m0h1de"
  );
  home.homeDirectory = lib.mkDefault (
    if pkgs.stdenv.isDarwin
    then "/Users/${config.home.username}"
    else "/home/${config.home.username}"
  );
}
