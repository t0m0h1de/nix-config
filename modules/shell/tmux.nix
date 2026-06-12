{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    mouse = true;
    plugins = [
      pkgs.tmuxPlugins.tmux-fzf
    ];
    extraConfig = (builtins.readFile ../../dotfiles/tmux.conf) + ''

      # ステータスバー
      set -g status on
      set -g status-right-length 150
      set -g status-right "#(${pkgs.kube-tmux}/bin/kube.tmux 250 cyan default)"
    '';
  };
}
