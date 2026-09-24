{ pkgs, lib, ... }:
{
  # Codex CLI の共有設定をリポジトリで管理し ~/.codex/config.toml へ反映する。
  # claude.nix / antigravity.nix と同じ流儀(ツール本体は npm 管理のままで、設定だけ Nix が持つ)。
  #
  # シンボリックリンク(read-only)にできないのは、codex 自身がこの config.toml を書き換えるため。
  # 実際に以下が codex 由来で入っている:
  #   model / model_reasoning_effort        … /model での選択
  #   [projects."<path>"] trust_level       … ディレクトリを信頼したとき
  #   [tui.model_availability_nux]          … 新モデル告知の表示回数カウンタ
  # そこでリポジトリの共有ベースを既存ファイルへマージし、書き込み可能なまま保つ。
  #
  # JSON ではなく TOML なので jq は使えない。yq(mikefarah v4)は `-p toml -o toml` で
  # TOML のラウンドトリップができるため、これを使う(yq-go は packages.nix に既にある)。
  #
  # ベースが持つトップレベルキーを target 側から落としてからマージする。
  # 単純な `$target * $base` だと、ベースからキーを消しても実ファイル側に古い値が残り続けるため。
  #
  # ベースにコメントを書かないこと。yq のマージはコメントを実ファイル側へ運んでしまい、
  # 「ここが原本」と誤解させる紛らわしい出力になる。説明はこのモジュールに書く。
  #
  # なお ~/.codex 配下でこのモジュールが触るのは config.toml だけ。
  # auth.json(認証情報)や *.sqlite / history.jsonl(会話履歴)は一切管理しない。
  home.activation.codexSharedSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    base="${../../dotfiles/codex/config.toml}"
    target="$HOME/.codex/config.toml"
    run mkdir -p "$HOME/.codex"
    if [ -f "$target" ]; then
      ${pkgs.yq-go}/bin/yq eval-all -p toml -o toml \
        'select(fi==0) as $t | select(fi==1) as $b | ($t | with_entries(select(.key as $k | $b | has($k) | not))) * $b' \
        "$target" "$base" > "$target.tmp"
      run mv -f "$target.tmp" "$target"
    else
      run cp "$base" "$target"
    fi
    # store からコピーした直後は read-only(444)になり codex が書けなくなる。
    # また codex 自身が 600 で作るファイルなのでそれに合わせる。
    run chmod 600 "$target"
  '';
}
