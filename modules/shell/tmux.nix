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

  # prefix + s のセッション一覧生成。最終アタッチ時刻の降順(MRU)で、現在のセッションは除外。
  # 出力は tab 区切りの2列: <表示ラベル(name + Claude状態バッジ)>\t<切替用のセッション名>。
  # fzf の reload でも使い回すため独立スクリプトに切り出す。
  tmuxSessionList = pkgs.writeShellScript "tmux-session-list" ''
    current=$(tmux display-message -p '#{session_name}')
    tmux list-sessions -F '#{session_last_attached}|#{session_name}|#{@claude_state}' \
      | sort -rn -t'|' -k1 \
      | awk -F'|' -v cur="$current" 'BEGIN { OFS = "\t" } $2 != cur {
          label = $2
          if ($3 != "") label = label " [" $3 "]"
          print label, $2
        }'
  '';

  # C-a(Create): 検索ボックスに打った文字列を名前に新規セッションを作成 → switch。
  # after-new-session の自動命名(repo@branch)に名前を奪われないよう、生成後に明示 rename し、
  # rename の影響を受けない session_id で switch する。名前が空なら自動命名に委ねる。
  tmuxSessionCreate = pkgs.writeShellScript "tmux-session-create" ''
    name="''${1:-}"
    id=$(tmux new-session -d -P -F '#{session_id}')
    if [ -n "$name" ]; then
      tmux rename-session -t "$id" "$name"
    fi
    tmux switch-client -t "$id"
  '';

  # prefix + s のセッション切り替え/管理ピッカー。fzf の --bind で CRUD を行う。
  #   enter : 選択セッションへ switch
  #   C-a   : 検索ボックスの名前で新規セッション作成 → switch (Create)
  #   C-d   : 選択セッションを kill → 一覧 reload (Delete)
  #   C-r   : 選択セッションを検索ボックスの名前へ rename → 一覧 reload (Rename)
  # fzf には表示ラベル列(--with-nth=1)だけ見せ、操作には切替用の名前列 {2} を使う。
  tmuxSessionPicker = pkgs.writeShellScript "tmux-session-picker" ''
    ${tmuxSessionList} \
      | fzf --reverse --delimiter='\t' --with-nth=1 --prompt 'session> ' \
          --header 'enter:switch  C-a:new(query)  C-d:kill  C-r:rename(query)' \
          --bind 'enter:become(tmux switch-client -t {2})' \
          --bind 'ctrl-a:become(${tmuxSessionCreate} {q})' \
          --bind 'ctrl-d:execute-silent(tmux kill-session -t {2})+reload(${tmuxSessionList})' \
          --bind 'ctrl-r:execute-silent(tmux rename-session -t {2} {q})+reload(${tmuxSessionList})'
  '';

  # prefix + w のウィンドウ一覧生成(現在セッション内)。アクティブなウィンドウは除外。
  # 出力は tab 区切り2列: <表示ラベル "index: name"> <切替用の window_id>。
  # fzf の reload で使い回すため独立スクリプトに切り出す。
  tmuxWindowList = pkgs.writeShellScript "tmux-window-list" ''
    tmux list-windows -F '#{window_index}|#{window_id}|#{window_name}|#{window_active}' \
      | awk -F'|' 'BEGIN { OFS = "\t" } $4 != "1" {
          print $1 ": " $3, $2
        }'
  '';

  # C-a(Create): 新規ウィンドウ作成 → 自動でそのウィンドウへ。
  # 検索ボックスに名前があれば -n で命名する(以後 automatic-rename はそのウィンドウで無効化される)。
  tmuxWindowCreate = pkgs.writeShellScript "tmux-window-create" ''
    name="''${1:-}"
    if [ -n "$name" ]; then
      tmux new-window -n "$name"
    else
      tmux new-window
    fi
  '';

  # prefix + w のウィンドウ切り替え/管理ピッカー(セッション用 tmuxSessionPicker と同じ流儀)。
  #   enter : 選択ウィンドウへ切替
  #   C-a   : 新規ウィンドウ作成(検索ボックスの文字列があれば名前に) → 移動
  #   C-d   : 選択ウィンドウを kill → 一覧 reload
  #   C-r   : 選択ウィンドウを検索ボックスの名前へ rename → 一覧 reload
  # fzf には表示ラベル列(--with-nth=1)だけ見せ、操作には window_id 列 {2} を使う。
  tmuxWindowPicker = pkgs.writeShellScript "tmux-window-picker" ''
    ${tmuxWindowList} \
      | fzf --reverse --delimiter='\t' --with-nth=1 --prompt 'window> ' \
          --header 'enter:switch  C-a:new(query)  C-d:kill  C-r:rename(query)' \
          --bind 'enter:become(tmux select-window -t {2})' \
          --bind 'ctrl-a:become(${tmuxWindowCreate} {q})' \
          --bind 'ctrl-d:execute-silent(tmux kill-window -t {2})+reload(${tmuxWindowList})' \
          --bind 'ctrl-r:execute-silent(tmux rename-window -t {2} {q})+reload(${tmuxWindowList})'
  '';
