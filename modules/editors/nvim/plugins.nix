{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      nvim-window-picker
    ];

    plugins.treesitter = {
      # AST ベースのハイライトとインデントを有効化。
      enable = true;
      # デバッグしやすくするため起動時ロードを強制する。
      autoLoad = true;
      lazyLoad.enable = false;
      # Nix 管理で parser を固定するため、全 Grammar を導入する。
      # 特定の言語だけ入れる場合は grammarPackages = with ...builtGrammars; [ ... ] を使う。
      grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
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

    plugins.nvim-tree = {
      # サイドバー型ファイルエクスプローラーを有効化。
      enable = true;
      settings = {
        git.enable = true;
        renderer = {
          group_empty = true;
          highlight_git = "icon";
          icons.show.git = true;
        };
        view = {
          width = 30;
          side = "left";
        };
        actions.open_file.window_picker = {
          enable = true;
          picker.__raw = "function() return require('window-picker').pick_window() end";
        };
      };
    };

    plugins.snacks = {
      # snacks.nvim を最小構成で有効化し、段階的移行の検証基盤を作る。
      enable = true;
      settings = {
        bigfile.enabled = true;
        indent.enabled = true;
        notifier.enabled = true;
        quickfile.enabled = true;
        statuscolumn.enabled = true;
        words.enabled = true;
      };
    };

    plugins.vimade = {
      # 非アクティブウィンドウを薄く表示して、フォーカス中のペインを見分けやすくする。
      enable = true;
      settings = {
        fadelevel = 0.7;
        ncmode = "windows";
      };
    };

    plugins.tmux-navigator = {
      # tmux と Neovim 間を Ctrl-hjkl でシームレス移動。
      enable = true;
    };

    plugins.gitsigns = {
      # 行単位のGit差分表示とhunk操作を有効化。
      enable = true;
      settings = {
        # カーソル行の右端に「誰が・いつ・何を」コミットしたかをインライン表示する。
        current_line_blame = true;
        current_line_blame_opts = {
          virt_text = true;
          virt_text_pos = "eol"; # 行末に表示
          delay = 300;
        };
        current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>";
      };
    };

    plugins.diffview = {
      # ファイル差分ビューを有効化。
      enable = true;
    };

    extraConfigLua = ''
      -- nvim-window-picker: ウィンドウ選択UIの初期化（nvim-tree と連携）。
      require("window-picker").setup({
        hint = "floating-big-letter",
        filter_rules = {
          include_current_win = false,
          autoselect_one = true,
          bo = {
            filetype = { "nvim-tree", "NvimTree", "qf", "notify" },
            buftype = { "terminal", "quickfix" },
          },
        },
      })
    '';
  };
}
