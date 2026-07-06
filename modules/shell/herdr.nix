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

    [keys]
    # prefix は tmux と同じ ctrl+b (デフォルトのまま明示)
    prefix = "ctrl+b"
    # タブ移動: tmux の prefix+j/k (前/次ウィンドウ) の手癖を移植。
    # デフォルトの prefix+j/k は focus_pane_down/up なので、そちらは矢印キーへ退避する。
    next_tab = ["prefix+n", "prefix+j"]
    previous_tab = ["prefix+p", "prefix+k"]
    focus_pane_down = ["prefix+down"]
    focus_pane_up = ["prefix+up"]
    # ペイン左右移動はデフォルト(prefix+h / prefix+l)のまま

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
