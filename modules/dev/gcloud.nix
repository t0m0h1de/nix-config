{ pkgs, ... }:
{
  # Google Cloud CLI。公式インストーラー(~/.gcloud)から Nix 管理へ移行した。
  #
  # 補完: パッケージが share/zsh/site-functions/{_gcloud,_gsutil} を同梱しており、
  # Home Manager の zsh モジュールが profile の site-functions を fpath に入れるため、
  # zshrc 側に追加設定は不要(公式インストーラーの completion.zsh.inc を source する方式は不要)。
  #
  # コンポーネント: base に gcloud/alpha/beta/bq/gsutil/gcloud-crc32c が含まれる。
  # それ以外は withExtraComponents で明示する。`gcloud components install` は
  # store が read-only なので使えない ⇒ 必要なものはここに書く。
  # kubectl / kustomize は SDK 版ではなく nixpkgs の単体パッケージ(modules/dev/k8s.nix)を使う。
  home.packages = [
    (pkgs.google-cloud-sdk.withExtraComponents (with pkgs.google-cloud-sdk.components; [
      gke-gcloud-auth-plugin # kubectl の GKE 認証に必須
      pubsub-emulator
    ]))
  ];
}
