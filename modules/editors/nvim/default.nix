{ pkgs, ... }:
{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./plugins.nix
    ./completion.nix
    ./lsp.nix
    ./scala.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    nixpkgs.source = pkgs.path;

    # 見た目は一旦 tokyonight に寄せる。
    colorschemes.tokyonight.enable = true;
    colorscheme = "tokyonight";

    # Leader は今後の拡張余地のためにだけ先に固定しておく。
    globals.mapleader = " ";
    globals.maplocalleader = " ";

    extraConfigLua = ''
      local is_ssh = vim.env.SSH_TTY ~= nil
      local is_wsl = vim.env.WSL_INTEROP ~= nil or vim.env.WSL_DISTRO_NAME ~= nil

      if vim.fn.has("mac") == 1 and not is_ssh and not is_wsl then
        -- macOS: tmux 経由でも pbcopy/pbpaste を確実に使うため明示指定する。
        -- Nix 管理の Neovim は PATH が制限されることがあり、自動検出が失敗する場合がある。
        vim.g.clipboard = {
          name = "macOS",
          copy  = { ["+"] = "pbcopy",  ["*"] = "pbcopy"  },
          paste = { ["+"] = "pbpaste", ["*"] = "pbpaste" },
          cache_enabled = false,
        }
      elseif is_ssh or is_wsl then
        -- SSH / WSL: ローカルツールが使えないため OSC 52 にフォールバック。
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
    '';
  };
}
