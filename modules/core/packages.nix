{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    jq
    yq-go
    glow
    jbang
    nmap
    openssl
    postgresql
    gh
    ghq
    awscli2
    fzf

    delta
    lazygit
    bottom
    diffnav

    nil
    nixpkgs-fmt
    uv

    nkf
    libiconv
    ffmpeg
    imagemagick
    zulu17
  ]
  # Linux専用パッケージ
  ++ lib.optionals stdenv.isLinux [
    buildah
  ];
}
