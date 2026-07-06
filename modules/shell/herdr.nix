{ pkgs, lib, ... }:
let
  # vim-herdr-navigation: Ctrl+h/j/k/l で herdr ペインと Vim/Neovim split をシームレスに移動
  # する(vim-tmux-navigator の herdr 版)。herdr のプラグイン登録は ~/.config/herdr/plugins.json
  # への書き込みで宣言的管理が難しいため、ソースだけ Nix で固定し activation で `herdr plugin link`
  # する(plugin_root は渡したストアパスを参照するので、closure に入り GC 保護される)。
  vim-herdr-navigation = pkgs.fetchFromGitHub {
    owner = "paulbkim-dev";
    repo = "vim-herdr-navigation";
    rev = "53e318c772c4d3b7fbd904ac43bcf3e5b5d8b244";
    hash = "sha256-vUUt46jiK6ZsPH8D13/+IIlqT3KbFliPJkNplsVqiQo=";
  };
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
    workspace_picker = "prefix+s"              # tmux: prefix+s (セッション一覧 choose-session)
    # セッション一覧(workspace_picker)内の選択移動を j/k でも行う(既定は矢印)。
    navigate_workspace_down = "j"
    navigate_workspace_up = "k"
    detach = "prefix+d"                        # tmux: prefix+d (detach)
    rename_workspace = "prefix+$"              # tmux: prefix+$ (rename-session)
    settings = "prefix+shift+s"                # herdr固有(tmux非対応)。prefix+s を workspace_picker に譲るため退避
    # 統合ジャンプピッカー(goto)を prefix+w でも開く。
    # ※ herdr には pane 専用のピッカーアクションが無いため、最も近い goto を割当(既定 prefix+g も残す)。
    goto = ["prefix+g", "prefix+w"]

    # --- ウィンドウ (herdr tab ≈ tmux window) ---
    new_tab = "prefix+c"                       # tmux: prefix+c (new-window)
    rename_tab = "prefix+comma"                # tmux: prefix+, (rename-window)
    close_tab = "prefix+ampersand"             # tmux: prefix+& (kill-window)
    next_tab = ["prefix+n", "prefix+j"]        # tmux: prefix+n (+ 現行 tmux.conf の独自 prefix+j)
    previous_tab = ["prefix+p", "prefix+k"]    # tmux: prefix+p (+ 独自 prefix+k)
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

    # tmux と完全一致できない/概念が異なる項目(herdr 既定のまま):
    #   - ペインリサイズ: tmux 独自の prefix+H/J/K/L(直接)に対し herdr は resize_mode(prefix+r)。
    #   - pane rename: tmux 既定に相当なし(herdr rename_pane = prefix+shift+p のまま)。
    #   - copy mode(prefix+[), next/last pane(prefix+o / prefix+;) 等の細かいキーは herdr 既定のまま。

    # vim-herdr-navigation: 直接の Ctrl+h/j/k/l をプラグインアクションに割当。
    # フォアグラウンドが Vim/Neovim なら Vim に転送し、そうでなければ herdr ペインを移動する。
    # (nvim 側マッピングは modules/editors/nvim/plugins.nix、登録は下の activation)
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

  # vim-herdr-navigation を herdr に登録する(plugins.json)。ソースは Nix ストアに固定し、
  # 毎 switch で現行ストアパスへ再リンクする(冪等)。herdr サーバ未起動時は失敗し得るので
  # best-effort(|| true)。反映後 `herdr plugin list` で確認できる。
  home.activation.herdrLinkNavPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.herdr}/bin/herdr plugin link "${vim-herdr-navigation}" > /dev/null 2>&1 || true
  '';
}
