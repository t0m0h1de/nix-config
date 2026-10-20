{ pkgs, ... }:
let
  # 期限切れ(既定90日 非アクティブ)worktree を抽出する jq フィルタ。
  # 判定は `gwq status --stale-days` が付ける status=="stale"。カレント(is_current)は除外し、
  # primary clone(ghq クローン本体。命名テンプレの都合でディレクトリ名に "+" が無い)も除外して
  # gwq 作成の worktree(repo+branch)だけを対象にする。出力は「<表示>\t<path>」。
  gwqStaleFilter = pkgs.writeText "gwq-stale.jq" ''
    .worktrees[]
    | select(
        .status == "stale"
        and ((.is_current // false) | not)
        and (.path | split("/") | last | contains("+"))
      )
    | ( .git_status | (.modified + .added + .deleted + .untracked + .staged + .conflicts) ) as $dirty
    | [ ( .last_activity[0:10]
          + "  " + (if $dirty > 0 then "✳dirty" else "·clean" end)
          + "  " + .repository + " : " + .branch ),
        .path ] | @tsv
  '';

  # gwq-ttl: 期限切れ worktree を fzf で複数選択 → 確認 → gwq remove する対話コマンド。
  # 使い方: `gwq-ttl [days]`(days 省略時 90)。dirty な worktree は `gwq remove`(非 -f)が
  # 保護するため削除されない(表示上 ✳dirty。消したい場合は中身確認のうえ手動で `gwq remove -f`)。
  gwqTtl = pkgs.writeShellApplication {
    name = "gwq-ttl";
    runtimeInputs = with pkgs; [ gwq jq fzf git ];
    text = ''
      days="''${1:-90}"

      mapfile -t rows < <(
        gwq status --json --global --no-fetch --stale-days "$days" \
          | jq -rf ${gwqStaleFilter}
      )

      if [ "''${#rows[@]}" -eq 0 ]; then
        echo "期限切れ (>''${days}d 非アクティブ) の gwq worktree はありません。"
        exit 0
      fi

      selected=$(
        printf '%s\n' "''${rows[@]}" \
          | fzf --multi --reverse --delimiter='\t' --with-nth=1 --nth=1 \
              --prompt "stale>''${days}d> " \
              --header 'Tab:選択  Enter:削除確認へ  (✳dirty は -f 無しでは消えません)' \
              --preview 'git -C {2} log --oneline -15 2>/dev/null; echo ---; git -C {2} status -s 2>/dev/null' \
              --preview-window=right,50%,wrap
      ) || true

      if [ -z "$selected" ]; then
        echo "キャンセルしました。"
        exit 0
      fi

      mapfile -t paths < <(printf '%s\n' "$selected" | cut -f2)

      echo "以下の ''${#paths[@]} 件を削除します:"
      printf '  - %s\n' "''${paths[@]}"
      printf 'よろしいですか? [y/N] '
      read -r ans
      case "$ans" in
        y | Y | yes | YES) ;;
        *)
          echo "中止しました。"
          exit 0
          ;;
      esac

      fail=0
      for p in "''${paths[@]}"; do
        echo ">>> gwq remove: $p"
        if ! gwq remove --global "$p"; then
          echo "!!! 失敗/スキップ: $p (dirty なら変更を確認して手動で gwq remove -f)"
          fail=1
        fi
      done
      exit "$fail"
    '';
  };

  # Git 管理下の全 linked worktree を対象にする対話式 cleanup。
  # gwq list は basedir 直下の命名規則に依存するため、git worktree list を正として
  # git worktree add で作られた nested worktree も拾う。通常は upstream が消えた
  # ([gone]) ブランチだけを候補にし、--all で upstream 無し/ detached も確認できる。
  gitWorktreeCleanup = pkgs.writeShellApplication {
    name = "git-worktree-cleanup";
    runtimeInputs = with pkgs; [ coreutils findutils gawk git ];
    text = ''
      set -u

      base="''${GIT_WORKTREE_CLEANUP_ROOT:-$HOME/src}"
      include_all=false
      dry_run=false
      fetch_prune=false
      older_than=""
      exec 3<&0

      usage() {
        cat <<'EOF'
      Usage: git-worktree-cleanup [options]

      Options:
        --all       upstream が gone でない linked worktree も候補に含める
        --fetch     各 repository で git fetch --prune origin を先に実行する
        --older-than DURATION
                    最終コミットが指定期間より古いものだけを候補にする
                    例: 1month, 30d, 2weeks
        --dry-run   候補表示だけ行い、削除しない
        -h, --help  このヘルプを表示する

      GIT_WORKTREE_CLEANUP_ROOT で探索ルートを変更できます(既定: ~/src)。
      EOF
      }

      while [ "$#" -gt 0 ]; do
        case "$1" in
          --all) include_all=true; shift ;;
          --fetch) fetch_prune=true; shift ;;
          --older-than)
            [ "$#" -ge 2 ] || { echo "--older-than には期間が必要です" >&2; exit 2; }
            older_than="$2"
            shift 2
            ;;
          --dry-run) dry_run=true; shift ;;
          -h | --help) usage; exit 0 ;;
          *) echo "不明なオプション: $1" >&2; usage >&2; exit 2 ;;
        esac
      done

      cutoff_epoch=""
      cutoff_label=""
      if [ -n "$older_than" ]; then
        case "$older_than" in
          *mo | *month | *months)
            number="''${older_than%mo}"
            [ "$number" = "$older_than" ] && number="''${older_than%month}"
            [ "$number" = "$older_than" ] && number="''${older_than%months}"
            unit=months
            ;;
          *d | *day | *days)
            number="''${older_than%d}"
            [ "$number" = "$older_than" ] && number="''${older_than%day}"
            [ "$number" = "$older_than" ] && number="''${older_than%days}"
            unit=days
            ;;
          *w | *week | *weeks)
            number="''${older_than%w}"
            [ "$number" = "$older_than" ] && number="''${older_than%week}"
            [ "$number" = "$older_than" ] && number="''${older_than%weeks}"
            unit=weeks
            ;;
          *)
            echo "期間は 1month / 30d / 2weeks の形式で指定してください: $older_than" >&2
            exit 2
            ;;
        esac
        if [ -z "$number" ]; then
          echo "期間の数値が不正です: $older_than" >&2
          exit 2
        fi
        case "$number" in
          *[!0-9]*)
            echo "期間の数値が不正です: $older_than" >&2
            exit 2
            ;;
        esac
        cutoff_epoch=$(date -u -d "$number $unit ago" +%s 2>/dev/null) || {
          echo "期間を解釈できません: $older_than" >&2
          exit 2
        }
        cutoff_label=$(date -u -d "@$cutoff_epoch" '+%Y-%m-%d %H:%M UTC')
      fi

      if [ ! -d "$base" ]; then
        echo "探索ルートがありません: $base" >&2
        exit 1
      fi

      declare -A seen_git_common=()
      declare -A prune_roots=()
      roots=()

      # .git directory を持つ clone を入口にし、git-common-dir で同じ repository を重複排除する。
      while IFS= read -r gitdir; do
        repo="''${gitdir%/.git}"
        common=$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || continue
        if [ -z "''${seen_git_common[$common]+x}" ]; then
          seen_git_common["$common"]=1
          roots+=("$repo")
        fi
      done < <(find "$base" -type d -name .git -prune -print)

      if [ "''${#roots[@]}" -eq 0 ]; then
        echo "Git repository が見つかりません: $base"
        exit 0
      fi

      if [ "$fetch_prune" = true ]; then
        for repo in "''${roots[@]}"; do
          if git -C "$repo" remote get-url origin >/dev/null 2>&1; then
            echo ">>> git fetch --prune origin: $repo"
            if ! git -C "$repo" fetch --prune origin; then
              echo "!!! fetch 失敗: $repo (この repository は現在の remote 情報で続行)" >&2
            fi
          fi
        done
      fi

      removed_worktrees=0
      retained_branches=0
      skipped=0
      failures=0

      for repo in "''${roots[@]}"; do
        # record: path / branch(@detached) / prunable / locked
        while IFS=$'\t' read -r wt_path branch prunable locked; do
          [ -n "$wt_path" ] || continue
          [ "$wt_path" = "$repo" ] && continue

          if [ "$prunable" = yes ] || [ ! -d "$wt_path" ]; then
            prune_roots["$repo"]=1
            continue
          fi

          upstream=""
          track=""
          merged="n/a"
          remote_state="detached"
          if [ "$branch" != '@detached' ]; then
            upstream=$(git -C "$repo" for-each-ref --format='%(upstream:short)' "refs/heads/$branch" 2>/dev/null || true)
            track=$(git -C "$repo" for-each-ref --format='%(upstream:track)' "refs/heads/$branch" 2>/dev/null || true)
            if [ "$track" = '[gone]' ]; then
              remote_state="upstream gone"
            elif [ -n "$upstream" ]; then
              remote_state="$upstream"
            else
              remote_state="no upstream"
            fi

            if git -C "$repo" rev-parse --verify --quiet refs/remotes/origin/main >/dev/null; then
              if git -C "$repo" merge-base --is-ancestor "refs/heads/$branch" refs/remotes/origin/main; then
                merged=yes
              else
                merged=no
              fi
            else
              merged=unknown
            fi
          fi

          [ "$include_all" = true ] || [ "$track" = '[gone]' ] || continue

          commit_epoch=$(git -C "$wt_path" log -1 --format='%ct' 2>/dev/null || echo 0)
          if [ -n "$cutoff_epoch" ] && [ "$commit_epoch" -ge "$cutoff_epoch" ]; then
            continue
          fi

          status=$(git -C "$wt_path" status --short --untracked-files=all 2>/dev/null || true)
          if [ -n "$status" ]; then
            cleanliness="DIRTY"
            dirty=true
          else
            cleanliness="clean"
            dirty=false
          fi

          last_commit=$(git -C "$wt_path" log -1 --format='%h %ad %s' --date=short 2>/dev/null || echo 'HEAD unavailable')
          echo
          echo "============================================================"
          echo "repository : $repo"
          echo "worktree   : $wt_path"
          echo "branch     : $branch"
          echo "remote     : $remote_state"
          echo "merged     : $merged (origin/main)"
          if [ -n "$cutoff_epoch" ]; then
            echo "cutoff     : $cutoff_label より前の最終コミット"
          fi
          echo "status     : $cleanliness"
          echo "last commit: $last_commit"
          if [ "$locked" = yes ]; then
            echo "locked     : yes"
          fi
          if [ "$dirty" = true ]; then
            echo "変更内容:"
            printf '%s\n' "$status" | sed -n '1,40p'
            status_lines=$(printf '%s\n' "$status" | awk 'NF { n++ } END { print n + 0 }')
            if [ "$status_lines" -gt 40 ]; then
              echo "... (残り $((status_lines - 40)) 件は省略)"
            fi
          fi

          if [ "$dry_run" = true ]; then
            echo "[dry-run] 削除候補"
            continue
          fi

          if [ "$locked" = yes ]; then
            echo "locked worktree のためスキップします。"
            skipped=$((skipped + 1))
            continue
          fi

          printf 'この worktree を削除しますか? [y/N] '
          read -r answer <&3
          case "$answer" in
            y | Y | yes | YES) ;;
            *)
              echo "スキップしました。"
              skipped=$((skipped + 1))
              continue
              ;;
          esac

          remove_args=()
          if [ "$dirty" = true ]; then
            echo "未コミット変更を破棄する削除になります。"
            printf '変更を破棄して強制削除しますか? [y/N] '
            read -r force_answer <&3
            case "$force_answer" in
              y | Y | yes | YES) remove_args=(-f) ;;
              *)
                echo "変更を保持するためスキップしました。"
                skipped=$((skipped + 1))
                continue
                ;;
            esac
          fi

          if [ "''${#remove_args[@]}" -gt 0 ]; then
            remove_command=(git -C "$repo" worktree remove "''${remove_args[@]}" "$wt_path")
          else
            remove_command=(git -C "$repo" worktree remove "$wt_path")
          fi
          if ! "''${remove_command[@]}"; then
            echo "!!! worktree 削除に失敗しました。"
            failures=$((failures + 1))
            continue
          fi
          removed_worktrees=$((removed_worktrees + 1))

          if [ "$branch" != '@detached' ]; then
            # local HEAD が origin/main より古くても、先に祖先性を確認できた場合は
            # その確認済みブランチだけ -D で消す。未マージ/判定不能は -d にして保持する。
            if [ "$merged" = yes ]; then
              branch_delete=(-D)
            else
              branch_delete=(-d)
            fi
            if git -C "$repo" branch "''${branch_delete[@]}" "$branch"; then
              echo "local branch も削除しました: $branch"
            else
              retained_branches=$((retained_branches + 1))
              echo "local branch は保持しました(未マージ判定): $branch"
            fi
          fi
        done < <(
          git -C "$repo" worktree list --porcelain 2>/dev/null | awk '
            function emit() {
              if (seen) print wt_path "\t" branch "\t" prunable "\t" locked
            }
            /^worktree / {
              emit()
              wt_path = substr($0, 10)
              branch = "@detached"
              prunable = "no"
              locked = "no"
              seen = 1
            }
            /^branch refs\/heads\// { branch = substr($0, 19) }
            /^detached$/ { branch = "@detached" }
            /^prunable/ { prunable = "yes" }
            /^locked/ { locked = "yes" }
            END { emit() }
          '
        )
      done

      for repo in "''${!prune_roots[@]}"; do
        echo
        echo "stale な worktree 管理情報があります: $repo"
        git -C "$repo" worktree prune --dry-run --verbose || true
        if [ "$dry_run" = true ]; then
          continue
        fi
        printf 'stale 管理情報を prune しますか? [y/N] '
        read -r prune_answer <&3
        case "$prune_answer" in
          y | Y | yes | YES) git -C "$repo" worktree prune --verbose ;;
          *) echo "prune をスキップしました。" ;;
        esac
      done

      echo
      echo "完了: worktree削除=$removed_worktrees, branch保持=$retained_branches, スキップ=$skipped, 失敗=$failures"
      [ "$failures" -eq 0 ]
    '';
  };
