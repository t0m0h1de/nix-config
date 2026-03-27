{ pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim
  ];

  # dotfiles/nvim/ を ~/.config/nvim にシンボリックリンク
  # lazy.nvim が自由にプラグインを管理できるよう、Nix側はリンクのみ行う
  xdg.configFile."nvim" = {
    source = ../../dotfiles/nvim;
    recursive = true;
  };
}
