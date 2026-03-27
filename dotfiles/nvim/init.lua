-- ==============================================================
-- init.lua - Neovim エントリーポイント
-- ==============================================================
-- 読み込み順:
--   1. config/options   : vim.opt 設定
--   2. config/keymaps   : キーマップ
--   3. config/autocmds  : autocmd
--   4. config/lazy      : lazy.nvim bootstrap & プラグイン読み込み
-- ==============================================================

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
