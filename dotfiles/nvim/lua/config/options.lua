-- ==============================================================
-- config/options.lua - Vim オプション設定
-- ==============================================================

local opt = vim.opt

-- 表示
opt.number         = true   -- 行番号
opt.relativenumber = true   -- 相対行番号
opt.cursorline     = true   -- カーソル行をハイライト
opt.signcolumn     = "yes"  -- 常にsigncolumnを表示（LSP等のアイコン用）
opt.wrap           = true  -- 折り返しなし
opt.scrolloff      = 8      -- カーソル上下のスクロールマージン
opt.termguicolors  = true   -- true color

-- インデント
opt.expandtab   = true  -- タブをスペースに展開
opt.shiftwidth  = 2     -- インデント幅
opt.tabstop     = 2     -- タブ幅
opt.smartindent = true  -- スマートインデント

-- 検索
opt.ignorecase = true   -- 大文字小文字を無視
opt.smartcase  = true   -- 大文字が含まれる場合は区別
opt.hlsearch   = false  -- 検索ハイライトを残さない

-- ファイル
opt.swapfile = false  -- スワップファイルなし
opt.backup   = false  -- バックアップなし
opt.undofile = true   -- undoファイルを永続化

-- 操作感
opt.splitright = true  -- 縦分割は右に
opt.splitbelow = true  -- 横分割は下に
opt.mouse      = "a"   -- マウス有効
opt.clipboard  = "unnamedplus"  -- システムクリップボードと共有 TODO: OSごとのクリップボード設定を調整

-- 補完
opt.completeopt = { "menuone", "noselect" }  -- nvim-cmp向け設定
