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
in
{
  home.packages = [ gwqTtl ];

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
