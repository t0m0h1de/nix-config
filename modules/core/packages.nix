{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jq
    yq-go
    glow
    jbang
    nmap
    gh
    ghq
    fzf

    nil
    nixpkgs-fmt

    nkf
    libiconv
    ffmpeg
    imagemagick
  ];
}
