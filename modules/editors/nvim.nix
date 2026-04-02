{ ... }:
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
