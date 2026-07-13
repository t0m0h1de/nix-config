{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gcc
    nodejs_latest
    yarn
    jdk17
    coursier
    sbt
    # scala-cli: 単発 Scala スクリプト / worksheet(.sc)/ scala-cli ビルドの実行用。
    # sbt プロジェクトには必須ではないが、Metals の worksheet/標準ファイル処理でも使われる。
    # bin は scala-cli のみで既存(sbt/coursier/jdk17/metals)と衝突しない。
    scala-cli
    cargo
    rustc
    bc
  ];

  home.sessionVariables = {
    # nixpkgs が OS 差(Darwin=zulu / Linux=openjdk)を吸収した JAVA_HOME を返す。
    # 旧 "${pkgs.jdk17}/lib/openjdk" は実在しないパスだった。
    JAVA_HOME = "${pkgs.jdk17.home}";
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
