{ config, pkgs, ... }:

{
  # バージョンは flake.nix 側に合わせる
  home.stateVersion = "25.05";

  # =================================================
  # 1. パッケージのインストール (重複を削除！)
  # =================================================
  home.packages = with pkgs; [
    # --- Cloud Native ---
    kubectl kubernetes-helm argocd openshift tektoncd-cli
    
    # --- Tools ---
    jq yq-go glow jbang nmap
    nkf libiconv ffmpeg imagemagick
    
    # --- Langs ---
    nodejs yarn cargo rustc bc

    # --- Essentials ---
    # 【重要】以下のツールは下の programs.xx で有効化しているため、
    # ここに書くと「重複エラー」になります。削除しました。
    # git      (削除 -> programs.git で管理)
    # tmux     (削除 -> programs.tmux で管理)
    # vim      (削除 -> programs.vim で管理)
    # starship (削除 -> programs.starship で管理)
    
    # sheldon は programs.sheldon を削除したので、ここに残してOKです！
    sheldon 
  ];

  # =================================================
  # 2. 各種設定 (外部ファイル読み込み)
  # =================================================

  # --- Vim ---
  programs.vim = {
    enable = true; # ここで有効化しているのでパッケージも自動で入ります
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

  # 環境変数設定（前回の内容を維持）
  home.sessionVariables = {
    EDITOR = "vim";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.jbang/bin"
    "$HOME/.cargo/bin"
  ];

  programs.home-manager.enable = true;
}
