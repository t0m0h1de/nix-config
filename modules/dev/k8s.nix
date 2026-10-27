{ pkgs, config, ... }:
let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    ps."ansible-core"
    kubernetes
    openshift
    pyyaml
  ]);

  # python3・python だけを置いたディレクトリ。下の initContent で PATH の先頭に足す。
  # macOS の /etc/zprofile の path_helper が /usr/bin を ~/.nix-profile/bin より前に並べるので、
  # `#!/usr/bin/env python3` で始まるスクリプト(pre-commit の zipapp や git の hook を含む)は
  # macOS 付属の 3.9.6 で動き、新しい virtualenv・filelock などが動かない。
  # PATH 全体を並べ直すと git・cc・java なども Nix 版に変わるので、python だけを前に出す。
  # pip・pip3 は Nix の Python には無いので、そのままだと /usr/bin/pip3(macOS の 3.9 と LibreSSL)が動く。
  # Nix の環境には書き込めない(読み取り専用)ので、macOS の pip が動く前に止めて、使う方法を案内する。
  pipGuard = pkgs.writeShellScript "pip-guard" ''
    cat >&2 <<'EOF'
    pip は直接使わない(macOS 付属の 3.9 の pip が動くのを防ぐため、modules/dev/k8s.nix で止めている)。
      リポジトリの依存: そのリポジトリの mise / uv / poetry を使う
      使い捨ての環境:   python3 -m venv .venv && .venv/bin/pip install ...
      単体のツール:     uv tool install <パッケージ>
    EOF
    exit 1
  '';

  pythonShim = pkgs.runCommand "python3-path-shim" { } ''
    mkdir -p $out/bin
    ln -s ${pythonEnv}/bin/python3 $out/bin/python3
    ln -s ${pythonEnv}/bin/python $out/bin/python
    ln -s ${pipGuard} $out/bin/pip
    ln -s ${pipGuard} $out/bin/pip3
  '';
in
{
  # .zshrc は /etc/zprofile(path_helper)より後に読まれるので、ここで足せば並べ直されない。
  # mise が有効なリポジトリでは、mise が自分の python をさらに前に足すので、そちらが優先される。
  programs.zsh.initContent = ''
    path=(${pythonShim}/bin $path)
  '';

  home.file.".kube/kubie.yaml".text = ''
    behavior:
      selector: fzf
  '';

  # k9s の設定ディレクトリを OS 間で ~/.config/k9s に揃える。
  # k9s は adrg/xdg を使うため、XDG_CONFIG_HOME が未設定の macOS では
  # ~/Library/Application Support/k9s を、Linux では ~/.config/k9s を既定にする。
  # このリポジトリは xdg.enable を有効にしていない(XDG_CONFIG_HOME を export しない)ので、
  # K9S_CONFIG_DIR で明示的に固定し、xdg.configFile 一本で管理できるようにする。
  home.sessionVariables.K9S_CONFIG_DIR = "${config.xdg.configHome}/k9s";

  # k9s を既定で readOnly にする(誤操作でクラスタを壊さないため)。書きたいときは `k9s --write`。
  # store への read-only シンボリックリンクで問題ない理由:
  #   - k9s が config.yaml を書き出すのは「ファイルが存在しないとき」だけ
  #     (internal/config/config.go の Save(): os.Stat が ErrNotExist のときのみ SaveFile)。
  #   - 実行中に書き換わるコンテキスト別の状態は clusters/<cluster>/<context>/config.yaml に分離済み。
  # 全体設定が上書きされない理由:
  #   - コンテキスト別 config の readOnly は `*bool` + `yaml:"readOnly,omitempty"` で、
  #     NewContext() は nil のまま(internal/config/data/context.go)。自動生成ファイルに
  #     readOnly 行が出ないので IsReadOnly() はここの値にフォールバックし続ける。
  xdg.configFile."k9s/config.yaml".text = ''
    k9s:
      readOnly: true
  '';

  home.packages = with pkgs; [
    pythonEnv
    kubectl
    kustomize # 以前は gcloud SDK 同梱版が PATH に居た(modules/dev/gcloud.nix の移行で単体化)
    k9s
    kubie
    kubernetes-helm
    argocd
    openshift
    tektoncd-cli
  ];
}
