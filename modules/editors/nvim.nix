{ pkgs, ... }:
{
  xdg.configFile."nvim/queries/scala/indents.scm".text = ''
    ; scala は upstream の nvim-treesitter query に indents.scm が無いため、
    ; 最低限のノードベースインデントをローカル override で提供する。
    [
      (template_body)
      (block)
    ] @indent.begin

    [
      "}"
      ")"
      "]"
    ] @indent.branch

    [
      "}"
      ")"
      "]"
    ] @indent.end
  '';

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
      # デバッグしやすくするため起動時ロードを強制する。
      autoLoad = true;
      lazyLoad.enable = false;
      # Nix 管理で parser を固定するため、全 Grammar を導入する。
      grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
      # 特定の言語だけ入れる場合は以下を使用する
      # grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      #   bash
      #   json
      #   lua
      #   make
      #   markdown
      #   nix
      #   regex
      #   scala
      #   toml
      #   vim
      #   vimdoc
      #   xml
      #   yaml
      # ];
      settings = {
        highlight.enable = true;
        indent = {
          enable = true;
        };
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
        sections = {
          lualine_c = [
            {
              __unkeyed-1 = "filename";
              file_status = true;
              newfile_status = true;
              path = 1;
              symbols = {
                modified = " ●";
                readonly = "[RO]";
                unnamed = "[No Name]";
                newfile = "[New]";
              };
            }
          ];
        };
      };
    };

    plugins.auto-save = {
      # フォーカスロスト時に、通常ファイルだけ自動保存する。
      enable = true;
      settings = {
        enabled = true;
        trigger_events = {
          immediate_save = [ "FocusLost" ];
          defer_save = [ ];
          cancel_deferred_save = [ ];
        };
        condition = ''
          function(buf)
            if vim.api.nvim_buf_get_name(buf) == "" then
              return false
            end
            if vim.bo[buf].buftype ~= "" then
              return false
            end
            if not vim.bo[buf].modifiable or vim.bo[buf].readonly then
              return false
            end
            return true
          end
        '';
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
          settings = {
            # file_browser で隠しファイルと gitignore 対象も表示する。
            hidden = {
              file_browser = true;
              folder_browser = true;
            };
            no_ignore = true;
            respect_gitignore = false;
          };
        };
      };
    };

    plugins.oil = {
      # Neovim 内でディレクトリを編集できるファイルブラウザを有効化。
      enable = true;
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
        # 最初の候補を事前選択しない。最初の Tab で 1 件目を選択する。
        preselect = "cmp.PreselectMode.None";
        completion = {
          # 先頭候補の自動選択を防ぎ、最初の Tab で1件目を選べるようにする。
          completeopt = "menu,menuone,noselect";
        };
        mapping = {
          # Tab で次候補、Shift-Tab で前候補。連打で候補送りする。
          "<Tab>" = "cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert })";
          "<S-Tab>" = "cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert })";
          "<C-Space>" = "cmp.mapping.complete()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
        };
        sources = [
          { name = "copilot"; }
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
      };
    };

    plugins.copilot-lua = {
      # GitHub Copilot を有効化（nvim-cmp と干渉しやすいUIは無効化）。
      enable = true;
      settings = {
        panel.enabled = false;
        suggestion.enabled = false;
      };
    };

    plugins.copilot-cmp = {
      # Copilot の候補を nvim-cmp の source として統合する。
      enable = true;
    };

    plugins."nvim-autopairs" = {
      # 開き括弧やクオート入力時に、自動で閉じ文字も補完する。
      enable = true;
      settings = {
        check_ts = true;
        map_cr = false;
      };
    };

    plugins.lsp = {
      # LSP を有効化。Python / Web / Scala の基本言語を導入する。
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
        html = {
          enable = true;
          extraOptions = {
            capabilities = {
              __raw = ''require("cmp_nvim_lsp").default_capabilities()'';
            };
          };
        };
        cssls = {
          enable = true;
          extraOptions = {
            capabilities = {
              __raw = ''require("cmp_nvim_lsp").default_capabilities()'';
            };
          };
        };
        ts_ls = {
          # TypeScript / JavaScript / React (jsx, tsx) を 1 つのサーバーで扱う。
          enable = true;
          filetypes = [
            "javascript"
            "javascriptreact"
            "typescript"
            "typescriptreact"
          ];
          extraOptions = {
            capabilities = {
              __raw = ''require("cmp_nvim_lsp").default_capabilities()'';
            };
          };
        };
        metals = {
          enable = true;
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

      -- 画面分割の境界線を見やすくする。
      vim.opt.fillchars = {
        vert = "│",
        horiz = "─",
        horizup = "┴",
        horizdown = "┬",
        vertleft = "┤",
        vertright = "├",
        verthoriz = "┼",
      }
      vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#7aa2f7", bold = true })

      -- LSP がアタッチされたバッファだけで基本キーマップを有効化。
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local opts = { buffer = event.buf, silent = true }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        end,
      })

      -- Scala で "case" / "=>" 入力時の自動再インデントを抑制する。
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "scala",
        callback = function()
          vim.cmd("setlocal indentkeys-==case")
          vim.cmd("setlocal indentkeys-=<>>")
        end,
      })

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

    opts = {
      # 普段の編集で欲しい最低限の見た目。
      number = true;
      relativenumber = true;
      signcolumn = "yes"; # 行番号の左側に、LSPの警告やGitの変更印を出す隙間を常に確保
      wrap = true;
      scrolloff = 8; # カーソル移動時、画面の上下に常に8行確保
      termguicolors = true; # 24bit フルカラーを有効

      # インデントは 2 スペースに統一。
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      autoindent = true;
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
        # oil.nvim で現在ファイルのディレクトリを開く。
        mode = "n";
        key = "<leader>fo";
        action = "<cmd>Oil --float %:p:h<cr>";
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
        action = "<cmd>lua vim.diagnostic.goto_next()<cr>";
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
        action = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
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
  };
}
