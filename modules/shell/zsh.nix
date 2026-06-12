{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    plugins = [
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-completions";
        src = pkgs.zsh-completions;
        file = "share/zsh-completions/zsh-completions.plugin.zsh";
      }
      {
        name = "zsh-abbr";
        src = pkgs.zsh-abbr;
        file = "share/zsh/zsh-abbr/zsh-abbr.plugin.zsh";
      }
    ];

    initContent = ''
      # nixの設定
      if [ -e ''${HOME}/.nix-profile/etc/profile.d/nix.sh ]; then
        . ''${HOME}/.nix-profile/etc/profile.d/nix.sh;
      fi

      # 秘密ファイルがあれば読み込む
      if [ -f "$HOME/.secrets" ]; then
        source "$HOME/.secrets"
      fi

      # Takumi Guard PyPI
      export PIP_INDEX_URL="https://token:''${TAKUMI_GUARD_API_KEY}@pypi.flatt.tech/simple/"
      export UV_INDEX_URL="https://token:''${TAKUMI_GUARD_API_KEY}@pypi.flatt.tech/simple/"
      export UV_EXCLUDE_NEWER="3 days"

      # 対話シェルでも `#` をコメントとして扱う。
      setopt interactivecomments

      # zsh-vi-mode の設定 (プラグインロード前に定義が必要)
      ZVM_VI_INSERT_ESCAPE_BINDKEY=jj
      zvm_after_init() {
        source <(fzf --zsh)
      }

      # ホーム下の *.gitconfig を ~/.gitconfig-extras に集約する
      _regen_gitconfig_extras() {
        local out="$HOME/.gitconfig-extras"
        : > "$out"
        for f in "$HOME"/*.gitconfig(DN); do
          [[ -f "$f" ]] && printf '[include]\n\tpath = %s\n' "$f" >> "$out"
        done
      }
      _regen_gitconfig_extras

      # 外部の zshrc を読み込む
      ${builtins.readFile ../../dotfiles/zshrc}
    '';
  };
}
