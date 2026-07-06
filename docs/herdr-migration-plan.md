# tmux → herdr 移行プラン

作成: 2026-07-06 / 対象リポジトリ: このリポジトリ (nix-config)
実行者: AIエージェント(Opus/Sonnet想定)。**このドキュメントだけで作業が完結するように書いてある。**

---

## 0. 実行者への必須指示

- 作業前に `docs/progress.md` を読むこと。作業後(各フェーズ完了ごと)に更新すること(CLAUDE.md のルール)。
- Nix ファイル編集後は必ず `nixpkgs-fmt <file>` で整形し、
  `nix eval .#homeConfigurations.work.activationPackage.drvPath` で評価が通ることを確認すること。
- コミットは main 直接・**1論理変更=1コミット**(このリポジトリの慣習。`git log --oneline` を参照)。
- 本プランには「✅確認済み」と「⚠️未確認(実行者が検証する)」を明示している。未確認事項を確認せずに破壊的変更(Phase 3)へ進まないこと。
- ユーザー判断が必要な箇所は「🙋要ユーザー確認」と記してある。勝手に決めず AskUserQuestion で確認すること。

---

## 1. 背景と目的

現在 tmux を「永続セッション + ペイン分割 + **Claude Code の状態可視化**」のために使っており、
そのために大量の自作機構(fzf ピッカー、Claude hooks による状態スタンプ、resurrect/continuum 等)を抱えている。

