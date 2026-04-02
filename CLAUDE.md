# Agent Development Guide

このリポジトリでエージェントが動作するためのガイドライン

## アーキテクチャ

[Home Manager](https://github.com/nix-community/home-manager)を利用したFlake構成。
x86_64とaarch64など複数のCPUアーキテクチャ、linux, macOSなどの複数のOSをサポートし、OS固有の差分は `pkgs.stdenv` の条件分岐で処理する。
具体的なサポート対象は[HomeManagerのプロファイル](#homemanagerのプロファイル)を参照。

## 主要コマンド

* 設定の適用 (初回 / 更新)
    * 初回(Home Managerが未インストールの場合): `nix run home-manager/master -- switch --flake .#<profile>`
    * 更新: `home-manager switch --flake .#<profile>`
* メンテナンス
    * 依存関係の更新: `nix flake update`
    * 整形: `nixpkgs-fmt <file.nix>`

## HomeManagerのプロファイル

Home Managerのプロファイルは、[`flake.nix`](./flake.nix)の`homeConfigurations`を確認すること。

### モジュール構成

`home.nix`が以下の4モジュールを読み込む。

* core(`modules/core/`): 共通パッケージ、Git、環境変数
* dev(`modules/dev/`): 各種プログラム言語, 開発ツール(例: K8s, OpenTofu)
* shell(`modules/shell/`): シェル本体、シェルのプラグイン管理、拡張(例: Starship, Tmux, Sheldon, direnv)
* editors(`modules/editors/`): Vim, Neovimなどのエディタ

### 設定ファイル (Dotfiles) の扱い

各nixファイルで`builtins.readFile`で文字列として設定を読み込む、もしくは`xdg.configFile`で`dotfiles/`下をシンボリックリンクとして`~/.config`下に配置する。

### ツール管理

* Nix管理: OS共通で再現性を重視するツール（例: `codex`, `jq`, `git` など）
* Nix管理外: ベンダー/ npm 管理で更新するCLI（例: `claude`, `cline`など）

### 秘匿情報

`~/.secrets`に記述し、`.zshrc`で読み込み、Git管理は禁止。

## ルール
- 作業前に `docs/progress.md` を読む
- 作業後に `docs/progress.md` を更新する
- 新規API追加時は ADR を確認する
