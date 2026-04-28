{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gcc
    nodejs_latest
    yarn
    jdk17
    coursier
    sbt
    cargo
    rustc
    bc
  ];

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
  };

  # Declarative npm global prefix (replaces `npm config set prefix ~/.local`).
  # `force = true` avoids collision with an existing ~/.npmrc.
  home.file.".npmrc" = {
    force = true;
    text = ''
      prefix=''${HOME}/.local
    '';
  };
}
