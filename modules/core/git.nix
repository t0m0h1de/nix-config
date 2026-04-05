{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Tomohide Sawada";
        email = "Tomohide.Sawada@ibm.com";
      };

      ghq = {
        root = "~/src";
      };
    };

    includes = [
      { path = ../../dotfiles/gitconfig; }
    ];
  };
}
