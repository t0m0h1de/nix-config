{ pkgs, lib, ... }:
{
  programs.ssh = {
    # ~/.ssh/config を Home Manager で管理する。
    enable = true;
    # 将来のデフォルト値変更影響を避けるため、明示設定だけを生成する。
    enableDefaultConfig = false;
    extraConfig = ''
      # 個別環境での自由な追記はここに置く（Git 管理外推奨）。
      Include ~/.ssh/config.d/*.conf
    '';
    matchBlocks = {
      "*" = { };
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/github.com";
        identitiesOnly = true;
        extraOptions =
          {
            AddKeysToAgent = "yes";
          }
          // lib.optionalAttrs pkgs.stdenv.isDarwin {
            UseKeychain = "yes";
          };
      };
    };
  };
}
