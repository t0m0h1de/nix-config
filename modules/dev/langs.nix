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
  # takumi (npm supply chain guard) settings: _authToken is expanded at runtime from ~/.secrets.
  home.file.".npmrc" = {
    force = true;
    text = ''
      prefix=''${HOME}/.local
      registry=https://npm.flatt.tech/
      //npm.flatt.tech/:_authToken=''${TAKUMI_GUARD_API_KEY}
      minimum-release-age=3
    '';
  };
}
