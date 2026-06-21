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
    };

    includes = [
      { path = ../../dotfiles/gitconfig; }
    ];
  };
}
