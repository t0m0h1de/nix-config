{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    jq
    yq-go
    glow
    jbang
    gnumake
    nmap
    openssl
    postgresql
    gh
    ghq
    gwq
    awscli2
    fzf
    ripgrep
    fd

    delta
    lazygit
    bottom
    diffnav
    hunk

    nil
    nixpkgs-fmt
    uv
    zenn-cli
    roots
    zed-editor
    mise
    overmind
    gettext
    pre-commit
    herdr
    pup

    watch
    nkf
    libiconv
    ffmpeg
    imagemagick
    pdftk
  ]
  # Linux専用パッケージ
  ++ lib.optionals stdenv.isLinux [
    buildah
    bubblewrap
  ];
}
