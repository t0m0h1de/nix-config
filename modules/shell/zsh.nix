{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;

    initContent = ''
      # nixの設定 (Sheldonより先に読み込む必要あり)
      if [ -e ''${HOME}/.nix-profile/etc/profile.d/nix.sh ]; then
        . ''${HOME}/.nix-profile/etc/profile.d/nix.sh;
      fi

      # 秘密ファイルがあれば読み込む
      if [ -f "$HOME/.secrets" ]; then
        source "$HOME/.secrets"
      fi

      # 対話シェルでも `#` をコメントとして扱う。
      setopt interactivecomments

      # zsh-vi-mode の設定 (Sheldon でロードされる前に定義が必要)
      ZVM_VI_INSERT_ESCAPE_BINDKEY=jj
      zvm_after_init() {
        source <(fzf --zsh)
      }

      # Sheldon の初期化
      eval "$(sheldon source)"

      # 外部の zshrc を読み込む
      ${builtins.readFile ../../dotfiles/zshrc}
    '';
  };
}
