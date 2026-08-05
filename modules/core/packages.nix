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
    md2pdf

    nil
    nixpkgs-fmt
    shellcheck
    uv
    poetry
    zenn-cli
    roots
    zed-editor
    mise
    overmind
    gettext
    pre-commit
    herdr
    pup
    coder

    watch
    tree
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
  ]
  # Apple Silicon macOS 専用パッケージ。
  # terminal-browser は上流が arm64 darwin ビルドしか配布していない(overlays/default.nix 参照)。
  ++ lib.optionals (stdenv.hostPlatform.system == "aarch64-darwin") [
    terminal-browser
  ];
}
