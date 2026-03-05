{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jq
    yq-go
    glow
    jbang
    nmap
    openssl
    gh
    ghq
    awscli2
    fzf

    delta
    lazygit
    bottom
    diffnav

    buildah

    nil
    nixpkgs-fmt

    nkf
    libiconv
    ffmpeg
    imagemagick
  ];
}
