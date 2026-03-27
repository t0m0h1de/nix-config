# Neovim 設定ガイド

lazy.nvimによるプラグイン管理を採用したNeovim設定。初回起動時にlazy.nvimと各プラグインが自動インストールされる。

## ディレクトリ構成

```
dotfiles/nvim/
├── init.lua                  # エントリーポイント
└── lua/
    ├── config/
    │   ├── options.lua       # vim.opt設定
    │   ├── keymaps.lua       # キーマップ (leader = Space)
    │   ├── autocmds.lua      # autocmd
    │   └── lazy.lua          # lazy.nvim bootstrap
    └── plugins/
        ├── navigation.lua    # vim-tmux-navigator
        ├── lsp.lua           # mason + lspconfig
        ├── completion.lua    # nvim-cmp + LuaSnip
        ├── treesitter.lua    # nvim-treesitter
        ├── filetree.lua      # neo-tree
        └── lang/             # 言語別設定 (nvim-java等)
```

## 起動・更新

```bash
# 通常起動 (初回は自動インストールが走る)
nvim

# プラグインの更新
:Lazy update

# プラグイン状態の確認
:Lazy

# LSPの状態確認
:checkhealth vim.lsp
```

---

## プラグイン別使い方

### leader キー

すべての `<leader>` は **Space キー**。

---

### vim-tmux-navigator — ウィンドウ/ペイン移動

vim splits と tmux panes を同じキーでシームレスに移動できる。

| キー | 動作 |
|---|---|
| `Ctrl+h` | 左のウィンドウ/tmuxペインへ |
| `Ctrl+j` | 下のウィンドウ/tmuxペインへ |
| `Ctrl+k` | 上のウィンドウ/tmuxペインへ |
| `Ctrl+l` | 右のウィンドウ/tmuxペインへ |
| `Ctrl+\` | 直前のウィンドウ/tmuxペインへ |

---

### neo-tree — ファイルツリー

| キー | 動作 |
|---|---|
| `<leader>e` | ファイルツリーを開閉 |
| `<leader>E` | 現在のファイルをツリーで表示 |
| `<leader>ge` | Git状態ツリーを表示 |
| `<leader>be` | バッファ一覧を表示 |

#### ツリー内のキー操作

| キー | 動作 |
|---|---|
| `<Enter>` | ファイルを開く |
| `s` | 縦分割で開く |
| `S` | 横分割で開く |
| `t` | タブで開く |
| `a` | ファイルを追加 |
| `A` | ディレクトリを追加 |
| `r` | リネーム |
| `d` | 削除 |
| `y` / `x` / `p` | コピー / カット / ペースト |
| `H` | 隠しファイル (dotfile) 表示を切替 |
| `/` | ツリー内をfuzzy検索 |
| `<Backspace>` | 親ディレクトリへ移動 |
| `.` | 現在ディレクトリをルートに変更 |
| `?` | ヘルプを表示 |
| `q` | ツリーを閉じる |

---

### mason.nvim — LSPサーバー管理

LSPサーバー・linter・formatterのパッケージマネージャー。

```
:Mason              → インストールUIを開く
:MasonInstall <name>  → サーバーを直接インストール
:MasonUpdate        → registryを更新
```

#### よく使うサーバー名

| 言語 | サーバー名 |
|---|---|
| Lua | `lua_ls` |
| Rust | `rust_analyzer` |
| Java | `jdtls` |
| TypeScript/JavaScript | `ts_ls` |
| Python | `pyright` |

常時インストールしたいサーバーは `plugins/lsp.lua` の `ensure_installed` に追記する。

---

### LSP — コード補助機能

LSPがアタッチされているバッファで以下のキーが使える。

#### 定義・参照への移動

| キー | 動作 |
|---|---|
| `gd` | 定義へジャンプ |
| `gD` | 宣言へジャンプ |
| `gi` | 実装へジャンプ |
| `gr` | 参照一覧を表示 |
| `gt` | 型定義へジャンプ |
| `Ctrl+o` | ジャンプ前の位置に戻る (Neovim標準) |

#### ドキュメント・情報

| キー | 動作 |
|---|---|
| `K` | カーソル下のホバードキュメントを表示 |
| `Ctrl+k` | 関数のシグネチャ (引数の型) を表示 |

#### コード操作

| キー | 動作 |
|---|---|
| `<leader>rn` | シンボルをプロジェクト全体でリネーム |
| `<leader>ca` | コードアクション (importの追加、修正提案等) |
| `<leader>cf` | LSPによるフォーマット |

#### 診断 (エラー・警告)

| キー | 動作 |
|---|---|
| `<leader>e` | カーソル行の診断詳細をポップアップ表示 |
| `[d` | 前の診断へ移動 |
| `]d` | 次の診断へ移動 |
| `<leader>dl` | 全診断をlocation listに表示 |

---

### nvim-cmp — 補完

#### 補完メニューが出ているとき

| キー | 動作 |
|---|---|
| `Ctrl+n` | 次の候補を選択 |
| `Ctrl+p` | 前の候補を選択 |
| `Tab` | 次の候補を選択 / スニペットの次フィールドへ |
| `Shift+Tab` | 前の候補を選択 / スニペットの前フィールドへ |
| `Enter` | 候補を確定 (未選択時はそのままEnter) |
| `Ctrl+e` | 補完メニューを閉じる |
| `Ctrl+Space` | 補完を手動で起動 |
| `Ctrl+b` / `Ctrl+f` | ドキュメントウィンドウをスクロール |

#### 補完ソースの優先順位

1. **[LSP]** — LSPサーバーからの補完 (最優先)
2. **[Snip]** — LuaSnipスニペット
3. **[Path]** — ファイルパス
4. **[Buf]** — バッファ内の単語 (3文字以上で発動)

---

### nvim-treesitter — シンタックスハイライト

インストール済みのパーサーは `ensure_installed` に記載されたもの + `auto_install = true` により不足分が自動追加される。

```
:TSInstallInfo        → インストール済みパーサー一覧
:TSInstall <lang>     → 手動でパーサーを追加
```

#### インクリメンタル選択

コードをASTのノード単位で選択範囲を広げる機能。

| キー | 動作 |
|---|---|
| `Ctrl+Space` | 選択を開始 / ノード単位で拡大 |
| `Ctrl+s` | スコープ単位で拡大 |
| `Alt+Space` | 選択範囲を縮小 |

---

## プラグインの追加方法

`lua/plugins/` 以下に Lua ファイルを追加するだけで自動的に読み込まれる。

```lua
-- lua/plugins/example.lua
return {
  {
    "author/plugin-name",
    event = "VeryLazy",  -- lazy loadのトリガー
    opts = {
      -- setupに渡すオプション
    },
  },
}
```

言語固有のプラグインは `lua/plugins/lang/` 以下に追加する (例: `lang/java.lua`)。

## 新しいLSPサーバーの追加

1. `:Mason` でサーバーをインストールするか、`plugins/lsp.lua` の `ensure_installed` に追記
2. `plugins/lsp.lua` の `vim.lsp.enable({...})` の配列にサーバー名を追加
3. 追加設定が必要な場合は `vim.lsp.config("server_name", {...})` でカスタマイズ
