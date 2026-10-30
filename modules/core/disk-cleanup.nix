{ config, pkgs, lib, ... }:
let
  # disk-cleanup: 再生成できるものだけを消してディスクを空ける(手で動かす)。
  # 既定は見積もりだけで何も消さない。-y を付けたときだけ消す。
  #   nix     古い世代を消して GC し(nh clean と同じ保持数)、nix store optimise する
  #   caches  パッケージマネージャー・ビルドツールのキャッシュ(入っているツールだけ)
  #   src     ghq root 配下の .terragrunt-cache / .terraform / node_modules / ビルドの target
  # src は作業中のリポジトリにも効く(次回は再 install・フルビルドになる)ので、定期実行はしない。
  # 古い世代の定期 GC は nh.nix の nh clean が受け持つ。
  nhArgs = lib.escapeShellArgs config.programs.nh.clean.extraArgs;

  diskCleanup = pkgs.writeShellApplication {
    name = "disk-cleanup";
    runtimeInputs = with pkgs; [ coreutils findutils gnugrep gawk config.programs.nh.package ];
    text = ''
      usage() {
        cat <<'EOF'
      使い方: disk-cleanup [-y] [nix|caches|src ...]
        再生成できるものだけを消してディスクを空ける。既定は見積もりだけ(何も消さない)。
        -y      実際に消す
        対象を省略すると全部。
          nix     古い世代を消して GC し、nix store optimise する
          caches  パッケージマネージャー・ビルドツールのキャッシュ(入っているツールだけ)
          src     ghq root 配下の .terragrunt-cache / .terraform / node_modules / ビルドの target
      EOF
      }

      apply=0
      targets=()
      for a in "$@"; do
        case "$a" in
          -y | --yes) apply=1 ;;
          -h | --help) usage; exit 0 ;;
          nix | caches | src) targets+=("$a") ;;
          *) usage >&2; exit 2 ;;
        esac
      done
      [ ''${#targets[@]} -gt 0 ] || targets=(nix caches src)

      if [ "$(uname -s)" = Darwin ]; then
        cache_home="$HOME/Library/Caches"
        coursier_dir="$cache_home/Coursier"
      else
        cache_home="''${XDG_CACHE_HOME:-$HOME/.cache}"
        coursier_dir="$cache_home/coursier"
      fi

      has() { command -v "$1" >/dev/null 2>&1; }
      size() { du -sch "$@" 2>/dev/null | tail -n1 | cut -f1; }
      # -y のときだけ実行する。失敗しても次へ進む。
      run() {
        [ "$apply" = 1 ] || return 0
        echo "  + $*"
        "$@" || echo "  !!! 失敗: $*" >&2
      }
      item() { printf '  %-14s %7s  %s\n' "$1" "$2" "$3"; }

      # GC が macOS の保護で止まったら、退避の手順を出す。
      # macOS は一度起動した .app に com.apple.macl を付け、フルディスクアクセスの無い nix-daemon は
      # それを消せない。しかも Nix の DB からは外れた後なので GC root にもできず、毎回そこで止まる。
      # 親ディレクトリごとストアの外へ動かすのは許される。
      macl_hint() {
        local p
        p="$(grep -o 'While deleting store path "[^"]*"' "$1" | head -n1 | cut -d'"' -f2)" || true
        [ -n "$p" ] || return 0
        echo "  !!! $p を消せずに GC が止まった(macOS が .app を保護している)。ストアの外へ退避してから実行し直す:"
        echo "      sudo mkdir -p /nix/var/nix/macl-trash && sudo mv $p /nix/var/nix/macl-trash/ && disk-cleanup -y nix"
      }

      clean_nix() {
        echo "== nix"
        local gens log
        gens="$(find "''${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles" -maxdepth 1 -name '*-link' 2>/dev/null | wc -l)" || gens="?"
        item "世代" "$gens 個" "nh clean user ${nhArgs}"
        item "最適化" "-" "nix store optimise(同じ中身のファイルをハードリンクにまとめる)"
        [ "$apply" = 1 ] || return 0
        log="$(mktemp)"
        if ! nh clean user ${nhArgs} 2>&1 | tee "$log"; then
          echo "  !!! nh clean が失敗した。nix store optimise は飛ばす" >&2
          macl_hint "$log"
          rm -f "$log"
          return 0
        fi
        rm -f "$log"
        run nix store optimise
      }

      clean_caches() {
        echo "== caches"
        if has npm; then
          item npm "$(size "$(npm config get cache)")" "npm cache clean --force"
          run npm cache clean --force
        fi
        if has go; then
          item go-build "$(size "$(go env GOCACHE)")" "go clean -cache"
          run go clean -cache
        fi
        if has pnpm; then
          item pnpm "$(size "$(pnpm store path)")" "pnpm store prune(どこからも使われていないパッケージだけ)"
          run pnpm store prune
        fi
        if has uv; then
          item uv "$(size "$(uv cache dir)")" "uv cache clean"
          run uv cache clean
        fi
        if has pre-commit; then
          item pre-commit "$(size "''${PRE_COMMIT_HOME:-''${XDG_CACHE_HOME:-$HOME/.cache}/pre-commit}")" "pre-commit gc(どのリポジトリからも使われていない環境だけ)"
          run pre-commit gc
        fi
        if has mise; then
          item mise "-" "mise prune -y(どの設定からも使われていない版)"
          run mise prune -y
        fi
        # 専用の掃除コマンドが無い(か、ツール自体が入っていないことがある)ので、ディレクトリごと消すもの。
        # pypoetry は cache だけ(隣の virtualenvs はプロジェクトの venv なので消さない)。
        local d
        for d in "$cache_home/pip" "$cache_home/pypoetry/cache" "$coursier_dir" "$cache_home/grype" "$cache_home/trivy"; do
          [ -d "$d" ] || continue
          item "$(basename "$d")" "$(size "$d")" "rm -rf $d"
          run rm -rf "$d"
        done
      }

      # target はビルド成果物のときだけ(sbt / Cargo / Maven / dbt と、sbt の project/ の中)。
      is_build_target() {
        local parent
        parent="$(dirname "$1")"
        [ "$(basename "$parent")" = project ] && return 0
        local f
        for f in build.sbt Cargo.toml pom.xml dbt_project.yml; do
          [ -e "$parent/$f" ] && return 0
        done
        return 1
      }

      clean_src() {
        echo "== src"
        local root list d name
        root="$(ghq root 2>/dev/null || echo "$HOME/src")"
        [ -d "$root" ] || { item "(無し)" "-" "$root"; return 0; }
        list="$(mktemp)"
        while IFS= read -r -d "" d; do
          if [ "$(basename "$d")" = target ] && ! is_build_target "$d"; then
            continue
          fi
          # backend が local だと .terragrunt-cache の中に state の唯一の実体があるので消さない。
          # .terraform 直下の terraform.tfstate は remote backend の接続設定なので数えない。
          if [ "$(basename "$d")" != node_modules ] && [ "$(basename "$d")" != target ] \
            && [ -n "$(find "$d" -name terraform.tfstate ! -path '*/.terraform/terraform.tfstate' -print -quit 2>/dev/null)" ]; then
            echo "  (残す: terraform.tfstate がある $d)"
            continue
          fi
          printf '%s\0' "$d" >>"$list"
        done < <(find -H "$root" -name .git -prune -o -type d \
          \( -name .terragrunt-cache -o -name .terraform -o -name node_modules -o -name target \) -prune -print0)
        for name in .terragrunt-cache .terraform node_modules target; do
          local n s
          n="$(tr '\0' '\n' <"$list" | grep -c "/$name\$")" || true
          [ "$n" -gt 0 ] || continue
          # xargs が du を何回かに分けても合計できるよう、KiB で足し上げる。
          s="$(tr '\0' '\n' <"$list" | grep "/$name\$" | tr '\n' '\0' | xargs -0 du -sk 2>/dev/null \
            | awk '{s += $1} END {printf "%.1fG", s / 1048576}')" || true
          item "$name" "$s" "$n 個($root 配下)"
        done
        if [ "$apply" = 1 ] && [ -s "$list" ]; then
          echo "  + rm -rf(上の一覧)"
          xargs -0 rm -rf <"$list" || echo "  !!! 一部消せなかった" >&2
        fi
        rm -f "$list"
      }

      before="$(df -Ph "$HOME" | awk 'NR==2 {print $4}')"
      for t in "''${targets[@]}"; do
        "clean_$t"
      done
      if [ "$apply" = 1 ]; then
        echo "空き: $before -> $(df -Ph "$HOME" | awk 'NR==2 {print $4}')"
      else
        echo "見積もりだけ。消すには -y を付ける(例: disk-cleanup -y caches)"
      fi
    '';
  };
in
{
  home.packages = [ diskCleanup ];
}
