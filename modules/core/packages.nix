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
    cloudflared
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
    # Google Antigravity の TUI エージェントクライアント。コマンド名は antigravity ではなく `agy`。
    # unfree(Google 配布のプリビルドバイナリを再パッケージ)なので cache.nixos.org には無く、
    # 初回は storage.googleapis.com から直接取得される。IDE 版が要るなら別途 antigravity-ide。
    antigravity-cli

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
