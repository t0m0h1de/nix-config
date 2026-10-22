{ pkgs, pkgsMaster, lib, ... }:
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
    pkgsMaster.gh # 一時的に master から(eMudhra 対応の修正版。flake.nix の nixpkgs-master を参照)
    ghq
    gwq
    awscli2
    google-cloud-sql-proxy
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
    python3Packages.weasyprint

    nil
    nixpkgs-fmt
    shellcheck
    pkgsMaster.uv # 一時的に master から(同上)
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
    aria2
    _7zz
  ]
  # Linux専用パッケージ
  ++ lib.optionals stdenv.isLinux [
    buildah
    bubblewrap
  ]
  # macOS 標準の caffeinate コマンド。
  ++ lib.optionals stdenv.isDarwin [
    darwin.PowerManagement
  ]
  # Apple Silicon macOS 専用パッケージ。
  # terminal-browser は arm64 darwin 版だけをパッケージしている(overlays/default.nix 参照)。
  ++ lib.optionals (stdenv.hostPlatform.system == "aarch64-darwin") [
    terminal-browser
  ];
}