in
{
  home.packages = [ gwqTtl gitWorktreeCleanup ];

  # gwq の worktree 保存先を ghq root と同じ ~/src に統一し、
  # ディレクトリ名を host/owner/repo+branch 形式にする。
  xdg.configFile."gwq/config.toml".text = ''
    [worktree]
    basedir = "~/src"

    [naming]
    template = "{{.Host}}/{{.Owner}}/{{.Repository}}+{{.Branch}}"
  '';

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Tomohide Sawada";
        email = "ma1n.tmrev01ut10n@gmail.com";
      };

      ghq = {
        root = "~/src";
      };

      # hunk.nvim(nvim の :DiffEditor)を dir-diff の difftool として登録する。
      # git difftool --dir-diff は before/after を2つのディレクトリ($LOCAL/$REMOTE)で渡すので、
      # それを hunk.nvim の :DiffEditor <left> <right> に渡す(output 省略時は right 側=working tree)。
      # 注意: dir-diff は編集結果を working tree に書き戻し得るため、閲覧目的なら変更を accept しないこと。
      # プラグイン導入は modules/editors/nvim/plugins.nix の plugins.hunk。
      difftool = {
        prompt = false;
        hunk.cmd = ''nvim -c "DiffEditor $LOCAL $REMOTE"'';
      };

      alias = {
        # hunk.nvim を dir-diff で起動する: git dh [<commit>] [-- <path>...]
        # --no-symlinks が必須。既定の dir-diff は working tree 側(right)を symlink で作るが、
        # hunk.nvim は symlink を差分対象にしない実装(fs.scan_dir が symlink 判定 → diff_file が
        # 空を返す)ため、全ファイルが差分無し/新規のように化ける。--no-symlinks で実ファイルコピー
        # にさせると正しく差分が出る(git config の difftool.symlinks=false は本環境で効かず、
        # フラグ指定が必要だったため alias に固定)。
        dh = "difftool --dir-diff --no-symlinks --tool=hunk";
      };
    };

    includes = [
      { path = ../../dotfiles/gitconfig; }
    ];
  };
}
