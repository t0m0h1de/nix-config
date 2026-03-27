-- ==============================================================
-- config/keymaps.lua - キーマップ設定
-- ==============================================================

-- leaderキーをスペースに設定 (lazy.nvimより前に設定する必要あり)
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- jj でInsertモードを抜ける
map("i", "jj", "<Esc>", { desc = "Insertモードを抜ける" })


-- バッファ操作
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "バッファを閉じる" })
map("n", "[b", "<cmd>bprevious<cr>",       { desc = "前のバッファ" })
map("n", "]b", "<cmd>bnext<cr>",           { desc = "次のバッファ" })

-- ファイル保存
map("n", "<leader>w", "<cmd>write<cr>",  { desc = "保存" })
map("n", "<leader>q", "<cmd>quit<cr>",   { desc = "終了" })

-- インデント後に選択を維持
map("v", "<", "<gv", { desc = "インデントを減らす" })
map("v", ">", ">gv", { desc = "インデントを増やす" })

-- 検索ハイライトをクリア
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "ハイライトをクリア" })

-- ターミナルを抜ける
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "ノーマルモードに戻る" })