[herdr](https://github.com/ogulcancelik/herdr) は「AIコーディングエージェント向けに再構築された tmux」で、
これらの大半が**ネイティブ機能**になっている。自作機構を捨てて herdr に寄せるのが本移行の目的。

### herdr の確認済み事実 (herdr 0.7.1, nixpkgs 管理でインストール済み)

情報源: `herdr --help` / `herdr --default-config` / https://herdr.dev/docs/configuration/ /
https://herdr.dev/docs/keyboard/ / https://herdr.dev/docs/agents/ / GitHub README。
以下はすべて実バイナリまたは公式ドキュメントで確認した内容。

- ✅ server/client 構成の永続セッション(detach/reattach、named sessions、SSHリモート)。tmux 相当。
- ✅ workspace(≒tmuxセッション) / tab(≒tmuxウィンドウ) / pane の3階層。マウスネイティブ。
- ✅ **エージェント状態のネイティブ検知**: サイドバーに 🔴blocked / 🟡working / 🔵done / 🟢idle。
  Claude Code はプロセス名マッチ + 画面ヒューリスティックで**フック不要・ゼロ設定**で検知される
  (blocked は「承認/質問/許可UIが画面に見えている時のみ」の厳格判定)。
- ✅ 設定は `~/.config/herdr/config.toml`(TOML)。`herdr --default-config` で全デフォルトを出力できる。
  変更後は `herdr server reload-config` で再読込。
- ✅ prefix は `ctrl+b`(tmuxデフォルトと同じ)。`[keys]` セクションでリバインド可。
  1アクションに複数キー割当可(`focus_pane_left = ["prefix+h", "ctrl+alt+h"]`)。
- ✅ copy mode は `prefix+[`、vi風キー(h/j/k/l, v, y)。**マウスドラッグ選択は自動コピー**(copy mode 不要)。
- ✅ CLI/socket API が充実: `herdr workspace|tab|pane|agent|worktree|notification ...`
  (スクリプトから workspace 作成・ラベル付け・エージェント状態取得などが可能)。
- ✅ `[session] resume_agents_on_restore = true`(デフォルト有効): セッション復元時に
  Claude Code 等を**ネイティブの会話セッションごと再開**する。
- ✅ `herdr integration install claude` という組込み統合もあるが、Claude Code は**統合なしで検知が機能する**
  (統合はライフサイクルフックを追加するが、Claude では意図的に部分的で、画面検知と併用される)。
- ✅ nixpkgs の herdr 0.7.1 は 2026-07-05 チャンネルで darwin ビルド修正済み・キャッシュあり(導入済み)。

### herdr に無い/違うもの(移行で失われる・変わるもの)

- ❌ tmux の status-right 相当が無い → **kube-tmux(k8sコンテキスト表示)の行き場がない**(§5 Phase 2 参照)。
- ❌ vim-tmux-navigator(`C-hjkl` で nvim split と tmux pane をシームレス移動)は tmux 専用。
  herdr では pane 移動は `prefix+h/j/k/l`(nvim 内の `C-hjkl` は nvim の split 移動として引き続き機能する)。
- ⚠️ tmux の automatic-rename(ウィンドウ名=実行中コマンド名)相当は未確認。
  herdr はエージェントラベルをサイドバー表示するが、tab 名の自動リネームは確認できていない。
- ⚠️ サーバ再起動(マシン再起動)後のレイアウト完全復元は未確認(Phase 0 で検証)。
  `[experimental] pane_history` で画面内容の保存は可能(セキュリティ理由でデフォルト無効)。

---

## 2. 現状インベントリ(移行対象の全ファイル)

### 2.1 `dotfiles/tmux.conf` (全体が移行対象)

| 設定 | 内容 | herdr での扱い |
|---|---|---|
| `escape-time 10` / `focus-events on` | nvim向け調整 | 不要(herdr内部処理) |
| OSC52 clipboard (`set-clipboard on` 等) | コピー連携 | 不要(herdrネイティブ。⚠️SSH越しは未確認) |
| ペインボーダー色 / window-style(非アクティブ暗色) | 外観 | `[theme]`/`[ui] pane_borders` で近似(完全一致はしない) |
| `mouse on` + WheelUpPane | マウス | 不要(マウスネイティブ) |
| `mode-keys vi` | copy-mode vi | herdr copy mode がデフォルトvi風 |
| vim-tmux-navigator (`C-hjkl` + is_vim判定) | ペイン移動 | `prefix+h/j/k/l` へ(§1参照) |
| copy-mode Enter 2段階(ヤンク後留まる) + MouseDragEnd1Pane | コピー挙動 | マウスは自動コピーで同等。⚠️キーボード`y`後の挙動は未確認 |
| `prefix H/J/K/L` リサイズ | リサイズ | `prefix+r`(resize mode)へ |
| `prefix C-l` (clear screen 代替) | C-lがペイン移動に取られていたための代替 | 不要(herdrは`C-l`を奪わないのでシェルに直接届く) |
| `prefix j/k` ウィンドウ移動 | タブ移動 | デフォルト `prefix+n/p`。j/k化はオプション(§5 Phase 1) |
| automatic-rename | ウィンドウ名 | ⚠️未確認(§1) |

### 2.2 `modules/shell/tmux.nix` (全体が移行対象)

- `tmuxNameSession`: セッション名を `repo@branch` に自動命名(after-new-session hook)。
  → herdr では workspace ラベル。同等の zsh ヘルパー `hws` を新設して置き換え(§5 Phase 2 に全文)。
- `tmuxSessionList/Create/Picker`(prefix+s, fzf, MRU順, `@claude_state` バッジ, C-a/C-d/C-r CRUD)
  → herdr のサイドバー+`prefix+w`(workspace_picker)+`prefix+g`(goto) がネイティブ代替。**削除**。
- `tmuxWindowList/Create/Picker`(prefix+w, fzf, CRUD) → 同上。**削除**。
- plugins: `tmux-fzf`(session.sh をMRU+claude バッジに override) → **削除**。
  `resurrect` + `continuum`(status-right 後に手動ロード、interval 5分, restore on)
  → herdr のサーバ永続 + `resume_agents_on_restore` が代替。**削除**。
- `status-right` の kube-tmux → 🙋要ユーザー確認(§5 Phase 2)。
- `bind s` / `bind w` → herdr ネイティブへ。

### 2.3 Claude 状態スタンプ機構 (移行対象 — herdr がネイティブ検知するため全て不要)

- `dotfiles/claude/hooks/tmux-state.sh` … `$TMUX_PANE` から自セッションに `@claude_state` を set するスクリプト。**削除**。
- `modules/core/claude.nix` の `home.file.".claude/hooks/tmux-state.sh"` ブロック。**削除**。
- `dotfiles/claude/settings.json` の `hooks` から **tmux-state.sh を呼ぶエントリのみ削除**:
  - `UserPromptSubmit`(working) / `Notification`(permission_prompt→waiting) /
    `Stop`(idle) / `SessionStart`(startup→idle) / `SessionEnd`(clear) の各ブロック
  - `PreToolUse` 配列内の `"matcher": "AskUserQuestion"` エントリ(waiting)
- **絶対に残すもの**(tmuxと無関係の安全ガード):
  - `PreToolUse` の find `-exec` 禁止 hook(`*find*-exec*` → deny)
  - `PreToolUse` の cd+リダイレクト禁止 hook(`cd`+`>` → deny)
  - `permissions` / `env` / `language` セクション全部

### 2.4 関連するが今回は触らないもの

- `modules/editors/nvim/plugins.nix:169` の `plugins.tmux-navigator`
  … tmux外では無害(nvim内のsplit移動として機能)。Phase 3 で tmux を完全撤去する際に削除してよい。
- `overlays/default.nix` の `kube-tmux` … tmux status-right 専用。Phase 3 で tmux.nix と同時に削除
  (他に参照が無いことを `grep -rn "kube-tmux" --include="*.nix" .` で確認してから)。
- `dotfiles/zshrc` の `ghq-fzf`(C-g) / `cd-nav` / `kctx` / `kns` … シェル機能。**herdr移行の影響なし。触らない**。
- `modules/dev/k8s.nix` の kubie … 無関係。触らない。

---

## 3. 移行後の姿(ゴール)

- ターミナル起動 → `herdr` 一発で永続ワークスペースにアタッチ。
- リポジトリごとに workspace(ラベル `repo@branch`、`hws` ヘルパーで作成)。タブ=作業単位。
- Claude Code の状態はサイドバーで常時可視(自作フック無し)。
- 設定は `~/.config/herdr/config.toml` を home-manager(`xdg.configFile`)で宣言管理。
- tmux・関連自作機構・Claude状態フックは全廃(Phase 3 完了後)。

---

## 4. フェーズ構成(概要)

| Phase | 内容 | 破壊的変更 |
|---|---|---|
| 0 | 動作検証(何も変更しない) | なし |
| 1 | config.toml を nix 管理化 + 起動導線 | なし(追加のみ) |
| 2 | ワークフロー移行(hws ヘルパー、Claude hooks 削除、kube 代替) | settings.json の hooks 削減 |
| 3 | tmux 完全撤去 | tmux.nix / tmux.conf / kube-tmux 等の削除 |

Phase 0→1→2 は連続実行可。**Phase 3 はユーザーが herdr を数日使って合格判定を出してから**(🙋要ユーザー確認)。
それまで tmux と herdr は共存する(同じ prefix `ctrl+b` だが、**入れ子にしなければ衝突しない**。
herdr は tmux の外・素のターミナルで起動すること。herdr には nested 起動ガードもある)。

---

## 5. フェーズ詳細

### Phase 0: 動作検証(変更なし)

前提: `home-manager switch --flake .#work` 適用済みで `herdr` が PATH にあること(`herdr --version` → 0.7.1)。

チェックリスト(結果を docs/progress.md に記録):

1. **tmux の外の**素のターミナルで `herdr` を起動 → ワークスペースが開くこと。
2. ペインで `claude` を起動し、サイドバーの状態表示を確認:
   - プロンプト送信中に 🟡working になるか
   - permission prompt / AskUserQuestion で 🔴blocked になるか
   - 応答完了で 🔵done/🟢idle になるか
3. `prefix+q` でデタッチ → `herdr` で再アタッチ → claude が生きていること。
4. `herdr server stop` でサーバ停止 → `herdr` 再起動 → ⚠️レイアウト・エージェントが復元されるか
   (`[session] resume_agents_on_restore` の実挙動確認。**マシン再起動相当の検証**)。
5. コピー動作: マウスドラッグでシステムクリップボードに入るか。copy mode(`prefix+[`)の vi 操作。
6. nvim をペインで開き、表示崩れ・`C-hjkl`(nvim内split移動)・IME入力を確認。
   `echo $TERM` の値も記録(zsh/nvim の想定と齟齬がないか)。
7. `herdr agent list` / `herdr workspace list` が状態を返すこと(CLI疎通)。

**判定**: 2(状態検知) と 3(永続化) が通れば Phase 1 へ。4 が NG の場合は
「再起動後は手動で再構築(tmux+resurrect相当は無い)」という制約をユーザーに報告してから進む。

### Phase 1: config.toml の nix 管理化

**新規ファイル `modules/shell/herdr.nix`**(下記そのまま使用可。コメント含め維持すること):

```nix
{ ... }:
{
  # herdr (AIエージェント向けターミナルワークスペース) の設定。
  # パッケージ本体は modules/core/packages.nix (nixpkgs管理)。
  # 設定リファレンス: https://herdr.dev/docs/configuration/
  # 変更後は `herdr server reload-config` で稼働中サーバに反映できる。
  xdg.configFile."herdr/config.toml".text = ''
    # 初回オンボーディングはスキップ(設定はこのファイルで宣言管理する)
    onboarding = false

    [update]
    # Nix 管理のため self-update (`herdr update`) は使わない(nix store は read-only)。
    # 更新は nixpkgs 経由。バージョン通知だけ切る。エージェント検知マニフェストの更新は有効のまま。
    version_check = false
    manifest_check = true

    [session]
    # 復元時に Claude Code 等をネイティブ会話セッションごと再開する(デフォルトtrueだが明示)
    resume_agents_on_restore = true

    [ui]
    # tmux の window-style(非アクティブ暗色)の代替はテーマに委ねる。
    # サイドバー(エージェント状態一覧)は attention 優先で並べる。
    agent_panel_sort = "priority"

    [keys]
    # prefix は tmux と同じ ctrl+b (デフォルトのまま明示)
    prefix = "ctrl+b"
    # タブ移動: tmux の prefix+j/k (前/次ウィンドウ) の手癖を移植。
    # デフォルトの prefix+j/k は focus_pane_down/up なので矢印キーへ退避する。
    next_tab = ["prefix+n", "prefix+j"]
    previous_tab = ["prefix+p", "prefix+k"]
    focus_pane_down = ["prefix+down"]
    focus_pane_up = ["prefix+up"]
    # ペイン左右移動はデフォルト(prefix+h / prefix+l)のまま
  '';
}
```

**編集 `modules/shell/default.nix`**: imports に `./herdr.nix` を追加(tmux.nix は残す)。

⚠️注意(未確認事項): `[keys]` で配列構文・`prefix+down` が 0.7.1 で受理されるかは docs 由来で実機未確認。
適用後に `herdr server reload-config` を実行し、herdr のログ(`~/.config/herdr/herdr-server.log`)に
設定警告が出ていないか確認すること。警告が出た場合は j/k 割当をコメントアウトして
デフォルトキーで進める(キー配置は Phase 3 後にでも調整できる。ここで止まらない)。

検証: `nixpkgs-fmt` → `nix eval .#homeConfigurations.work.activationPackage.drvPath` →
`home-manager switch --flake .#work` → `herdr server reload-config` → 上記ログ確認。

コミット: `feat(herdr): config.toml を追加し Nix 管理化`

### Phase 2: ワークフロー移行

#### 2-a. workspace 自動命名ヘルパー `hws` (tmuxNameSession の代替)

`dotfiles/zshrc` の `cd-nav` 定義の後ろに追加:

```zsh
# herdr: カレントディレクトリの workspace を repo@branch ラベルで作成してフォーカスする。
# modules/shell/tmux.nix の tmuxNameSession と同じ命名規則:
# - git リポジトリ: メイン worktree の basename @ ブランチ末尾要素 (gwq worktree の +branch 重複を回避)
# - git 管理外: ディレクトリ basename
function hws() {
  local label main_wt repo b
  main_wt=$(git worktree list 2>/dev/null | head -1 | awk '{print $1}')
  if [ -n "$main_wt" ]; then
    repo=$(basename "$main_wt")
    b=$(git branch --show-current 2>/dev/null)
    if [ -n "$b" ]; then
      label="$repo@${b##*/}"
    else
      label="$repo"
    fi
  else
    label=$(basename "$PWD")
  fi
  herdr workspace create --cwd "$PWD" --label "$label" --focus
}
```

検証: `zsh -n dotfiles/zshrc`。適用後、リポジトリ内で `hws` → herdr に `repo@branch` workspace ができること。
コミット: `feat(zsh): herdr workspace を repo@branch で作る hws ヘルパーを追加`

#### 2-b. Claude 状態フックの削除

herdr はフック無しで Claude を検知する(§1 確認済み)ため、tmux 用の状態スタンプ機構を落とす。

1. `dotfiles/claude/settings.json` を編集。**§2.3 の削除対象/残留対象リストに厳密に従うこと**。
   削除後に `jq empty dotfiles/claude/settings.json` で妥当性確認。
   さらに `jq '.hooks | keys' dotfiles/claude/settings.json` の結果が `["PreToolUse"]` のみになること、
   `jq '.hooks.PreToolUse | length' ` が `2`(find-exec ガードと cd+リダイレクトガード)であることを確認。
2. `modules/core/claude.nix` から `home.file.".claude/hooks/tmux-state.sh"` ブロックを削除。
3. `dotfiles/claude/hooks/tmux-state.sh` を `git rm`。
4. ⚠️ `~/.claude/settings.json` は claude.nix の activation で **base が hooks キーごと上書き**する仕組みなので、
   switch 後に実ファイルからも消えることを `jq '.hooks | keys' ~/.claude/settings.json` で確認。

**`herdr integration install claude` は実行しないこと。**
理由: どのファイルに何を書くか公式に明記がなく、`~/.claude/settings.json` に書く場合、
このリポジトリの activation(jq マージで base の hooks が毎回勝つ)により **switch のたびに消えて**
中途半端な状態になる。ネイティブ検知で足りるのでまず不要。
(将来入れたくなったら: 実行→ `git diff`/実ファイル diff で書き込み内容を特定→
 `dotfiles/claude/settings.json` に手で移植、という手順を踏むこと。)

コミット: `refactor(claude): tmux向け状態スタンプhookを削除(herdrネイティブ検知に移行)`

#### 2-c. kube コンテキスト表示の代替 (🙋要ユーザー確認)

kube-tmux(status-right)の代替候補を提示して選んでもらう:

- **案A**: starship の kubernetes モジュールを有効化(`modules/shell/starship.nix`)。
  プロンプト表示なので常時見えるが行が長くなる。
- **案B**: 表示を捨てる(`kubie info`/`kubectl config current-context` を都度叩く運用)。
- 案C: herdr のカスタムコマンドキー(`[[keys.command]]` type="pane" で `kubectl config current-context`)。

選択された案のみ実装。コミットは独立で。

### Phase 3: tmux 完全撤去 (🙋要ユーザー確認: herdr 数日運用の合格判定後)

1. `modules/shell/default.nix` から `./tmux.nix` を削除。
2. `modules/shell/tmux.nix` を `git rm`。
3. `dotfiles/tmux.conf` を `git rm`。
4. `overlays/default.nix` から `kube-tmux` derivation を削除
   (事前に `grep -rn "kube-tmux" --include="*.nix" .` で参照が tmux.nix のみだったことを確認)。
5. `modules/editors/nvim/plugins.nix` の `plugins.tmux-navigator`(169行付近)を削除。
   nvim の `C-hjkl` split移動が失われるので、代替の素のキーマップを `keymaps.nix` に追加:
   ```nix
   # tmux-navigator 撤去後の nvim 内 split 移動 (C-hjkl)
   { mode = "n"; key = "<C-h>"; action = "<C-w>h"; }
   { mode = "n"; key = "<C-j>"; action = "<C-w>j"; }
   { mode = "n"; key = "<C-k>"; action = "<C-w>k"; }
   { mode = "n"; key = "<C-l>"; action = "<C-w>l"; }
   ```
6. 残骸確認: `grep -rniE "tmux" modules/ dotfiles/ overlays/ home.nix flake.nix` を実行し、
   ヒットが「意図して残すもの」(例: 過去の progress.md 記述)だけであること。
   `~/.tmux/resurrect/` のバックアップファイルは**消さない**(ユーザーの保険。言及だけしておく)。
7. 検証: eval → switch → 新ターミナルで herdr 起動・主要動線(分割/タブ/デタッチ/Claude状態/hws)を一通り。
8. コミット(分割推奨):
   - `refactor(tmux)!: tmux 設定一式を削除(herdr へ移行完了)`
   - `refactor(nvim): tmux-navigator を素の C-hjkl キーマップに置換`

---

## 6. 未確認事項まとめ(実行者が Phase 0/1 で潰す)

| # | 事項 | 確認方法 |
|---|---|---|
| 1 | サーバ再起動/マシン再起動後のワークスペース・エージェント復元範囲 | Phase 0-4 |
| 2 | `[keys]` の配列構文・`prefix+down` の受理(docs記載だが0.7.1実機未確認) | Phase 1 のログ確認 |
| 3 | copy mode で `y` 後にモードに留まるか(tmuxのEnter2段階相当) | Phase 0-5 |
| 4 | SSH 越しのクリップボード(OSC52相当) | リモート利用時に確認(通常利用では影響なし) |
| 5 | tab の自動リネーム有無(tmux automatic-rename相当) | Phase 0 で観察。無ければ `prompt_new_tab_name`(デフォルトtrue)運用 |
| 6 | herdr 内の `$TERM` と nvim/zsh の表示互換 | Phase 0-6 |

---

## 7. ロールバック

- Phase 1-2 まで: tmux は無傷なので、単に tmux を使い続ければよい。
  Claude 状態フックを戻すには 2-b のコミットを `git revert` して switch。
- Phase 3 後: 該当コミットを `git revert` して switch(tmux.conf/tmux.nix/kube-tmux が復活する)。
  resurrect のデータは `~/.tmux/resurrect/` に残っているため、tmux 復帰後 `prefix+C-r` で復元可能。

---

## 8. 参考リンク

- https://herdr.dev/docs/configuration/ (config.toml 全リファレンス)
- https://herdr.dev/docs/keyboard/ (キーバインド/prefix-free)
- https://herdr.dev/docs/agents/ (状態検知の仕組み)
- https://herdr.dev/docs/persistence-remote/ (named sessions / remote)
- `herdr --default-config` (実機の全デフォルト設定。**編集前に必ず一度出力して読むこと**)
