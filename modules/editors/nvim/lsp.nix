{ pkgs, ... }:
let
  # nvim-cmp の補完能力を LSP に伝える共通設定。
  cmpCapabilities = {
    capabilities.__raw = ''require("cmp_nvim_lsp").default_capabilities()'';
  };
in
{
  programs.nixvim = {
    plugins.lsp = {
      # LSP を有効化。Python / Web の基本言語を導入する。
      enable = true;
      servers = {
        pyright = {
          enable = true;
          package = pkgs.pyright;
          extraOptions = cmpCapabilities;
        };
        html = {
          enable = true;
          extraOptions = cmpCapabilities;
        };
        cssls = {
          enable = true;
          extraOptions = cmpCapabilities;
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
          extraOptions = cmpCapabilities;
        };
      };
    };

    extraConfigLua = ''
      -- LSP がアタッチされたバッファだけで基本キーマップを有効化。
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local opts = { buffer = event.buf, silent = true }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        end,
      })
    '';
  };
}
