{ pkgs, ... }:
{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    # 見た目は一旦 tokyonight に寄せる。
    colorschemes.tokyonight.enable = true;
    colorscheme = "tokyonight";

    # Leader は今後の拡張余地のためにだけ先に固定しておく。
    globals.mapleader = " ";
    globals.maplocalleader = " ";

    plugins.treesitter = {
      # AST ベースのハイライトとインデントを有効化。
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
      };
    };

    plugins.lualine = {
      # ステータスラインを導入。見た目は tokyonight に合わせる。
      enable = true;
      settings = {
        options = {
          theme = "tokyonight";
          globalstatus = true;
        };
      };
    };

    plugins.which-key = {
      # leader キー候補の表示を有効化。
      enable = true;
    };

    plugins.web-devicons = {
      # telescope が参照するアイコン表示を明示的に有効化（auto-enable廃止対応）。
      enable = true;
    };

    plugins.telescope = {
      # ファイル/文字列検索の UI と、file-browser 拡張を有効化。
      enable = true;
      extensions = {
        file-browser = {
          enable = true;
        };
      };
    };

    plugins.tmux-navigator = {
      # tmux と Neovim 間を Ctrl-hjkl でシームレス移動。
      enable = true;
    };

    plugins.gitsigns = {
      # 行単位のGit差分表示とhunk操作を有効化。
      enable = true;
    };

    plugins.diffview = {
      # ファイル差分ビューを有効化。
      enable = true;
    };

    plugins.cmp = {
      # 補完UIを有効化。ソースは cmp-* プラグインを明示的に有効化する。
      enable = true;
      autoEnableSources = true;
      settings = {
        completion = {
          completeopt = "menu,menuone,noinsert";
        };
        mapping = {
          "<C-n>" = "cmp.mapping.select_next_item()";
          "<C-p>" = "cmp.mapping.select_prev_item()";
          "<C-Space>" = "cmp.mapping.complete()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
        };
        sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
      };
    };

    plugins.lsp = {
      # LSP を有効化。まずは Python (pyright) から導入する。
      enable = true;
      servers = {
        pyright = {
          enable = true;
          package = pkgs.pyright;
          extraOptions = {
            capabilities = {
              __raw = ''require("cmp_nvim_lsp").default_capabilities()'';
            };
          };
        };
      };
    };

    extraConfigLua = ''
      -- OSC 52 を使うべき環境を判定する。
      -- 1) SSH セッション
      -- 2) WSL 環境
      -- 3) ローカル clipboard provider が見つからない環境
      local has_local_clipboard_tool =
        vim.fn.executable("pbcopy") == 1
        or vim.fn.executable("wl-copy") == 1
        or vim.fn.executable("xclip") == 1
        or vim.fn.executable("xsel") == 1
        or vim.fn.executable("win32yank.exe") == 1
        or vim.fn.executable("clip.exe") == 1

      local is_ssh = vim.env.SSH_TTY ~= nil
      local is_wsl = vim.env.WSL_INTEROP ~= nil or vim.env.WSL_DISTRO_NAME ~= nil

      -- tmux の set-clipboard と合わせて、必要な環境では OSC 52 を使う。
      if is_ssh or is_wsl or not has_local_clipboard_tool then
        vim.g.clipboard = "osc52"
      end

      -- LSP がアタッチされたバッファだけで基本キーマップを有効化。
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local opts = { buffer = event.buf, silent = true }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        end,
      })
    '';

    opts = {
      # 普段の編集で欲しい最低限の見た目。
      number = true;
      relativenumber = true;
      signcolumn = "yes";  # 行番号の左側に、LSPの警告やGitの変更印を出す隙間を常に確保
      wrap = true;
      scrolloff = 8;  # カーソル移動時、画面の上下に常に8行確保
      termguicolors = true;  # 24bit フルカラーを有効

      # インデントは 2 スペースに統一。
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      smartindent = true;

      # 検索は普段は大文字小文字を無視しつつ、大文字を含めたら厳密一致。
      ignorecase = true;
      smartcase = true;
      hlsearch = false;

      # 余計な一時ファイルは作らず、undo だけは残す。
      swapfile = false;
      backup = false;
      undofile = true;

      # 使い勝手のための小さな調整。
      splitright = true;
      splitbelow = true;
      mouse = "a";
      clipboard = "unnamedplus";
      timeoutlen = 800;
      updatetime = 200;
    };

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
        # gitsigns: 次のhunkへ移動。
        mode = "n";
        key = "]h";
        action = "<cmd>Gitsigns next_hunk<cr>";
      }
      {
        # gitsigns: 前のhunkへ移動。
        mode = "n";
        key = "[h";
        action = "<cmd>Gitsigns prev_hunk<cr>";
      }
      {
        # gitsigns: 現在hunkの差分プレビュー。
        mode = "n";
        key = "<leader>hp";
        action = "<cmd>Gitsigns preview_hunk<cr>";
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
        # Visual mode でインデント後も選択を維持。
        mode = "v";
        key = "<";
        action = "<gv>";
      }
      {
        # Visual mode でインデント後も選択を維持。
        mode = "v";
        key = ">";
        action = ">gv";
      }
      {
        # Terminal buffer から素早く normal mode に戻る。
        mode = "t";
        key = "<Esc><Esc>";
        action = "<C-\\><C-n>";
      }
    ];
  };
}
