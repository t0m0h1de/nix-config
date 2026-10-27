{ pkgs, lib, ... }:
{
  # Linux: Nixでvimをインストールして設定も管理
  programs.vim = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    enable = true;
    extraConfig = builtins.readFile ../../dotfiles/vimrc;
  };

  # Darwin: macOS組み込みvimを使うので~/.vimrcだけ配置
  home.file.".vimrc" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    source = ../../dotfiles/vimrc;
  };
}
