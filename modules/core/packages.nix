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

    delta
    lazygit
    bottom
    diffnav
    
    nil
    nixpkgs-fmt

    nkf
    libiconv
    ffmpeg
    imagemagick
  ];
}
