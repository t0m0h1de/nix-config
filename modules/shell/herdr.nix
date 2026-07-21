{ pkgs, lib, ... }:
let
  # vim-herdr-navigation: Ctrl+h/j/k/l で herdr ペインと Vim/Neovim split をシームレスに移動
  # する(vim-tmux-navigator の herdr 版)。herdr のプラグイン登録は ~/.config/herdr/plugins.json
  # への書き込みで宣言的管理が難しいため、ソースだけ Nix で固定し activation で `herdr plugin link`
  # する(plugin_root は渡したストアパスを参照するので、closure に入り GC 保護される)。
  vim-herdr-navigation-src = pkgs.fetchFromGitHub {
    owner = "paulbkim-dev";
    repo = "vim-herdr-navigation";
    rev = "53e318c772c4d3b7fbd904ac43bcf3e5b5d8b244";
    hash = "sha256-vUUt46jiK6ZsPH8D13/+IIlqT3KbFliPJkNplsVqiQo=";
  };

  # navigate.sh の passthrough 既定を fzf に焼き込むパッチ。
  # 上流は Ctrl+h/j/k/l を Vim/Neovim にしか転送せず、fzf 等の TUI 前面では herdr のペイン移動に
  # 消費されてしまう(→ fzf の選択移動 Ctrl+j/k が効かない)。env HERDR_NAV_PASSTHROUGH_RE で
  # opt-in できるが、herdr サーバへの env 継承は起動タイミング依存で不確実だったため、サーバが毎回
  # 実行する navigate.sh 自体の既定を fzf にする(env が設定されていればそちらが優先されるまま)。
  vim-herdr-navigation = pkgs.runCommand "vim-herdr-navigation" { } ''
    cp -r ${vim-herdr-navigation-src} $out
    chmod -R u+w $out
    substituteInPlace $out/navigate.sh \
      --replace-fail 'passthrough_re="''${HERDR_NAV_PASSTHROUGH_RE:-}"' \
                     'passthrough_re="''${HERDR_NAV_PASSTHROUGH_RE:-fzf}"'
  '';

  # --- フロート Spaces ピッカー (fzf, 自前 MRU) ---
  # サイドバー(Spaces一覧)の代替として prefix+s で fzf ピッカーを一時ペインに開き、
  # workspace を絞り込み → enter で focus する(ネイティブ workspace_picker は prefix+shift+s に退避)。
  #
  # MRU(最終アタッチ順)について: herdr の API は last-attached/last-focused の時刻を一切返さない
  # (workspace list の focused は「今フォーカス中か」の bool のみ、number は作成順)。そのため
  # 「空クエリ時に最終アタッチ順」は自前の MRU ファイルで実現する。focus のたびに先頭へ積む。
  # GC: ピッカーを開くたびに現存 workspace で MRU ファイルを刈り込んで書き戻すので肥大化しない。
  mruFile = ''"''${XDG_CACHE_HOME:-$HOME/.cache}/herdr/workspace-mru"'';

  # 一覧生成: 現存 workspace を「MRU ファイル順(現存のみ) → 未記録の現存を list 順」で並べ、
  # 刈り込んだ MRU を書き戻し(GC)、fzf 用に「<icon+label>\t<workspace_id>」を出力する。
  # 現在フォーカス中の workspace は切替対象外なので除外する(先頭に「今いる所」が来ないように)。
  herdrWorkspaceList = pkgs.writeShellScript "herdr-workspace-list" ''
    mru=${mruFile}
    mkdir -p "$(dirname "$mru")"
    touch "$mru"

    # <id>\t<icon + label>\t<focused>
    list=$(herdr workspace list | jq -r '
      .result.workspaces[]
      | (if   .agent_status=="blocked" then "🔴"
         elif .agent_status=="working" then "🟡"
         elif .agent_status=="done"    then "🔵"
         elif .agent_status=="idle"    then "🟢"
         else "⚪" end) as $icon
      | [.workspace_id, ($icon + " " + .label), (.focused|tostring)] | @tsv')

    # MRU 順の id 列(MRU ファイル順で現存のみ → 未記録の現存を list 順で末尾に)
    ordered=$(awk -F"\t" '
      NR==FNR { live[$1]=1; order[++n]=$1; next }
      ($0 in live) && !seen[$0]++ { print }
      END { for (i=1;i<=n;i++) if (!seen[order[i]]++) print order[i] }
    ' <(printf "%s\n" "$list") "$mru")

    # GC: 現存する id だけに刈り込んだ MRU を書き戻す
    printf "%s\n" "$ordered" | awk 'NF' > "$mru"

    # fzf 行: <display>\t<id>。現在フォーカス中は除外。
    awk -F"\t" '
      NR==FNR { disp[$1]=$2; foc[$1]=$3; next }
      NF && foc[$0]!="true" { print disp[$0] "\t" $0 }
    ' <(printf "%s\n" "$list") <(printf "%s\n" "$ordered")
  '';

  # 選択した workspace を MRU 先頭へ積んでから focus する(become で fzf を置き換えて実行)。
  herdrWorkspaceFocus = pkgs.writeShellScript "herdr-workspace-focus" ''
    id="''${1:-}"
    [ -n "$id" ] || exit 0
    mru=${mruFile}
    mkdir -p "$(dirname "$mru")"
    touch "$mru"
    { printf "%s\n" "$id"; grep -vxF "$id" "$mru" 2>/dev/null; } > "$mru.tmp"
    mv "$mru.tmp" "$mru"
    herdr workspace focus "$id" >/dev/null 2>&1
  '';

  # ピッカー本体: 一覧を fzf に流し、enter で focus スクリプトへ置き換える(tmux 版と同じ流儀)。
  # fzf には表示ラベル列(--with-nth=1)だけ見せ、操作には workspace_id 列 {2} を使う。
  herdrWorkspacePicker = pkgs.writeShellScript "herdr-workspace-picker" ''
    ${herdrWorkspaceList} \
      | fzf --reverse --delimiter='\t' --with-nth=1 --nth=1 --prompt 'space> ' \
          --header 'enter:switch' \
          --bind 'enter:become(${herdrWorkspaceFocus} {2})'
  '';

  # --- フロート Agent ピッカー (fzf, workspace MRU 順) ---
  # prefix+a で popup に fzf を開き、herdr が検知中のエージェントを workspace MRU 順(=最近フォーカス
  # した workspace のエージェントから)で一覧 → enter でそのエージェントのペインへ focus。
  # Spaces ピッカーと同じ MRU ファイルを共有し、focus 時にその workspace を MRU 先頭へ積む。
  # ※1 対象は「herdr が現在検知しているエージェント」(`herdr agent list`)のみ。workspace list と違い
  #     全ペインではなく検知済みエージェントに限られる(サーバ再起動直後などは検知されるまで出ない)。
  # ※2 「今いるエージェント」の除外は .focused では不可。popup を開くと focus が picker 側へ移り、
  #     直前のエージェントの .focused が false になって一覧に残ってしまう(しかも blocked/working だと
  #     従来の priority ソートで先頭に来て邪魔)。popup へ渡る HERDR_ACTIVE_PANE_ID(開く直前に
  #     アクティブだったペイン)と .pane_id を突き合わせて除外する(未設定時のみ .focused で近似)。
  herdrAgentList = pkgs.writeShellScript "herdr-agent-list" ''
    active="''${HERDR_ACTIVE_PANE_ID:-}"
    mru=${mruFile}
    touch "$mru" 2>/dev/null || true

    # workspace_id -> label
    wsmap=$(herdr workspace list | jq -r '.result.workspaces[] | [.workspace_id, .label] | @tsv')

    # 検知中エージェント → <workspace_id>\t<icon>\t<agent>\t<cwd>\t<terminal_id>。
    # 今アクティブなペイン(HERDR_ACTIVE_PANE_ID。未設定時は .focused で近似)は除外。
    agents=$(herdr agent list | jq -r --arg active "$active" '
      def icon: if   .agent_status=="blocked" then "🔴"
                elif .agent_status=="working" then "🟡"
                elif .agent_status=="unknown" then "⚪"
                else "🟢" end;
      .result.agents[]
      | select( if $active != "" then (.pane_id != $active) else (.focused|not) end )
      | [ .workspace_id, icon, (.agent // ""), (.foreground_cwd // .cwd // ""), .terminal_id ] | @tsv')

    [ -n "$agents" ] || exit 0

    # agents に含まれる workspace_id を「MRU ファイル順(現存のみ) → 未記録は出現順」で整列。
    wsorder=$(awk -F"\t" '
      NR==FNR { if (!($1 in live)) { live[$1]=1; order[++n]=$1 }; next }
      ($0 in live) && !seen[$0]++ { print }
      END { for (i=1;i<=n;i++) if (!seen[order[i]]++) print order[i] }
    ' <(printf "%s\n" "$agents") "$mru")

    # workspace MRU 順に、その workspace のエージェント行を出現順で出力。
    # fzf 行: 「<icon> <label> · <agent> · <cwd basename>\t<terminal_id>\t<workspace_id>」
    printf "%s\n" "$wsorder" | while IFS= read -r ws; do
      [ -n "$ws" ] || continue
      label=$(printf "%s\n" "$wsmap" | awk -F"\t" -v w="$ws" '$1==w{print $2; exit}')
      [ -n "$label" ] || label="$ws"
      printf "%s\n" "$agents" | awk -F"\t" -v w="$ws" -v label="$label" '
        $1==w {
          n=split($4,p,"/"); base=(n>0?p[n]:$4)
          printf "%s %s · %s · %s\t%s\t%s\n", $2, label, $3, base, $5, $1
        }'
    done
  '';

  # 選択したエージェントへ focus し、あわせてその workspace を MRU 先頭へ積む(Spaces ピッカーと
  # 共有。次回の並びに反映)。become で fzf を置き換えて実行({1}=terminal_id, {2}=workspace_id)。
  herdrAgentFocus = pkgs.writeShellScript "herdr-agent-focus" ''
    term="''${1:-}"
    ws="''${2:-}"
    [ -n "$term" ] || exit 0
    if [ -n "$ws" ]; then
      mru=${mruFile}
      mkdir -p "$(dirname "$mru")"
      touch "$mru"
      { printf "%s\n" "$ws"; grep -vxF "$ws" "$mru" 2>/dev/null; } > "$mru.tmp"
      mv "$mru.tmp" "$mru"
    fi
    herdr agent focus "$term" >/dev/null 2>&1
  '';

  # ピッカー本体: enter で focus スクリプトへ置換({2}=terminal_id, {3}=workspace_id)。
  herdrAgentPicker = pkgs.writeShellScript "herdr-agent-picker" ''
    ${herdrAgentList} \
      | fzf --reverse --delimiter='\t' --with-nth=1 --nth=1 --prompt 'agent> ' \
          --header 'enter:focus' \
          --bind 'enter:become(${herdrAgentFocus} {2} {3})'
  '';
in
{
  # herdr (AIエージェント向けターミナルワークスペース) の設定。
  # パッケージ本体は modules/core/packages.nix (nixpkgs管理)。
  # 設定リファレンス: https://herdr.dev/docs/configuration/
  # 変更後は `herdr server reload-config` で稼働中サーバに反映できる。
  #
  # 注意: これは read-only シンボリックリンクになる。herdr の設定UI(prefix+s)や
  # `herdr config reset-keys` は config.toml へ書き込もうとするため失敗し得る。
  # 設定変更は基本このファイルを編集 → switch → reload-config で行うこと。
  xdg.configFile."herdr/config.toml".text = ''
    # 初回オンボーディングはスキップ(設定はこのファイルで宣言管理する)
    onboarding = false

    [theme]
    # オンボーディングで選択したテーマを維持
    name = "nord"
    auto_switch = false

    [update]
    # Nix 管理のため self-update (`herdr update`) は使わない(nix store は read-only)。
    # 更新は nixpkgs 経由。バージョン通知だけ切る。エージェント検知マニフェスト更新は有効のまま。
    version_check = false
    manifest_check = true

    [session]
    # 復元時に Claude Code 等をネイティブ会話セッションごと再開する(デフォルトtrueだが明示)
    resume_agents_on_restore = true

    [ui]
    # サイドバー(エージェント状態一覧)を attention 優先で並べる
    agent_panel_sort = "priority"

    # キーバインドは可能な範囲で tmux(デフォルト + 現行 tmux.conf のカスタム)に合わせる。
    # herdr の概念対応: workspace ≈ tmux session / tab ≈ tmux window / pane ≈ tmux pane。
    # ※ herdr のモデル差で完全一致できない項目(リサイズ等)は末尾コメント参照。
    [keys]
    prefix = "ctrl+b"                          # tmux: prefix = C-b

    # --- セッション (herdr workspace ≈ tmux session) ---
    # prefix+s は自前の fzf フロート Spaces ピッカー([[keys.command]] 末尾)に割当。
    # ネイティブの workspace_picker は prefix+shift+s へ退避(fzf が動かない時のフォールバック)。
    workspace_picker = "prefix+shift+s"        # ネイティブ Spaces ピッカー(fzf ピッカーの保険)
    # ネイティブ workspace_picker 内の選択移動を j/k でも行う(既定は矢印)。
    navigate_workspace_down = "j"
    navigate_workspace_up = "k"
    detach = "prefix+d"                        # tmux: prefix+d (detach)
    rename_workspace = "prefix+$"              # tmux: prefix+$ (rename-session)
    # 設定UI。prefix+shift+s は workspace_picker に譲ったので、new_worktree 無効化で空いた
    # prefix+shift+g へ退避(このリポジトリでは config が read-only なので設定UIは実質参照用)。
    settings = "prefix+shift+g"                # herdr固有(tmux非対応)
    # 統合ジャンプピッカー(goto)を prefix+w でも開く。
    # ※ herdr には pane 専用のピッカーアクションが無いため、最も近い goto を割当(既定 prefix+g も残す)。
    goto = ["prefix+g", "prefix+w"]

    # --- ウィンドウ (herdr tab ≈ tmux window) ---
    new_tab = "prefix+c"                       # tmux: prefix+c (new-window)
    rename_tab = "prefix+comma"                # tmux: prefix+, (rename-window)
    close_tab = "prefix+ampersand"             # tmux: prefix+& (kill-window)
    # タブ移動: prefix+n/p(tmux既定)+ prefix+j/k(現行 tmux.conf 独自)+ prefix+l/h(vim の左右=次/前)。
    next_tab = ["prefix+n", "prefix+j", "prefix+l"]      # 次タブ: prefix+n / prefix+j / prefix+l
    previous_tab = ["prefix+p", "prefix+k", "prefix+h"]  # 前タブ: prefix+p / prefix+k / prefix+h
    switch_tab = "prefix+1..9"                 # tmux: prefix+0..9 (select-window)

    # --- ペイン ---
    split_vertical = "prefix+%"                # tmux: prefix+% (split-window -h / 左右分割)
    split_horizontal = "prefix+\""             # tmux: prefix+" (split-window -v / 上下分割)
    close_pane = "prefix+x"                    # tmux: prefix+x (kill-pane)
    zoom = "prefix+z"                          # tmux: prefix+z (resize-pane -Z)
    # ペイン移動: tmux 既定の prefix+方向キー(select-pane)。C-hjkl は vim-herdr-navigation(下 [[keys.command]])で対応。
    focus_pane_left = "prefix+left"
    focus_pane_down = "prefix+down"
    focus_pane_up = "prefix+up"
    focus_pane_right = "prefix+right"

    # --- その他 ---
    help = "prefix+?"                          # tmux: prefix+? (list-keys)
    # worktree 作成は gwq に一任するため herdr の作成キー(既定 prefix+shift+g)を無効化。
    # 非gitディレクトリで誤起動して "worktree actions require a Git work tree" 警告(消えない)を誘発するのも防ぐ。
    new_worktree = ""

    # tmux と完全一致できない/概念が異なる項目(herdr 既定のまま):
    #   - ペインリサイズ: tmux 独自の prefix+H/J/K/L(直接)に対し herdr は resize_mode(prefix+r)。
    #   - pane rename: tmux 既定に相当なし(herdr rename_pane = prefix+shift+p のまま)。
    #   - copy mode(prefix+[), next/last pane(prefix+o / prefix+;) 等の細かいキーは herdr 既定のまま。

    # フロート Spaces ピッカー(fzf, 自前MRU)。prefix+s でフロート popup に開き、workspace を
    # 絞り込み → enter で focus。空クエリ時は最終アタッチ順(MRU)で並ぶ。実装は先頭の let を参照。
    # herdr 0.7.4+ の type="popup"(セッションモーダルなフロート端末。tab レイアウトを変えず、
    # command 終了まで Escape 含む全入力を受け取る)を利用。width/height は border 込み、割合指定可。
    [[keys.command]]
    key = "prefix+s"
    type = "popup"
    command = "${herdrWorkspacePicker}"
    description = "Spaces picker (fzf, MRU)"
    width = "70%"
    height = "70%"

    # フロート Agent ピッカー(fzf, 注目度順)。prefix+a でフロート popup に開き、検知中のエージェントを
    # 一覧 → enter でそのペインへ focus。対象は herdr が検知中のエージェントのみ(実装は先頭の let 参照)。
    # Spaces ピッカーと同じく herdr 0.7.4+ の type="popup" を利用。
    [[keys.command]]
    key = "prefix+a"
    type = "popup"
    command = "${herdrAgentPicker}"
    description = "Agents picker (fzf, attention order)"
    width = "70%"
    height = "70%"

    # vim-herdr-navigation: 直接の Ctrl+h/j/k/l をプラグインアクションに割当。
    # フォアグラウンドが Vim/Neovim なら Vim に転送し、そうでなければ herdr ペインを移動する。
    # (nvim 側マッピングは modules/editors/nvim/plugins.nix、登録は下の activation)
    # ※ fzf など Ctrl+h/j/k/l を自前で使う TUI では、これがペイン移動に消費されキーが届かない。
    #   下の HERDR_NAV_PASSTHROUGH_RE で fzf 前面時はそのまま fzf へ転送させている。
    [[keys.command]]
    key = "ctrl+h"
    type = "plugin_action"
    command = "vim-herdr-navigation.left"
    description = "navigate left (vim/herdr)"

    [[keys.command]]
    key = "ctrl+j"
    type = "plugin_action"
    command = "vim-herdr-navigation.down"
    description = "navigate down (vim/herdr)"

    [[keys.command]]
    key = "ctrl+k"
    type = "plugin_action"
    command = "vim-herdr-navigation.up"
    description = "navigate up (vim/herdr)"

    [[keys.command]]
    key = "ctrl+l"
    type = "plugin_action"
    command = "vim-herdr-navigation.right"
    description = "navigate right (vim/herdr)"
  '';

  # fzf passthrough は上の navigate.sh パッチ(既定 fzf)で担保済み。この env は追加の TUI を
  # 増やしたい時の上書き用に残す(例: "fzf|lazygit")。設定するとパッチ既定より優先される。
  # ただしサーバへの env 継承は起動タイミング依存なので、確実性はパッチ側に置いている。
  home.sessionVariables.HERDR_NAV_PASSTHROUGH_RE = "fzf";

  # vim-herdr-navigation を herdr に登録する(plugins.json)。ソースは Nix ストアに固定する。
  # パッチで navigate.sh を変えるとストアパスが変わるため、毎 switch で一旦 unlink → 現行パスへ
  # link し直す(link だけだと既存 id が古いストアパスのまま残り、パッチが反映されない)。
  # herdr サーバ未起動時は失敗し得るので best-effort(|| true)。反映後 `herdr plugin list` で確認。
  home.activation.herdrLinkNavPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.herdr}/bin/herdr plugin unlink vim-herdr-navigation > /dev/null 2>&1 || true
    ${pkgs.herdr}/bin/herdr plugin link "${vim-herdr-navigation}" > /dev/null 2>&1 || true
  '';
}