in
{
  programs.tmux = {
    enable = true;
    mouse = true;
    plugins = [
      # tmux-fzf のセッション一覧を最終アタッチ時刻の降順(MRU)にする。
      # 本体に順序設定が無いため session.sh の list-sessions をソート版に差し替える。
      (pkgs.tmuxPlugins.tmux-fzf.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace scripts/session.sh \
            --replace-fail \
              'sessions=$(tmux list-sessions | grep -v "^$current_session: ")' \
              'sessions=$(tmux list-sessions -F "#{session_last_attached} #{session_name}: #{session_windows} windows#{?session_attached, (attached),}#{?@claude_state, [#{@claude_state}],}" | sort -rn | cut -d" " -f2- | grep -v "^$current_session: ")'
        '';
      }))
      # resurrect: セッション/ウィンドウの保存・復元スクリプトを提供(status-right は使わない)。
      # continuum はここではロードしない。continuum は status-right に保存トリガ #() を追記する方式で、
      # home-manager は plugins を extraConfig より先にロードするため、ここで読むと後続の
      # status-right 上書きで自動保存が壊れる。そのため status-right 設定後に extraConfig 末尾で手動ロードする。
      pkgs.tmuxPlugins.resurrect
    ];
    extraConfig = (builtins.readFile ../../dotfiles/tmux.conf) + ''

      # ステータスバー
      set -g status on
      set -g status-right-length 150
      set -g status-right "#(${pkgs.kube-tmux}/bin/kube.tmux 250 cyan default)"

      # prefix + s で fzf によるセッション切り替え/管理(MRU順, Claude状態バッジ, CRUDバインド付き)。
      # ピッカー本体は生成スクリプトに切り出している(インラインのクォートが複雑になるのを避けるため)。
      bind s display-popup -E -w 50% -h 50% "${tmuxSessionPicker}"

      # prefix + w で fzf によるウィンドウ切り替え/管理(現在セッション内, CRUDバインド付き)。
      # セッション切替(prefix s)と同じ流儀。既定の choose-tree(prefix w)を置き換える。
      bind w display-popup -E -w 50% -h 50% "${tmuxWindowPicker}"

      # セッション作成時のみセッション名を設定。ウィンドウ名は automatic-rename に委ねる
      set-hook -g after-new-session 'run-shell "${tmuxNameSession} #{pane_current_path}"'

      # tmux-continuum: 必ず status-right を設定し終えた“後”に読み込む。
      # continuum は status-right に保存トリガ #() を追記して定期保存を実現するため、
      # 後から status-right を上書きするとトリガが消えて自動保存が止まる(今回の不具合の原因)。
      # @continuum-restore on で tmux サーバ起動時の自動復元も有効化する(これも未設定だった)。
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '5'
      run-shell ${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/continuum.tmux
    '';
  };
}
