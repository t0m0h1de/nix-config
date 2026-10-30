{ config, ... }:
{
  # nh (yet another Nix CLI helper): home-manager の switch を TUI + パッケージ差分表示で実行し、
  # 古い世代の GC を自動化する。`programs.nh` モジュールで管理する。
  programs.nh = {
    enable = true;

    # NH_FLAKE 環境変数に本リポジトリのチェックアウト先(絶対パス)を設定する。
    # これにより `nh home switch -c <profile>`(例: -c work)を flake パス省略で実行できる。
    # 絶対パスはマシン依存なので、ghq 配置(~/src/<host>/<owner>/<repo>)前提で home ディレクトリ基準に組み立てる。
    flake = "${config.home.homeDirectory}/src/github.com/t0m0h1de/nix-config";

    # 古い世代を定期 GC する。Linux は systemd user timer、macOS は launchd agent が自動選択される。
    # extraArgs はリストで書く。文字列だと launchd の ProgramArguments に 1 要素として入り、
    # nh が引数を解釈できず失敗する(macOS で世代が消えずに溜まっていた)。
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = [ "--keep" "5" "--keep-since" "7d" ];
    };
  };
}
