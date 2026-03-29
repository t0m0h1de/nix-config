-- plugins/lang/java.lua - Java開発環境
-- nvim-java: JDTLS ラッパー + テスト/デバッグ/リファクタリング統合
-- setup() は vim.lsp.enable('jdtls') より前に呼ぶ必要がある

return {
  {
    "nvim-java/nvim-java",
    ft = "java",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "mfussenegger/nvim-dap",
      {
        "JavaHello/spring-boot.nvim",
        commit = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0",
      },
    },
    config = function()
      require("java").setup({
        jdk = {
          -- NixでZulu JDKが入っているので自動インストール不要
          auto_install = false,
        },
      })
      vim.lsp.enable("jdtls")
    end,
    keys = {
      -- テスト
      { "<leader>jrc", function() require("java").test.run_current_class() end,   desc = "Java: テストクラスを実行" },
      { "<leader>jrm", function() require("java").test.run_current_method() end,  desc = "Java: テストメソッドを実行" },
      { "<leader>jdc", function() require("java").test.debug_current_class() end, desc = "Java: テストクラスをデバッグ" },
      { "<leader>jdm", function() require("java").test.debug_current_method() end, desc = "Java: テストメソッドをデバッグ" },
      { "<leader>jvr", function() require("java").test.view_last_report() end,    desc = "Java: テストレポートを表示" },
      -- ビルド/実行
      { "<leader>jrr", function() require("java").runner.built_in.run_app() end,    desc = "Java: アプリを実行" },
      { "<leader>jrs", function() require("java").runner.built_in.stop_app() end,   desc = "Java: アプリを停止" },
      { "<leader>jrl", function() require("java").runner.built_in.toggle_logs() end, desc = "Java: ログを表示/非表示" },
      { "<leader>jbb", function() require("java").build.build_workspace() end,    desc = "Java: ワークスペースをビルド" },
      { "<leader>jbc", function() require("java").build.clean_workspace() end,    desc = "Java: ワークスペースをクリーン" },
      -- リファクタリング
      { "<leader>jev", function() require("java").refactor.extract_variable() end,  desc = "Java: 変数に抽出", mode = { "n", "v" } },
      { "<leader>jec", function() require("java").refactor.extract_constant() end,  desc = "Java: 定数に抽出", mode = { "n", "v" } },
      { "<leader>jem", function() require("java").refactor.extract_method() end,    desc = "Java: メソッドに抽出", mode = { "n", "v" } },
      -- その他
      { "<leader>jpr", function() require("java").profile.ui() end,               desc = "Java: プロファイル管理" },
      { "<leader>jsr", function() require("java").settings.change_runtime() end,  desc = "Java: JDKバージョン変更" },
    },
  },
}
