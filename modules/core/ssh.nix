{ pkgs, lib, config, ... }:
{
  # Coder CLI の `coder config-ssh` が SSH 設定を書き込む先を ~/.ssh/config 本体ではなく
  # ~/.ssh/config.d/coder.conf に固定する。既定は ~/.ssh/config だが、そこは Home Manager が
  # read-only symlink で管理しているため、CLI が本体を書き換えると次回 activation が
  # 「would be clobbered」で失敗する。config.d は下の extraConfig で Include 済みなので、
  # coder.conf に逃がせば HM 本体と衝突しない(VS Code 拡張側は remote.SSH.configFile で別途対処)。
  home.sessionVariables.CODER_SSH_CONFIG_FILE = "${config.home.homeDirectory}/.ssh/config.d/coder.conf";

  programs.ssh = {
    # ~/.ssh/config を Home Manager で管理する。
    enable = true;
    # 将来のデフォルト値変更影響を避けるため、明示設定だけを生成する。
    enableDefaultConfig = false;
    extraConfig = ''
      # 個別環境での自由な追記はここに置く（Git 管理外推奨）。
      Include ~/.ssh/config.d/*.conf
    '';
    settings = {
      "*" = { };
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/github.com";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      } // lib.optionalAttrs pkgs.stdenv.isDarwin {
        UseKeychain = "yes";
      };
    };
  };
}
