{ ... }:
{
  programs.nixvim = {
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

    plugins.nvim-autopairs = {
      # 開き括弧やクオート入力時に、自動で閉じ文字も補完する。
      enable = true;
      settings = {
        check_ts = true;
        map_cr = false;
      };
    };
  };
}
