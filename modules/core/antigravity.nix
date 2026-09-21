{ pkgs, lib, ... }:
{
  # Antigravity CLI(`agy`)の permissions をリポジトリで管理し
  # ~/.gemini/antigravity-cli/settings.json へ反映する。claude.nix と同じ流儀。
  #
  # シンボリックリンク(read-only)にできないのは claude.nix と同じ理由で、agy 自身が
  # この settings.json を書き換えるため。具体的には「Always Allow」で承認したルールが
  # permissions.allow に追記され、/model で model が、ワークスペース信頼で
  # trustedWorkspaces が更新される。そこで jq で「リポジトリの共有ベース」を既存の
  # settings.json にマージし、agy が管理するキー(model/statusLine/trustedWorkspaces)は
  # 温存しつつ書き込み可能なまま保つ。
  #
  # permissions は共有ベースが所有するため、target 側を del してから base をマージする。
  # 単純な再帰マージだと base から削除したルールが target 側に残り続けるため。
  # 裏を返すと、セッション中に「Always Allow」で足したルールは次の switch で消える。
  # 恒久的に残したいものは dotfiles/antigravity/settings.json に書くこと。
  #
  # permission specifier は Claude Code と別物で、agy 側の検証正規表現は
  #   ^(command|read_file|write_file|read_url|mcp|execute_url|unsandboxed)\s*\(.*\)$
  # (`unsandboxed` は廃止済みで、書いても無視され何も許可しない)。
  # command() のターゲットはトークンごとに ^(?:pattern)$ のアンカー付き正規表現として
  # 評価される点が Claude の literal 前方一致と異なり、`$HOME` や `.` を含むルールは
  # ベース側でエスケープしてある。
  home.activation.antigravitySharedSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    base="${../../dotfiles/antigravity/settings.json}"
    target="$HOME/.gemini/antigravity-cli/settings.json"
    run mkdir -p "$HOME/.gemini/antigravity-cli"
    if [ -f "$target" ]; then
      ${pkgs.jq}/bin/jq -s '(.[0] | del(.permissions)) * .[1]' "$target" "$base" > "$target.tmp"
      run mv -f "$target.tmp" "$target"
    else
      run cp "$base" "$target"
    fi
    # store からコピーした直後は read-only(444)になり agy が書けなくなる。
    # また agy 自身は 600 で作るのでそれに合わせる。
    run chmod 600 "$target"
  '';
}
