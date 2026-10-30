{ config, lib, pkgs, ... }:
let
  pluginCacheDir = "${config.xdg.cacheHome}/opentofu/plugin-cache";
in
{
  home.packages = with pkgs; [
    opentofu
    terragrunt
  ];

  # プロバイダーをディレクトリごとに落とさず 1 か所で共有する。
  # 未設定だと .terraform / .terragrunt-cache ごとに同じプロバイダー(google だけで 256M)が置かれ、
  # worktree を作るたびに増えて ~/src が 20G を超えていた。
  # TF_PLUGIN_CACHE_DIR は素の tofu 用。terragrunt は並列 init で同じキャッシュに書き込むと壊れうるので、
  # 自前のキャッシュサーバー(TG_PROVIDER_CACHE)で直列化させる。
  home.sessionVariables = {
    TF_PLUGIN_CACHE_DIR = pluginCacheDir;
    TG_PROVIDER_CACHE = "1";
  };

  # キャッシュディレクトリが無いと tofu init がエラーになる。
  home.activation.opentofuPluginCacheDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${pluginCacheDir}"
  '';
}
