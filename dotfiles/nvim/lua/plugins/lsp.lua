-- plugins/lsp.lua - LSP設定
-- mason.nvim     : LSPサーバー/linter/formatterのパッケージマネージャー
-- mason-lspconfig: masonでインストールするサーバーの管理
-- nvim-lspconfig : LSPサーバーのconfig定義を提供 (lsp/配下のファイル群)
--
-- Note: org移転 williamboman → mason-org (2024)
-- Note: require('lspconfig').xxx.setup{} は Nvim 0.11+ で deprecated
--       → vim.lsp.config() + vim.lsp.enable() を使う

return {
  -- ============================================================
  -- mason.nvim - LSPサーバー等のパッケージ管理
  -- :Mason でUI表示、:MasonInstall <server> でインストール
  -- ============================================================
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ui = {
        icons = {
          package_installed   = "✓",
          package_pending     = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },

  -- ============================================================
  -- mason-lspconfig.nvim - masonでのサーバーインストール管理
  -- ensure_installed に書いたサーバーを自動インストールする
  -- ============================================================
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      -- 常にインストールされているべきLSPサーバー
      ensure_installed = { "lua_ls", "rust_analyzer" },
      automatic_installation = true,
    },
  },

  -- ============================================================
  -- nvim-lspconfig - LSPサーバーのconfig定義を提供
  -- lsp/配下のファイルが vim.lsp.config により自動認識される
  -- ============================================================
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",  -- LSPのcapabilitiesをcmp用に拡張
    },
    config = function()
      -- cmp-nvim-lsp の capabilities をマージ (LSPにスニペット補完等を伝える)
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities()
      )
      vim.lsp.config("*", { capabilities = capabilities })

      -- ----------------------------------------------------------
      -- LSPアタッチ時のキーマップ設定 (新APIでも変わらず有効)
      -- ----------------------------------------------------------
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspAttachKeymaps", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          -- 定義/参照への移動
          map("gd", vim.lsp.buf.definition,      "定義へジャンプ")
          map("gD", vim.lsp.buf.declaration,     "宣言へジャンプ")
          map("gi", vim.lsp.buf.implementation,  "実装へジャンプ")
          map("gr", vim.lsp.buf.references,      "参照一覧")
          map("gt", vim.lsp.buf.type_definition, "型定義へジャンプ")

          -- ドキュメント
          map("K",     vim.lsp.buf.hover,          "ホバードキュメント")
          map("<C-k>", vim.lsp.buf.signature_help, "シグネチャヘルプ")

          -- 編集操作
          map("<leader>rn", vim.lsp.buf.rename,      "リネーム")
          map("<leader>ca", vim.lsp.buf.code_action, "コードアクション")
          map("<leader>cf", vim.lsp.buf.format,      "フォーマット")

          -- 診断
          map("<leader>e",  vim.diagnostic.open_float, "診断詳細を表示")
          map("[d",         vim.diagnostic.goto_prev,  "前の診断へ")
          map("]d",         vim.diagnostic.goto_next,  "次の診断へ")
          map("<leader>dl", vim.diagnostic.setloclist, "診断リスト")
        end,
      })

      -- ----------------------------------------------------------
      -- 診断アイコンの設定
      -- ----------------------------------------------------------
      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "✘",
            [vim.diagnostic.severity.WARN]  = "▲",
            [vim.diagnostic.severity.HINT]  = "⚑",
            [vim.diagnostic.severity.INFO]  = "»",
          },
        },
        virtual_text     = true,
        update_in_insert = false,
        float = {
          border = "rounded",
          source = true,
        },
      })

      -- ----------------------------------------------------------
      -- サーバーの有効化 (Nvim 0.11+ の新API)
      -- require('lspconfig').xxx.setup{} は deprecated なので使わない
      -- ----------------------------------------------------------
      vim.lsp.enable({ "lua_ls", "rust_analyzer" })

      -- ----------------------------------------------------------
      -- サーバー個別の設定 (vim.lsp.config でカスタマイズ)
      -- ----------------------------------------------------------

      -- lua_ls: Neovim設定ファイル向けにruntime/workspaceを設定
      -- (configs.md記載の推奨設定)
      vim.lsp.config("lua_ls", {
        on_init = function(client)
          -- .luarc.jsonがあるプロジェクトはそちらの設定を優先
          if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if path ~= vim.fn.stdpath("config")
              and (vim.uv.fs_stat(path .. "/.luarc.json")
                or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
            then
              return
            end
          end
          client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
            runtime = {
              version = "LuaJIT",
              path = { "lua/?.lua", "lua/?/init.lua" },
            },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
          })
        end,
        settings = { Lua = {} },
      })

      -- rust_analyzer: 設定例 (必要に応じてコメントアウトを解除)
      -- vim.lsp.config("rust_analyzer", {
      --   settings = {
      --     ["rust-analyzer"] = {
      --       diagnostics = { enable = true },
      --     },
      --   },
      -- })
    end,
  },
}
