# Nix Configuration & Dotfiles

Nix Flakes + Home Manager を利用した、宣言的な開発環境設定リポジトリ。
WSL (Fedora), Linux, macOS など、OSの違いを吸収し統一された開発体験を提供する。

## 🚀 特徴

* **Nix Flakes:** 再現性の高いパッケージ管理 (`flake.nix`, `flake.lock`)
* **Home Manager:** ユーザー環境（Dotfiles）の構成管理
* **Modern Shell:** Zsh + Starship + Sheldon (Plugin Manager)
* **Dev Tools:**
    * **Cloud Native:** kubectl, helm, argocd, openshift, tektoncd
    * **Langs/AI:** Node.js, Rust, JBang, Gemini CLI
    * **Utils:** jq, yq, glow, ffmpeg, nkf, etc.
* **Config Management:** Vim, Tmux, Git 設定を外部ファイル (`dotfiles/`) として読み込み

## 📂 ディレクトリ構成

```text
~/nix-config/
├── flake.nix           # エントリーポイント (依存関係と出力の定義)
├── home.nix            # Home Manager 設定本体 (パッケージと設定の紐付け)
├── flake.lock          # バージョンロックファイル
└── dotfiles/           # 設定ファイルの実体 (Nixから読み込まれる)
    ├── zshrc           # Zsh設定 (エイリアス・キーバインド等)
    ├── sheldon/        # Zshプラグイン管理
    ├── gitconfig       # Git共通設定
    ├── work.gitconfig  # 業務/特定プロジェクト用Git設定 (includeIfで読み込み)
    ├── vimrc           # Vim設定
    ├── tmux.conf       # Tmux設定
    └── starship.toml   # Starship設定
````

## 🛠 セットアップ手順

### 1\. Nix のインストール

[Determinate Systems](https://github.com/DeterminateSystems/nix-installer) のインストーラ（推奨）を使用する。

```bash
curl --proto '=https' --tlsv1.2 -sSf -L [https://install.determinate.systems/nix](https://install.determinate.systems/nix) | sh -s -- install
```

インストール後、シェルを再起動すること。

### 2\. リポジトリのクローン

```bash
git clone [https://github.com/YOUR_GITHUB_USER/nix-config.git](https://github.com/YOUR_GITHUB_USER/nix-config.git) ~/nix-config
cd ~/nix-config
```

### 3\. 機密情報のセットアップ (必須)

APIトークンなどはGit管理外の `.secrets` ファイルで管理する。
ホームディレクトリ直下に作成すること。

```bash
vim ~/.secrets
```

**内容例:**

```bash
# Hugging Face Token
export HUGGING_FACE_HUB_TOKEN="your_secret_token_here"

# AWS Keys
# export AWS_ACCESS_KEY_ID="path_to_key"

# Bob installer URL (secret)
# export BOB_INSTALL_URL="<bob_installer_url>"
```

権限を変更しておく。

```bash
chmod 600 ~/.secrets
```

### 4\. 環境の適用 (Switch)

以下のコマンドで設定を適用する。
※ 初回は `home-manager` コマンドがないため、`nix run` を経由する。

```bash
# WSL環境の場合 (flake.nix内の "wsl" 定義を使用)
# -b backup オプションで既存の設定ファイルを自動バックアップして上書きする
nix run home-manager/master -- switch --flake .#wsl -b backup
```

## 🔄 日々の運用

### 設定の変更

1.  `home.nix` や `dotfiles/` 内のファイルを編集する。
2.  新規ファイルを追加した場合は `git add` する（必須）。
3.  以下のコマンドで適用する。

```bash
# 2回目以降は home-manager コマンドが使用可能
home-manager switch --flake .#wsl
```

### パッケージの更新

`flake.lock` を更新して、最新のパッケージを取得する。

```bash
nix flake update
home-manager switch --flake .#wsl
```

### パッケージの探し方

```
nix search nixpkgs <パッケージ名>
```

### npm系CLIの運用方針

このリポジトリでは、自己更新前提のCLIはNix管理に含めない。

- Nix管理: OS共通で再現性を重視するツール（例: `codex`, `jq`, `git` など）
- Nix管理外: ベンダー/ npm 管理で更新するCLI（例: `bob`, `claude`, `cline`, `antigravity`）

理由:

- Nix配下（`/nix/store`）は不変
- `npm -g` や `xxx update` は実体の上書きを前提
- そのため自己更新CLIをNix管理すると権限エラーになりやすい

#### 運用例

1. `bob` は公式インストーラ（Windows側/ベンダー提供）でインストール・更新する
2. `claude` / `cline` / `antigravity` は公式手順または `npm` で更新する
3. `home-manager switch --flake .#wsl` 後はシェルを再起動し、`type -a bob` / `type -a claude` で解決先を確認する

### CLI のインストール例（claude / bob）

このリポジトリでは自己更新前提の CLI を Nix では配布しない。
`claude` は公式インストーラで導入する。

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

`bob` は `.secrets` に設定した `BOB_INSTALL_URL` を使って導入する。

```bash
curl -fsSL "$BOB_INSTALL_URL" | bash
```

このリポジトリの `dotfiles/zshrc` には、`claude` / `bob` が未インストール時のみ
上記インストーラを実行する冪等な処理を入れている。
（インタラクティブシェル時のみ、短い `curl` タイムアウト付き、再試行間隔あり）

```bash
export CLAUDE_AUTO_INSTALL=0  # 自動導入を無効化したい場合
export BOB_AUTO_INSTALL=0
export CLI_AUTO_INSTALL_CONNECT_TIMEOUT=3
export CLI_AUTO_INSTALL_MAX_TIME=8
export CLI_AUTO_INSTALL_RETRY_INTERVAL=21600
```

確認例:

```bash
claude --version
bob --version
```

## ⚙️ Git設定について

特定のディレクトリ配下でのみ適用される設定 (`includeIf`) を採用している。

  * **共通設定:** `dotfiles/gitconfig`
  * **特定プロジェクト用:** `dotfiles/work.gitconfig` (例)
      * 適用条件: 特定のワークスペース配下のGitリポジトリ（例: `~/workspace/proj-a/`）

## ⚠️ 注意事項

  * **ホストのShellについて:** WSL/Linux側の `/bin/zsh` (または `/bin/bash`) は削除しないこと。Nix環境へのログインに必要となる。
  * **Git管理:** 新しい設定ファイルを追加した際は、必ず `git add` すること。Nix FlakesはGit管理外のファイルを認識しない。
  * **WSL Fedora 42 以降の WSLg 警告について:** `home-manager switch` 実行時に `The user systemd session is degraded` として `wslg-session.service` 失敗が出る場合がある。`/run/user/$UID/pulse` のリンク作成が `tmpfiles` と `wslg-session.service` で重複し、`ln: ... are the same file` で失敗する既知ケース。GUI を使う場合でも通常は以下で解消できる。

```bash
systemctl --user mask --now wslg-session.service
systemctl --user reset-failed
systemctl --user is-system-running
```

必要なら元に戻せる:

```bash
systemctl --user unmask wslg-session.service
systemctl --user start wslg-session.service
```
