{ ... }:
{
  programs.nixvim = {
    keymaps = [
      {
        # Insert mode から手癖で抜けやすくする。
        mode = "i";
        key = "jj";
        action = "<Esc>";
      }
      {
        # 最低限の保存。
        mode = "n";
        key = "<leader>w";
        action = "<cmd>write<cr>";
      }
      {
        # 最低限の終了。
        mode = "n";
        key = "<leader>q";
        action = "<cmd>quit<cr>";
      }
      {
        # 検索ハイライトをすぐ消せるようにする。
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<cr>";
      }
      {
        # ファイル名ベースで検索。
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>Telescope find_files<cr>";
      }
      {
        # ripgrep で全文検索。
        mode = "n";
        key = "<leader>fg";
        action = "<cmd>Telescope live_grep<cr>";
      }
      {
        # 現在ファイルのディレクトリを起点にブラウズ。
        mode = "n";
        key = "<leader>fb";
        action = "<cmd>Telescope file_browser path=%:p:h select_buffer=true<cr>";
      }
      {
        # oil.nvim で現在ファイルのディレクトリを開く。
        mode = "n";
        key = "<leader>fo";
        action = "<cmd>Oil --float %:p:h<cr>";
      }
      {
        # 開いているバッファ一覧を MRU 順で表示して選択する。
        mode = "n";
        key = "<leader>bb";
        action = "<cmd>Telescope buffers sort_mru=true ignore_current_buffer=true<cr>";
      }
      {
        # 最近開いたファイル履歴から選択して開く。
        mode = "n";
        key = "<leader>fr";
        action = "<cmd>Telescope oldfiles cwd_only=true<cr>";
      }
      {
        # gitsigns: 次のhunkへ移動。
        mode = "n";
        key = "]h";
        action = "<cmd>Gitsigns next_hunk<cr>";
      }
      {
        # 次の診断（エラー/警告）へ移動。
        mode = "n";
        key = "]d";
        action = "<cmd>lua vim.diagnostic.jump({ count = 1 })<cr>";
      }
      {
        # gitsigns: 前のhunkへ移動。
        mode = "n";
        key = "[h";
        action = "<cmd>Gitsigns prev_hunk<cr>";
      }
      {
        # 前の診断（エラー/警告）へ移動。
        mode = "n";
        key = "[d";
        action = "<cmd>lua vim.diagnostic.jump({ count = -1 })<cr>";
      }
      {
        # gitsigns: 現在hunkの差分プレビュー。
        mode = "n";
        key = "<leader>hp";
        action = "<cmd>Gitsigns preview_hunk<cr>";
      }
      {
        # カーソル位置の診断詳細をフロート表示。
        mode = "n";
        key = "<leader>e";
        action = "<cmd>lua vim.diagnostic.open_float()<cr>";
      }
      {
        # snacks.nvim の通知履歴を表示する。
        mode = "n";
        key = "<leader>un";
        action = "<cmd>lua Snacks.notifier.show_history()<cr>";
      }
      {
        # 全バッファの診断一覧を Telescope で表示。
        mode = "n";
        key = "<leader>E";
        action = "<cmd>Telescope diagnostics<cr>";
      }
      {
        # nvim-tree: ファイルツリーをトグル。開くとき現在のバッファのファイルにフォーカスする。
        mode = "n";
        key = "<leader>ft";
        action = "<cmd>NvimTreeFindFileToggle<cr>";
        options.desc = "Toggle File Tree (focus current file)";
      }
      {
        # diffview: 差分ビューを開く。
        mode = "n";
        key = "<leader>do";
        action = "<cmd>DiffviewOpen<cr>";
      }
      {
        # diffview: 差分ビューを閉じる。
        mode = "n";
        key = "<leader>dc";
        action = "<cmd>DiffviewClose<cr>";
      }
      {
        # Terminal buffer から素早く normal mode に戻る。
        mode = "t";
        key = "<Esc><Esc>";
        action = "<C-\\><C-n>";
      }
    ];

    extraConfigLua = ''
      -- <leader>H/J/K/L で、カレントウィンドウ基準の方向リサイズを行う。
      -- 例: 5<leader>L で 15 カラム分リサイズ。
      local resize_step = 3
      local function resize_with_direction(direction)
        local amount = resize_step * vim.v.count1
        local current = vim.fn.winnr()

        if direction == "left" then
          if vim.fn.winnr("h") ~= current then
            vim.cmd("vertical resize +" .. amount)
          else
            vim.cmd("vertical resize -" .. amount)
          end
          return
        end

        if direction == "right" then
          if vim.fn.winnr("l") ~= current then
            vim.cmd("vertical resize +" .. amount)
          else
            vim.cmd("vertical resize -" .. amount)
          end
          return
        end

        if direction == "down" then
          if vim.fn.winnr("j") ~= current then
            vim.cmd("resize +" .. amount)
          else
            vim.cmd("resize -" .. amount)
          end
          return
        end

        if direction == "up" then
          if vim.fn.winnr("k") ~= current then
            vim.cmd("resize +" .. amount)
          else
            vim.cmd("resize -" .. amount)
          end
        end
      end

      vim.keymap.set("n", "<leader>H", function()
        resize_with_direction("left")
      end, { silent = true, desc = "Resize Pane Left" })
      vim.keymap.set("n", "<leader>L", function()
        resize_with_direction("right")
      end, { silent = true, desc = "Resize Pane Right" })
      vim.keymap.set("n", "<leader>J", function()
        resize_with_direction("down")
      end, { silent = true, desc = "Resize Pane Down" })
      vim.keymap.set("n", "<leader>K", function()
        resize_with_direction("up")
      end, { silent = true, desc = "Resize Pane Up" })
    '';
  };
}
