-- ==============================================================
-- config/lazy.lua - lazy.nvim bootstrap & プラグイン読み込み
-- ==============================================================
-- lazy.nvimが未インストールの場合は自動的にクローンする

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- vim.uv
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath,
  })
  -- clone失敗時はエラーを表示して終了
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

-- ==============================================================
-- lazy.nvim セットアップ
-- plugins/ 配下の *.lua を自動的に読み込む
-- 新しいプラグインは lua/plugins/ 以下にファイルを追加するだけでOK
-- ==============================================================
require("lazy").setup({
  spec = {
    { import = "plugins" },       -- lua/plugins/*.lua を自動読み込み
    { import = "plugins.lang" },  -- lua/plugins/lang/*.lua を自動読み込み
  },
  defaults = {
    lazy = true,   -- デフォルトはlazy load
  },
  install = {
    colorscheme = { "habamax" },  -- インストール中のフォールバックカラースキーム
  },
  checker = {
    enabled = true,   -- プラグイン更新を自動チェック
    notify  = true,  -- 通知は出さない
  },
  performance = {
    rtp = {
      -- 不要なデフォルトプラグインを無効化
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
