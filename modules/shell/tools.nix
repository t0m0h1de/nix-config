{ pkgs, ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # TODO: Remove this override once direnv 2.38.0 is released, which includes a fix for the build failure on musl.
    package = pkgs.direnv.overrideAttrs (_: {
      doCheck = false;
    });
  };
}
