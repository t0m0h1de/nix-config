{ ... }:
{
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
