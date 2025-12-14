{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;

    initExtra = ''
      # 秘密ファイルがあれば読み込む
      if [ -f "$HOME/.secrets" ]; then
        source "$HOME/.secrets"
      fi

      # Sheldon の初期化
      eval "$(sheldon source)"

      # 外部の zshrc を読み込む
      ${builtins.readFile ../../dotfiles/zshrc}
    '';
  };
}
