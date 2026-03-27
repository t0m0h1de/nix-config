-- plugins/filetree.lua - ファイルツリー
-- neo-tree.nvim: ファイルシステム/バッファ/Git状態をサイドバー表示
-- branch = "v3.x" (破壊的変更をしない方針のstableブランチ)

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,  -- neo-tree自身がlazy loadを管理するため false に
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",  -- ファイルアイコン (任意だが推奨)
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>",        desc = "ファイルツリーを開閉" },
      { "<leader>E", "<cmd>Neotree reveal<cr>",         desc = "現在のファイルをツリーで表示" },
      { "<leader>ge", "<cmd>Neotree git_status<cr>",   desc = "Git状態を表示" },
      { "<leader>be", "<cmd>Neotree buffers<cr>",      desc = "バッファ一覧を表示" },
    },
    opts = {
      close_if_last_window = true,  -- ツリーだけ残ったら自動で閉じる
      popup_border_style = "",      -- Nvim 0.11+の 'winborder' を使用
      enable_git_status   = true,
      enable_diagnostics  = true,

      -- ディレクトリを開いたときにnetrwの代わりにneo-treeを使う
      filesystem = {
        hijack_netrw_behavior = "open_default",

        -- 現在のファイルをツリーで自動追従
        follow_current_file = {
          enabled = true,
          leave_dirs_open = false,
        },

        -- OSレベルのファイル監視で自動更新 (手動refreshが不要になる)
        use_libuv_file_watcher = true,

        filtered_items = {
          visible = false,       -- 非表示ファイルは隠す
          hide_dotfiles = false, -- dotfileは表示 (.gitignore等を確認しやすいように)
          hide_gitignored = true,
        },

        window = {
          mappings = {
            ["<bs>"] = "navigate_up",   -- Backspaceで親ディレクトリへ
            ["."]    = "set_root",      -- .でルートを現在ディレクトリに変更
            ["H"]    = "toggle_hidden", -- Hで隠しファイル表示を切替
            ["/"]    = "fuzzy_finder",  -- /でツリー内をファジー検索
          },
        },
      },

      window = {
        position = "left",
        width = 35,
        mappings = {
          ["<cr>"] = "open",
          ["s"]    = "open_vsplit",
          ["S"]    = "open_split",
          ["t"]    = "open_tabnew",
          ["C"]    = "close_node",
          ["z"]    = "close_all_nodes",
          ["a"]    = { "add", config = { show_path = "relative" } },
          ["A"]    = "add_directory",
          ["d"]    = "delete",
          ["r"]    = "rename",
          ["y"]    = "copy_to_clipboard",
          ["x"]    = "cut_to_clipboard",
          ["p"]    = "paste_from_clipboard",
          ["c"]    = "copy",
          ["m"]    = "move",
          ["q"]    = "close_window",
          ["R"]    = "refresh",
          ["?"]    = "show_help",
          ["i"]    = "show_file_details",
        },
      },

      default_component_configs = {
        git_status = {
          symbols = {
            added     = "✚",
            modified  = "",
            deleted   = "✖",
            renamed   = "󰁕",
            untracked = "",
            ignored   = "",
            unstaged  = "󰄱",
            staged    = "",
            conflict  = "",
          },
        },
      },
    },
  },
}
