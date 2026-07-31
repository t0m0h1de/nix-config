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

  # Agent ピッカー用の MRU(pane_id 単位)。workspace-mru とは別ファイルにする:
  # Spaces ピッカーは workspace 粒度が必要で、粒度を混ぜると双方の並びが壊れるため。
  # 記録されるのは「ピッカーで選んで飛んだ先」と「ピッカーを開いた時点の現在地」の2点。
  # (herdr の socket API には pane.focused イベント購読 `events.subscribe` もあり、常駐して
  #  購読すれば Ctrl+hjkl 等も含め完全な履歴が取れるが、常駐プロセスと再接続処理が必要なので
  #  採らない。上記2点で「A↔B を行き来する」実用ケースはほぼ拾える。)
  agentMruFile = ''"''${XDG_CACHE_HOME:-$HOME/.cache}/herdr/agent-mru"'';

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

  # --- フロート Agent ピッカー (fzf, エージェント単位 MRU 順) ---
  # prefix+a で popup に fzf を開き、herdr が検知中のエージェントを一覧 → enter でそのペインへ focus。
  # 並び順は pane_id 単位の MRU(agent-mru):
  #   1. 訪問歴のあるエージェント … agent-mru 順(直近に居た/飛んだものほど上)
  #   2. 訪問歴のないエージェント … workspace MRU 順(未記録 workspace は末尾)→ 各 workspace 内は list 順
  # これで「同じ workspace の Agent 1/2」が塊で上位に来ることはなくなり、1 だけが上、2 は履歴どおりの
  # 位置に出る。agent-mru へ書き戻すのは (1) の訪問済みだけ(未訪問を書くと「行っていないのに履歴上位」
  # に居座り、以降ずっと workspace MRU フォールバックが効かなくなるため)。
  # ※1 対象は「herdr が現在検知しているエージェント」(`herdr agent list`)のみ。workspace list と違い
  #     全ペインではなく検知済みエージェントに限られる(サーバ再起動直後などは検知されるまで出ない)。
  # ※2 「今いるエージェント」の除外は .focused では不可。popup を開くと focus が picker 側へ移り、
  #     直前のエージェントの .focused が false になって一覧に残ってしまう。popup へ渡る
  #     HERDR_ACTIVE_PANE_ID(開く直前にアクティブだったペイン)と .pane_id を突き合わせて除外する
  #     (未設定時のみ .focused で近似)。この active は一覧からは消すが agent-mru の先頭には残す
  #     ——「今いる所」こそ最新の訪問先であり、次に prefix+a を開いた時の 1 位になるべきだから。
  herdrAgentList = pkgs.writeShellScript "herdr-agent-list" ''
    active="''${HERDR_ACTIVE_PANE_ID:-}"
    wsmru=${mruFile}
    amru=${agentMruFile}
    mkdir -p "$(dirname "$amru")"
    touch "$wsmru" "$amru" 2>/dev/null || true

    # 検知中エージェント → <pane_id>\t<workspace_id>\t<表示ラベル>。
    # ※ focus 対象の識別子は pane_id。`herdr agent focus` は terminal_id を受け付けず
    #   agent_not_found になる(herdr 0.7.5 で確認)ので、必ず pane_id を渡すこと。
    # 今アクティブなペイン(HERDR_ACTIVE_PANE_ID。未設定時は .focused で近似)は除外。
    wsjson=$(herdr workspace list)
    agents=$(herdr agent list | jq -r --arg active "$active" --argjson ws "$wsjson" '
      def icon: if   .agent_status=="blocked" then "🔴"
                elif .agent_status=="working" then "🟡"
                elif .agent_status=="unknown" then "⚪"
                else "🟢" end;
      ($ws.result.workspaces | map({ key: .workspace_id, value: .label }) | from_entries) as $lbl
      | .result.agents[]
      | select( if $active != "" then (.pane_id != $active) else (.focused|not) end )
      | [ .pane_id, .workspace_id,
          ( icon + " " + ($lbl[.workspace_id] // .workspace_id)
            + " · " + (.agent // "")
            + " · " + (((.foreground_cwd // .cwd // "") | split("/") | last) // "") ) ]
      | @tsv')

    [ -n "$agents" ] || exit 0

    # MRU ファイルは変数に読み込んでから使う(空ファイルだと awk の NR==FNR が第2入力側で
    # 誤って真になるため、必ず printf 経由で最低1行を渡す)。
    amru_lines=$(cat "$amru")
    wsmru_lines=$(cat "$wsmru")

    # (1) 訪問歴あり: agent-mru の順で、いま現存するエージェントだけを拾う。
    visited=$(awk -F"\t" '
      NR==FNR { live[$1]=1; next }
      ($0 in live) && !seen[$0]++ { print }
    ' <(printf "%s\n" "$agents") <(printf "%s\n" "$amru_lines"))

    # (2) 訪問歴なし: workspace MRU 順(未記録 workspace は末尾)→ 同一 workspace 内は list 順。
    #     workspace 順位を各行に付けて安定ソートする(第2キー = 出現順)。
    unvisited=$(awk -F"\t" '
      NR==FNR { rec[$0]=1; next }
      !($1 in rec) { print }
    ' <(printf "%s\n" "$visited") <(printf "%s\n" "$agents") \
      | awk -F"\t" '
      NR==FNR { if ($0 != "" && !($0 in rank)) rank[$0] = ++r; next }
      { rk = ($2 in rank) ? rank[$2] : 999999; printf "%d\t%d\t%s\n", rk, ++i, $1 }
    ' <(printf "%s\n" "$wsmru_lines") - \
      | sort -k1,1n -k2,2n | cut -f3)

    # GC 兼記録: agent-mru には「現在地 → 訪問済み(現存のみ)」だけを書き戻す。
    # active は agents から除外済みで visited にも入らないので、ここで明示的に先頭へ置く。
    if [ -n "$active" ]; then
      { printf "%s\n" "$active"; printf "%s\n" "$visited" | awk 'NF' | grep -vxF "$active"; } > "$amru.tmp"
    else
      printf "%s\n" "$visited" | awk 'NF' > "$amru.tmp"
    fi
    mv "$amru.tmp" "$amru"

    # fzf 行: 「<icon> <label> · <agent> · <cwd basename>\t<pane_id>\t<workspace_id>」
    printf "%s\n%s\n" "$visited" "$unvisited" | awk -F"\t" '
      NR==FNR { disp[$1] = $3 "\t" $1 "\t" $2; next }
      NF && ($0 in disp) { print disp[$0] }
    ' <(printf "%s\n" "$agents") -
  '';

  # 選択したエージェントへ focus し、あわせて MRU を更新する。become で fzf を置き換えて実行
  # ({1}=pane_id, {2}=workspace_id)。pane は agent-mru の、workspace は workspace-mru の
  # (Spaces ピッカーと共有)それぞれ先頭へ積む。
  #
  # ★ popup 内では「UI を変える API 呼び出し」はスクリプトの最後の1回だけにすること。
  #   popup はセッションモーダルな一時端末なので、focus 系 API(changes_ui=true)を呼ぶと popup
  #   自体が破棄され、その中で走っているこのスクリプトも一緒に殺される。→ 後続の行は実行されない。
  #   実際、以前ここで `herdr workspace focus` を先に呼んでいた版では popup がその時点で閉じ、
  #   次行の `herdr agent focus` に到達せず「workspace は変わるが tab/pane には飛ばない」状態だった
  #   (サーバログに workspace.focus だけが並び agent.focus が一切出ないことで確認)。
  #   `herdr agent focus <pane_id>` は単体で workspace/tab/pane すべてを切り替えるので
  #   (別 workspace のペインを指定して実測: focused workspace/tab/pane がすべて追従)、
  #   workspace focus は不要。MRU ファイルの更新は API を叩かないので先に済ませてよい。
  #
  # 失敗しても popup は即閉じてしまい原因が分からないので、エラー時だけメッセージを出して待つ
  # (失敗時は UI が変わらない = popup が残るので、この表示はちゃんと読める)。
  herdrAgentFocus = pkgs.writeShellScript "herdr-agent-focus" ''
    pane="''${1:-}"
    ws="''${2:-}"
    [ -n "$pane" ] || exit 0

    amru=${agentMruFile}
    mkdir -p "$(dirname "$amru")"
    touch "$amru"
    { printf "%s\n" "$pane"; grep -vxF "$pane" "$amru" 2>/dev/null; } > "$amru.tmp"
    mv "$amru.tmp" "$amru"

    # workspace MRU は Spaces ピッカーと共有。ファイル更新のみ(focus API は呼ばない)。
    if [ -n "$ws" ]; then
      mru=${mruFile}
      touch "$mru"
      { printf "%s\n" "$ws"; grep -vxF "$ws" "$mru" 2>/dev/null; } > "$mru.tmp"
      mv "$mru.tmp" "$mru"
    fi

    # ここから先は popup が閉じる前提。追加の処理を足さないこと。
    if ! err=$(herdr agent focus "$pane" 2>&1); then
      printf 'herdr agent focus %s failed:\n%s\n' "$pane" "$err" >&2
      sleep 3
      exit 1
    fi
  '';

  # ピッカー本体: enter で focus スクリプトへ置換({2}=pane_id, {3}=workspace_id)。
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
