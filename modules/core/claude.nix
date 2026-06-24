{ pkgs, lib, ... }:
{
  # Claude Code の共有設定(permissions/env/language)をリポジトリで管理し ~/.claude/settings.json へ反映する。
  #
  # 単純なシンボリックリンク(read-only)にすると、Claude が /model・/config(theme)・プラグイン有効化で
  # settings.json を自分で書き換える操作が失敗する。
  # そのため jq で「リポジトリの共有ベース」を既存 settings.json にマージし、
  # Claude が管理するキー(model/theme/enabledPlugins/extraKnownMarketplaces)は温存しつつ
  # 書き込み可能なまま保つ。共有ベースのキー(env/language/permissions)は毎回リポジトリ側で上書きする。
  home.activation.claudeSharedSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    base="${../../dotfiles/claude/settings.json}"
    target="$HOME/.claude/settings.json"
    run mkdir -p "$HOME/.claude"
    if [ -f "$target" ]; then
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$target" "$base" > "$target.tmp"
      run mv -f "$target.tmp" "$target"
    else
      run cp "$base" "$target"
    fi
  '';

  # Claude の hook から呼ぶ tmux 状態記録スクリプトを ~/.claude/hooks/ に配置する。
  # settings.json(静的JSON)から安定パスで参照したいので Nix ストアパスではなく
  # 固定パス(~/.claude/hooks/tmux-state.sh)へ実行可能ファイルとして置く。
  home.file.".claude/hooks/tmux-state.sh" = {
    source = ../../dotfiles/claude/hooks/tmux-state.sh;
    executable = true;
  };
}
