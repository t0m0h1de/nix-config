{ pkgs, ... }:
let
  # run-shell "cmd1; cmd2" ではセミコロン区切りで変数が引き継がれないため外部スクリプトに切り出す。
  #
  # セッション名: repo@branch（git管理外はディレクトリ basename）
  # repo は git worktree list の1行目から取得する。
  # gwq worktree はディレクトリ名に +branch サフィックスが付くため basename では重複するのを避けるため。
  # ウィンドウ名: automatic-rename に委ねる（実行中コマンド名が表示される）
  tmuxNameSession = pkgs.writeShellScript "tmux-name-session" ''
    path="$1"
    cd "$path" 2>/dev/null

    # git worktree list の1行目がメイン worktree → そこの basename が純粋なリポジトリ名
    main_wt=$(git worktree list 2>/dev/null | head -1 | awk '{print $1}')
    if [ -n "$main_wt" ]; then
      repo=$(basename "$main_wt")
      b=$(git branch --show-current 2>/dev/null)
      l=$(printf "%s" "$b" | sed "s|.*/||")
      if [ -z "$b" ]; then
        session_name="$repo"
      else
        session_name="$repo@$l"
      fi
    else
      # git 管理外: ディレクトリ basename をそのまま使う
      session_name=$(basename "$path")
    fi

    # . はtmuxのセパレータなので _ に変換
    tmux rename-session "$(printf "%s" "$session_name" | tr '.' '_')" 2>/dev/null
  '';
in
{
  programs.tmux = {
    enable = true;
    mouse = true;
    plugins = [
      pkgs.tmuxPlugins.tmux-fzf
    ];
    extraConfig = (builtins.readFile ../../dotfiles/tmux.conf) + ''

      # ステータスバー
      set -g status on
      set -g status-right-length 150
      set -g status-right "#(${pkgs.kube-tmux}/bin/kube.tmux 250 cyan default)"

      # セッション作成時のみセッション名を設定。ウィンドウ名は automatic-rename に委ねる
      set-hook -g after-new-session 'run-shell "${tmuxNameSession} #{pane_current_path}"'
    '';
  };
}
