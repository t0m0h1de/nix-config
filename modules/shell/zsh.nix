{ pkgs, lib, isWork ? false, ... }:
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

    initContent = lib.mkMerge [
      # zsh-abbr の job queue は強制終了時に stale な項目を残すことがある。
      # プラグイン初期化前に、queue の timeout を超えた項目だけを除去する。
      (lib.mkOrder 500 ''
        _zsh_abbr_clear_stale_jobs() {
          local job_queue_tmpdir=''${JOB_QUEUE_TMPDIR:-''${TMPDIR:-/tmp}/zsh-job-queue}
          local abbr_queue_dir="''${job_queue_tmpdir%/}/zsh-abbr"
          [[ -o interactive && -d "$abbr_queue_dir" ]] || return 0

          zmodload zsh/datetime || return 0
          local job_file job_timestamp
          for job_file in "$abbr_queue_dir"/*(N); do
            job_timestamp=''${''${job_file:t}%%-*}
            job_timestamp=''${job_timestamp%%.*}
            if [[ $job_timestamp == <-> ]] && (( EPOCHSECONDS - job_timestamp > ''${JOB_QUEUE_TIMEOUT_AGE_SECONDS:-30} )); then
              command rm -f -- "$job_file"
            fi
          done
        }
        _zsh_abbr_clear_stale_jobs
        unfunction _zsh_abbr_clear_stale_jobs
      '')
      # compinit より前に実行する必要がある設定（mkOrder 550 = before compinit）。
      (lib.mkOrder 550 ''
        # Homebrew formula(docker など)が提供する zsh 補完を fpath に追加する。
        # docker は brew 管理(Nix管理外)なので、補完も brew のディレクトリを参照して追従させる。
        if [ -d /opt/homebrew/share/zsh/site-functions ]; then
          fpath+=(/opt/homebrew/share/zsh/site-functions)
        fi
      '')
      ''
        # nixの設定
        if [ -e ''${HOME}/.nix-profile/etc/profile.d/nix.sh ]; then
          . ''${HOME}/.nix-profile/etc/profile.d/nix.sh;
        fi

        # 秘密ファイルがあれば読み込む
        if [ -f "$HOME/.secrets" ]; then
          source "$HOME/.secrets"
        fi
        ${lib.optionalString isWork ''

        # Takumi Guard PyPI
        export PIP_INDEX_URL="https://token:''${TAKUMI_GUARD_API_KEY}@pypi.flatt.tech/simple/"
        export UV_INDEX_URL="https://token:''${TAKUMI_GUARD_API_KEY}@pypi.flatt.tech/simple/"
        export UV_EXCLUDE_NEWER="3 days"
        ''}

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
      ''
    ];
  };

  # zsh-abbr のユーザー略語は読み書き可能なファイルに保存する。
  # 各シェル起動時に `abbr` を実行すると共有 job queue への書き込みが集中するため、
  # Home Manager activation で不足分だけを一度追加しておく。
  home.activation.zshAbbrDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}"
    abbr_file="$config_dir/zsh-abbr/user-abbreviations"
    legacy_abbr_file="$config_dir/zsh/abbreviations"
    if [ -f "$legacy_abbr_file" ]; then
      abbr_file="$legacy_abbr_file"
    fi

    run mkdir -p "$(dirname "$abbr_file")"
    run touch "$abbr_file"
    for abbreviation in cdn:cd-nav kube:kubectl kub:kubectl; do
      name=''${abbreviation%%:*}
      expansion=''${abbreviation#*:}
      if ! grep -Fq "abbr \"$name\"=" "$abbr_file"; then
        line="abbr \"$name\"=\"$expansion\""
        run /bin/sh -c 'printf "%s\n" "$1" >> "$2"' sh "$line" "$abbr_file"
      fi
    done
  '';
}
