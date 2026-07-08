{ pkgs, lib, ... }:
{
  # Claude Code の共有設定(permissions/env/language)をリポジトリで管理し ~/.claude/settings.json へ反映する。
  #
  # 単純なシンボリックリンク(read-only)にすると、Claude が /model・/config(theme)・プラグイン有効化で
  # settings.json を自分で書き換える操作が失敗する。
  # そのため jq で「リポジトリの共有ベース」を既存 settings.json にマージし、
  # Claude が管理するキー(model/theme/enabledPlugins/extraKnownMarketplaces)は温存しつつ
  # 書き込み可能なまま保つ。
  # 共有ベースが所有するキー(env/language/permissions/hooks)は、target 側を del してから
  # base をマージする。単純な '.[0] * .[1]' の再帰マージだと base から削除したエントリ
  # (例: 廃止した tmux-state hook のイベント)が target 側に残り続けるため、それを防ぐ。
  home.activation.claudeSharedSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    base="${../../dotfiles/claude/settings.json}"
    target="$HOME/.claude/settings.json"
    run mkdir -p "$HOME/.claude"
    if [ -f "$target" ]; then
      ${pkgs.jq}/bin/jq -s '(.[0] | del(.env, .language, .permissions, .hooks)) * .[1]' "$target" "$base" > "$target.tmp"
      run mv -f "$target.tmp" "$target"
    else
      run cp "$base" "$target"
    fi

    # マシンローカルの追加作業ディレクトリ(repo外・git追跡しない)を permissions.additionalDirectories に注入する。
    # 絶対パスは環境依存(ユーザー/マシン/会社)なので base(コミット対象)には置かず、各マシンがこの外部
    # ファイル(JSON配列)で定義する。.secrets と同じ発想。ファイルが無ければ何もしない。
    #   例: printf '%s' '["/Users/you/src/github.com/foo-inc"]' > ~/.claude/additional-directories.json
    localdirs="$HOME/.claude/additional-directories.json"
    if [ -f "$localdirs" ]; then
      ${pkgs.jq}/bin/jq --slurpfile d "$localdirs" '.permissions.additionalDirectories = $d[0]' "$target" > "$target.tmp"
      run mv -f "$target.tmp" "$target"
    fi
  '';
}
