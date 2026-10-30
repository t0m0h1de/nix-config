{ pkgs, lib, isWork, ... }:
let
  # dev-refresh: 開発ツールを最新の既定ブランチに追従させる(手で動かす)。
  #   1. 本リポジトリの最新 main を専用の clone に取り込み、`nh home switch` する(mise・CA などを上げる)
  #   2. 対象リポジトリの最新の既定ブランチを専用の clone に取り込み、`mise install` する
  #      (各リポジトリの mise.lock の版、つまり脆弱性の修正版を入れる)
  # clone は ~/.local/share/dev-refresh に置き、~/src の作業用の checkout には触れない。専用なので毎回
  # 既定ブランチの状態に戻す(手で変更しないこと)。
  #
  # 対象はマシンごとに違い、リポジトリ名も公開したくないので、本リポジトリには書かずに次のファイルで決める
  # (~/.claude/additional-directories.json と同じ発想)。無ければその手順を飛ばす。
  #   ~/.config/dev-refresh/home-profile  switch するプロファイル名(例: work)
  #   ~/.config/dev-refresh/repos         clone の URL を 1 行に 1 つ(# 以降はコメント)
  #   ~/.config/dev-refresh/profile-packages  nix profile に入れる flake の参照を 1 行に 1 つ(# 以降はコメント)
  #   ~/.config/dev-refresh/after/<項目名>  その項目の中身が変わったときに動かす実行ファイル(例: 常駐の再起動)
  #
  # 定期実行はしない。代わりに、しばらく成功していないと対話シェルの起動時に警告する(下の initContent)。
  nixConfigUrl = "https://github.com/t0m0h1de/nix-config.git";

  devRefresh = pkgs.writeShellApplication {
    name = "dev-refresh";
    runtimeInputs = with pkgs; [ coreutils gnused git jq ];
    text = ''
      config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/dev-refresh"
      data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/dev-refresh"
      profile_file="$config_dir/home-profile"
      repos_file="$config_dir/repos"
      packages_file="$config_dir/profile-packages"

      log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

      skip_mise=0
      ${lib.optionalString isWork ''
        # PyPI を Takumi Guard 経由にする設定は .zshrc(modules/shell/zsh.nix)が入れる。無いまま
        # mise install すると pypi のツールを公開の PyPI から入れてしまうので、mise install を飛ばす。
        if [ -z "''${PIP_INDEX_URL:-}" ] || [ -z "''${UV_INDEX_URL:-}" ]; then
          log "!!! PIP_INDEX_URL / UV_INDEX_URL が無い(Takumi Guard)。対話シェルから動かす。mise install は飛ばす"
          skip_mise=1
        fi
      ''}

      mkdir -p "$data_dir"
      lock="$data_dir/.lock"
      if ! mkdir "$lock" 2>/dev/null; then
        log "前の実行が終わっていない($lock)。終わっているなら消してから実行し直す"
        exit 1
      fi
      trap 'rmdir "$lock"' EXIT

      # clone の URL から置き場所を決める。
      #   ssh://git@github.com/o/r.git, git@github.com:o/r.git, https://github.com/o/r -> $data_dir/repos/github.com/o/r
      repo_dir() {
        local p
        p="$(printf '%s' "$1" | sed -E 's#^[a-z+]+://##; s#^[^@/]+@##; s#:#/#; s#\.git$##')"
        case "$p" in
          *..* | /*) return 1 ;;
        esac
        printf '%s/repos/%s' "$data_dir" "$p"
      }

      # 専用の clone を、origin の最新の既定ブランチの状態にする。
      sync_repo() {
        local url="$1" dir="$2" ref
        if [ ! -d "$dir/.git" ]; then
          mkdir -p "$(dirname "$dir")" || return 1
          git clone --quiet --filter=blob:none "$url" "$dir" || return 1
        fi
        git -C "$dir" fetch --quiet --prune origin || return 1
        git -C "$dir" remote set-head origin --auto >/dev/null || return 1
        ref="$(git -C "$dir" symbolic-ref --short refs/remotes/origin/HEAD)" || return 1
        git -C "$dir" checkout --quiet --force -B "''${ref#origin/}" "$ref" || return 1
        git -C "$dir" clean -ffdxq || return 1
        log "  $(git -C "$dir" log -1 --format='%h %cs %s' | cut -c1-100)"
      }

      # nix profile の項目のうち、flake の参照(originalUrl)が ref のものの名前
      profile_name() {
        jq -r --arg u "$2" '.elements | to_entries[] | select(.value.originalUrl == $u) | .key' <<<"$1" | head -n1
      }
      profile_paths() {
        jq -r --arg n "$2" '.elements[$n].storePaths | join(" ")' <<<"$1"
      }
      # 中身が変わった項目の後始末(常駐の再起動など)。after/<項目名> があれば動かす。
      run_after() {
        local hook="$config_dir/after/$1"
        [ -n "$1" ] && [ -x "$hook" ] || return 0
        log "  after/$1 を実行"
        "$hook" || { log "!!! after/$1 が失敗"; return 1; }
      }

      fail=0

      # 1. nix-config の最新 main を switch する
      if [ -r "$profile_file" ]; then
        profile="$(tr -d '[:space:]' <"$profile_file")"
        log "nix-config を取り込んで switch する(-c $profile)"
        if sync_repo "${nixConfigUrl}" "$data_dir/nix-config" &&
          nh home switch --no-nom -c "$profile" "$data_dir/nix-config"; then
          log "nix-config: switch した"
        else
          log "!!! nix-config: 失敗"
          fail=1
        fi
      else
        log "nix-config: $profile_file が無いので飛ばす"
      fi

      # 2. 対象リポジトリの既定ブランチで mise install する
      if [ "$skip_mise" -eq 1 ]; then
        fail=1
      elif [ -r "$repos_file" ]; then
        # 専用の clone の下だけを、このプロセスに限って信頼する(mise trust の記録は残さない)。
        # 既定ブランチ(レビュー済み)の mise.toml なので、hooks やタスクも含めて信頼してよい前提。
        export MISE_TRUSTED_CONFIG_PATHS="$data_dir/repos"
        export MISE_YES=1
        while IFS= read -r line || [ -n "$line" ]; do
          url="$(printf '%s' "''${line%%#*}" | tr -d '[:space:]')"
          [ -z "$url" ] && continue
          if ! dir="$(repo_dir "$url")"; then
            log "!!! 置き場所を決められない URL: $url"
            fail=1
            continue
          fi
          log "$url"
          if sync_repo "$url" "$dir" && (cd "$dir" && mise install); then
            :
          else
            log "!!! 失敗: $url"
            fail=1
          fi
        done <"$repos_file"
      else
        log "repos: $repos_file が無いので飛ばす"
      fi

      # 3. Home Manager の外で nix profile に入れるもの(会社の flake など、本リポジトリに書けないもの)を一覧に合わせる。
      #    一覧に無くて入っていないものは add、入っているものは upgrade。中身が変わったら after/<項目名> を動かす。
      #    一覧に無い項目は知らせるだけで、消さない(nix profile remove <項目名> は手で)。
      if [ -r "$packages_file" ]; then
        if ! installed="$(nix profile list --json)"; then
          log "!!! nix profile list に失敗"
          fail=1
        else
          wanted=()
          while IFS= read -r line || [ -n "$line" ]; do
            ref="$(printf '%s' "''${line%%#*}" | tr -d '[:space:]')"
            [ -z "$ref" ] && continue
            wanted+=("$ref")
            name="$(profile_name "$installed" "$ref")"
            if [ -z "$name" ]; then
              log "profile: 追加 $ref"
              if ! nix profile add "$ref"; then
                log "!!! 失敗: $ref"
                fail=1
                continue
              fi
              installed="$(nix profile list --json)" || { fail=1; continue; }
              name="$(profile_name "$installed" "$ref")"
              run_after "$name" || fail=1
              continue
            fi
            before="$(profile_paths "$installed" "$name")"
            log "profile: 更新 $name"
            if ! nix profile upgrade "$name"; then
              log "!!! 失敗: $name"
              fail=1
              continue
            fi
            installed="$(nix profile list --json)" || { fail=1; continue; }
            if [ "$(profile_paths "$installed" "$name")" != "$before" ]; then
              run_after "$name" || fail=1
            else
              log "  変わらず"
            fi
          done <"$packages_file"
          while IFS=$'\t' read -r name url; do
            [ -z "$name" ] && continue
            found=0
            for ref in "''${wanted[@]}"; do
              if [ "$ref" = "$url" ]; then found=1; fi
            done
            if [ "$found" -eq 0 ]; then
              log "profile: 一覧に無い項目 $name ($url)。要らなければ nix profile remove $name"
            fi
          done < <(jq -r '.elements | to_entries[] | select(.key != "home-manager-path") | "\(.key)\t\(.value.originalUrl // "")"' <<<"$installed")
        fi
      else
        log "profile-packages: $packages_file が無いので飛ばす"
      fi

      # 結果を残す。対話シェルの起動時の警告(下の initContent)がこの更新日時を見る。
      if [ "$fail" -ne 0 ]; then
        touch "$data_dir/last-failure"
        log "失敗があります。上のログを確認して、直したら dev-refresh を実行し直す"
        exit 1
      fi
      rm -f "$data_dir/last-failure"
      touch "$data_dir/last-success"
      log "完了"
    '';
  };
in
{
  home.packages = [ devRefresh ];

  # 対話シェルの起動時に、dev-refresh がしばらく成功していなければ警告する。
  # 設定(~/.config/dev-refresh)が無いマシンでは何もしない。端末でないシェル(AI エージェントのコマンド実行など)
  # では出さない(毎回の出力に混ざるため)。ファイルの更新日時を見るだけで、ネットワークにも外部コマンドにも触れない。
  # 日数は DEV_REFRESH_WARN_DAYS で変えられる(既定 7)。
  programs.zsh.initContent = lib.mkAfter ''
    _dev_refresh_warn() {
      [[ -o interactive && -t 2 ]] || return 0
      local conf="''${XDG_CONFIG_HOME:-$HOME/.config}/dev-refresh"
      [[ -r $conf/repos || -r $conf/home-profile || -r $conf/profile-packages ]] || return 0
      local data="''${XDG_DATA_HOME:-$HOME/.local/share}/dev-refresh"
      local days=''${DEV_REFRESH_WARN_DAYS:-7}
      zmodload -F zsh/stat b:zstat 2>/dev/null || return 0
      zmodload zsh/datetime 2>/dev/null || return 0
      local -a ok ng
      if [[ ! -e $data/last-success ]]; then
        print -u2 -P "%F{yellow}[dev-refresh]%f まだ成功していない。dev-refresh を実行する"
        return 0
      fi
      zstat -A ok +mtime -- $data/last-success
      if [[ -e $data/last-failure ]]; then
        zstat -A ng +mtime -- $data/last-failure
        if (( ng[1] > ok[1] )); then
          print -u2 -P "%F{yellow}[dev-refresh]%f 前回が失敗した。dev-refresh を実行し直す"
          return 0
        fi
      fi
      local age=$(( (EPOCHSECONDS - ok[1]) / 86400 ))
      if (( age >= days )); then
        print -u2 -P "%F{yellow}[dev-refresh]%f 最後の成功から ''${age} 日。dev-refresh を実行する"
      fi
    }
    _dev_refresh_warn
    unfunction _dev_refresh_warn
  '';
}
