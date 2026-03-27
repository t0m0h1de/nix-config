-- plugins/completion.lua - 補完設定
-- nvim-cmp: 補完エンジン本体
-- 各 cmp-xxx: 補完ソース (LSP, バッファ, パス, スニペット)
-- LuaSnip: スニペットエンジン (nvim-cmpが内部で必要とする)

return {
  -- ============================================================
  -- LuaSnip - スニペットエンジン
  -- nvim-cmpがスニペット展開に使用する
  -- ============================================================
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    build = "make install_jsregexp",  -- 正規表現対応 (任意)
    opts = {
      history = true,           -- ジャンプ後もスニペットを記憶
      delete_check_events = "TextChanged",
    },
  },

  -- ============================================================
  -- nvim-cmp - 補完エンジン本体
  -- ============================================================
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",  -- LuaSnip → cmp ブリッジ
      "hrsh7th/cmp-nvim-lsp",      -- LSP補完ソース
      "hrsh7th/cmp-buffer",         -- バッファ内の単語
      "hrsh7th/cmp-path",           -- ファイルパス補完
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        -- スニペットエンジンの指定 (必須)
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        -- 補完ウィンドウの見た目
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },

        -- キーマップ
        mapping = cmp.mapping.preset.insert({
          -- 候補の上下移動
          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),

          -- ドキュメントのスクロール
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),

          -- 補完を手動トリガー / キャンセル
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),

          -- 確定: Enterで確定 (候補未選択時はそのままEnter)
          ["<CR>"] = cmp.mapping.confirm({ select = false }),

          -- Tab: 次の候補 / スニペットの次のフィールドへ
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),

          -- Shift+Tab: 前の候補 / スニペットの前のフィールドへ
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),

        -- 補完ソースの優先順位 (上が高優先)
        sources = cmp.config.sources({
          { name = "nvim_lsp" },  -- LSP (最優先)
          { name = "luasnip" },   -- スニペット
          { name = "path" },      -- ファイルパス
        }, {
          { name = "buffer", keyword_length = 3 },  -- バッファ (3文字以上で発動)
        }),

        -- 補完候補のフォーマット (種類アイコン付き)
        formatting = {
          format = function(entry, item)
            -- ソース名を短縮表示
            local source_names = {
              nvim_lsp = "[LSP]",
              luasnip  = "[Snip]",
              buffer   = "[Buf]",
              path     = "[Path]",
            }
            item.menu = source_names[entry.source.name] or entry.source.name
            return item
          end,
        },
      })
    end,
  },
}
