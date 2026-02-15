{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_latest
    yarn
    cargo
    rustc
    bc
    codex
    gemini-cli
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
