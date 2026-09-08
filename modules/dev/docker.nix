{ pkgs, ... }:
{
  # docker / docker-compose / colima 本体は brew 管理(Nix管理外)。
  # macOS の VM(colima = Virtualization.Framework)と密結合しており、そちらは brew に任せる。
  # 一方 buildx は「docker CLI のクライアント側プラグイン」でしかなく、VM とは疎結合
  # (ビルドの実行は colima 側の daemon に同梱された BuildKit が担う)。
  # プラグイン API 経由でしか docker CLI と繋がらないため単独で Nix 管理でき、
  # 再現性の観点からこちらに寄せる。
  #
  # docker CLI は ~/.docker/cli-plugins/docker-<name> を走査してサブコマンドを生やすので、
  # store 内の実体をそこへ貼るだけで `docker buildx ...` が使えるようになる。
  # home.packages には入れない: 単体の `docker-buildx` を PATH に出す必要はなく、
  # symlink の参照だけで generation の closure に入りGCからも保護される。
  #
  # マルチアーキについて(実測メモ):
  #   colima の builder は既定で linux/arm64, linux/amd64, linux/amd64/v2, linux/386 を報告する
  #   (`docker buildx inspect colima`)。つまり amd64 のエミュレーションは VM 側で登録済みで、
  #   `--platform linux/amd64` の単一プラットフォームビルドは追加設定なしで通る。
  #   ただし既定の `docker` driver は 1 回のビルドで複数プラットフォームのマニフェストを
  #   出力できないので、マルチアーキイメージを作るなら
  #     docker buildx create --driver docker-container --use
  #   で colima 内に BuildKit コンテナを立てる。上記以外のアーキ(riscv64 等)が要るときだけ
  #     docker run --privileged --rm tonistiigi/binfmt --install all
  #   で binfmt を追加登録する。
  home.file.".docker/cli-plugins/docker-buildx".source =
    "${pkgs.docker-buildx}/libexec/docker/cli-plugins/docker-buildx";
}
