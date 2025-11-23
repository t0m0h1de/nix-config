{ config, pkgs, ... }:

{
  # バージョンは flake.nix 側に合わせる
  home.stateVersion = "25.05";

  # =================================================
  # 1. パッケージのインストール
  # =================================================
  home.packages = with pkgs; [
    # --- Cloud Native ---
    kubectl kubernetes-helm argocd openshift tektoncd-cli
    
    # --- Tools ---
    jq yq-go glow jbang nmap
    nkf libiconv ffmpeg imagemagick
    gh ghq
    
    # --- Langs ---
    nodejs yarn cargo rustc bc

    # --- Essentials ---
    # git      (削除 -> programs.git で管理)
    # tmux     (削除 -> programs.tmux で管理)
    # vim      (削除 -> programs.vim で管理)
    # starship (削除 -> programs.starship で管理)
    sheldon 
  ];

  # =================================================
  # 2. 各種設定 (外部ファイル読み込み)
  # =================================================

  # --- Vim ---
  programs.vim = {
    enable = true;
    defaultEditor = true;
    extraConfig = builtins.readFile ./dotfiles/vimrc;
  };

  # --- Tmux ---
  programs.tmux = {
    enable = true;
    mouse = true;
    extraConfig = builtins.readFile ./dotfiles/tmux.conf;
  };

  # --- Sheldon (手動設定) ---
  # 設定ファイルの配置
  xdg.configFile."sheldon/plugins.toml".source = ./dotfiles/sheldon/plugins.toml;

  # --- Zsh ---
  programs.zsh = {
    enable = true;
    
    initContent = ''
      # 秘密ファイルがあれば読み込む
      if [ -f "$HOME/.secrets" ]; then
        source "$HOME/.secrets"
      fi

      eval "$(sheldon source)"
      ${builtins.readFile ./dotfiles/zshrc}
    '';
  };

  # --- Starship ---
  xdg.configFile."starship.toml".source = ./dotfiles/starship.toml;
  programs.starship = {
    enable = true;
  };

  # =================================================
  # 3. Git 設定
  # =================================================
  programs.git = {
    enable = true;
    userName = "Tomohide Sawada";
    userEmail = "Tomohide.Sawada@ibm.com";

    includes = [
      { path = ./dotfiles/gitconfig; }
      # {
      #   condition = "gitdir:~/workspace/projectX/";
      #   path = ~/work.gitconfig; 
      # }
    ];
  };

  # 環境変数設定
  home.sessionVariables = {
    EDITOR = "vim";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.jbang/bin"
    "$HOME/.cargo/bin"
  ];

  programs.home-manager.enable = true;

  # direnv & nix-direnvを有効化
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
