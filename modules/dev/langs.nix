{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs
    yarn
    cargo
    rustc
    bc
  ];
}
