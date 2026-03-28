-- plugins/treesitter.lua - シンタックスハイライト / コード理解
-- nvim-treesitter: ASTベースの正確なシンタックスハイライト
-- テキストオブジェクト・インデント・折りたたみも提供

return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",  -- 更新時にパーサーを自動ビルド
    config = function(_, opts)
      require("nvim-treesitter.config").setup(opts)
    end,
    opts = {
      -- 常にインストールするパーサー
      ensure_installed = {
        "lua", "vim", "vimdoc", "query",  -- Neovim設定用 (必須)
        "rust",
        "java",
        "javascript", "typescript", "tsx",
        "json", "jsonc",
        "yaml", "toml",
        "bash",
        "markdown", "markdown_inline",
      },

      -- 不足しているパーサーを自動インストール
      auto_install = true,

      -- ASTベースのシンタックスハイライト
      highlight = {
        enable = true,
        -- vimの従来のregexpハイライトを無効化 (二重ハイライト防止)
        additional_vim_regex_highlighting = false,
      },

      -- ASTを使ったスマートインデント
      indent = {
        enable = true,
      },

      -- インクリメンタル選択 (ASTノード単位で選択範囲を広げる/縮める)
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection    = "<C-space>",  -- 選択開始
          node_incremental  = "<C-space>",  -- ノード単位で拡大
          scope_incremental = "<C-s>",      -- スコープ単位で拡大
          node_decremental  = "<M-space>",  -- 縮小
        },
      },
    },
  },
}
