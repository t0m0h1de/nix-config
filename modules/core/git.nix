{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Tomohide Sawada";
    userEmail = "Tomohide.Sawada@ibm.com";

    includes = [
      { path = ../../dotfiles/gitconfig; }

    ];

    extraConfig = {
      ghq = {
        root = "~/src";
      };
    };
  };
}
