-- plugins/navigation.lua - ウィンドウ/ペイン移動
-- vim-tmux-navigator: vim splits と tmux panes を Ctrl+hjkl で統一操作

return {
  {
    "christoomey/vim-tmux-navigator",
    -- コマンド実行時 or キー押下時にlazy load
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>",     desc = "左のウィンドウ/ペインへ" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>",     desc = "下のウィンドウ/ペインへ" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>",       desc = "上のウィンドウ/ペインへ" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>",    desc = "右のウィンドウ/ペインへ" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", desc = "直前のウィンドウ/ペインへ" },
    },
  },
}
