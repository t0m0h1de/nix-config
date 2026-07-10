{ pkgs, ... }:
{
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      nvim-window-picker
      # hunk.nvim の必須依存(nixvim の plugins.hunk は自動で入れないため明示追加)。
      # 任意依存の web-devicons は plugins.web-devicons で導入済み。
      nui-nvim
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
      settings = {
        view_options = {
          # 隠しファイル(ドットファイル)もデフォルトで表示する。
          # 一時的に隠したい時は oil バッファ内で `g.` でトグルできる。
          show_hidden = true;
        };
      };
    };

    plugins.nvim-tree = {
      # サイドバー型ファイルエクスプローラーを有効化。
      enable = true;
      settings = {
        git.enable = true;
        # 開いているファイルに追従してツリー上で現在ファイルをハイライトする(既定 false)。
        # ctrl-o 等でバッファを切り替えてもフォーカス表示が更新されるようになる。
        # update_root.enable=false: 追従はするが作業ディレクトリ(ルート)は勝手に変えない。
        update_focused_file = {
          enable = true;
          update_root.enable = false;
        };
        filters = {
          # 隠しファイル(ドットファイル)と gitignore 対象もデフォルトで表示する。
          # ツリー内で `H`(dotfiles) / `I`(gitignore) でトグルできる。
          dotfiles = false;
          git_ignored = false;
        };
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
      # tmux ⇄ Neovim の移動用。ただし C-hjkl の既定マッピングは no_mappings で無効化し、
      # vim-herdr-navigation(下の extraConfigLua)に一本化する。
      # (extraConfigLua はプラグインより先に走るため、無効化しないと tmux-navigator が後勝ちで上書きしてしまう)
      # tmux 内フォールバック用に TmuxNavigate* コマンドだけを利用する。
      enable = true;
      settings.no_mappings = 1;
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

    plugins.glow = {
      # ターミナルの glow と同じレンダラで Markdown をフローティングウィンドウにプレビューする。
      # glow バイナリは modules/core/packages.nix で導入済み(nixvim が dependencies.glow で参照)。
      # :Glow で開閉(キーマップは keymaps.nix の <leader>mp)。
      enable = true;
    };

    plugins.markview = {
      # 編集中バッファ内で Markdown をライブ整形表示(見出し/コード塊/表/リンク等)。treesitter 利用。
      # markdown 系 filetype で自動レンダリング。:Markview toggle でトグル(keymaps.nix の <leader>mt)。
      enable = true;
    };

    plugins.hunk = {
      # 差分(hunk)分割エディタ。:DiffEditor で left/right ディレクトリの差分を
      # ファイル/hunk/行単位に選択して部分 diff を作れる。主に jujutsu(jj)や git の
      # diff-editor / difftool として nvim を起動して使う想定(単体では :DiffEditor 待ち)。
      # 依存 nui.nvim は上の extraPlugins で追加済み。setup は既定のまま。
      enable = true;
    };

    extraConfigLua = ''
      -- nvim-tree の git 表示を staging/commit に追従させる。
      -- nvim-tree の filesystem_watchers はワークツリーのファイル変更は拾うが、`git add`(index のみ
      -- 変更)は拾わないため、gitsigns の git-dir 監視イベント(User GitSignsUpdate: staging/commit/
      -- 外部 index 変更で発火)をフックしてツリーを reload する。GitSignsUpdate は編集中にも発火するので
      -- タイマーでデバウンスし、ツリー表示中のみ reload する(reload は非同期で git を再取得する)。
      local nvimtree_git_timer = (vim.uv or vim.loop).new_timer()
      vim.api.nvim_create_autocmd("User", {
        pattern = "GitSignsUpdate",
        callback = function()
          nvimtree_git_timer:stop()
          nvimtree_git_timer:start(250, 0, vim.schedule_wrap(function()
            local ok, tree_api = pcall(require, "nvim-tree.api")
            if ok and tree_api.tree.is_visible() then
              tree_api.tree.reload()
            end
          end))
        end,
      })

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

      -- vim-herdr-navigation (editor側): C-hjkl で Neovim split を移動し、split の端では
      -- herdr(HERDR_PANE_ID があれば pane focus)/tmux(TMUX があれば TmuxNavigate) に
      -- フォールバックしてペイン境界を越える。tmux-navigator の既定マッピングは無効化済み。
      -- 出典: paulbkim-dev/vim-herdr-navigation editor/nvim.lua (rev 53e318c)
      local function herdr_nav(wincmd, dir)
        local prev = vim.api.nvim_get_current_win()
        vim.cmd("wincmd " .. wincmd)
        if vim.api.nvim_get_current_win() ~= prev then
          return
        end
        if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
          local herdr = vim.env.HERDR_BIN_PATH
          if herdr == nil or herdr == "" then
            herdr = "herdr"
          end
          vim.fn.system({ herdr, "pane", "focus", "--direction", dir, "--current" })
        elseif vim.env.TMUX and vim.env.TMUX ~= "" then
          local tmux = { left = "Left", down = "Down", up = "Up", right = "Right" }
          pcall(vim.cmd, "TmuxNavigate" .. tmux[dir])
        end
      end
      local function herdr_map(lhs, wincmd, dir, desc)
        vim.keymap.set("n", lhs, function()
          herdr_nav(wincmd, dir)
        end, { silent = true, noremap = true, desc = desc })
      end
      herdr_map("<C-h>", "h", "left", "Navigate left (vim/herdr)")
      herdr_map("<C-j>", "j", "down", "Navigate down (vim/herdr)")
      herdr_map("<C-k>", "k", "up", "Navigate up (vim/herdr)")
      herdr_map("<C-l>", "l", "right", "Navigate right (vim/herdr)")
    '';
  };
}
