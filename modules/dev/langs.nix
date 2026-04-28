{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gcc
    nodejs_latest
    yarn
    coursier
    sbt
    cargo
    rustc
    bc
  ];

  # Declarative npm global prefix (replaces `npm config set prefix ~/.local`).
  # `force = true` avoids collision with an existing ~/.npmrc.
  home.file.".npmrc" = {
    force = true;
    text = ''
      prefix=''${HOME}/.local
    '';
  };
}
