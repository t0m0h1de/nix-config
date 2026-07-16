# Nix Configuration & Dotfiles

Nix Flakes + Home Manager を利用した開発環境定義リポジトリ。

## 🚀 特徴

* Nix Flakes: 再現性あるパッケージ管理 (`flake.nix`, `flake.lock`)
* Home Manager: Dotfiles等の構成管理

## 📂 ディレクトリ構成

```text
~/nix-config/
├── flake.nix           # エントリーポイント (linux / darwin / work プロファイルを定義)
├── home.nix            # Home Manager 設定本体 (Linux/Darwin共通。OS差分は内部で吸収)
├── flake.lock          # バージョンロックファイル
├── modules/
│   ├── core/           # 共通パッケージ・Git・基本設定 (OS別パッケージはlib.optionals で分岐)
│   ├── dev/            # 開発ツール (k8s, langs, opentofu)
│   ├── shell/          # Zsh・Starship・direnv
│   └── editors/        # Vim / Neovim (nixvimによる管理)
└── dotfiles/           # 設定ファイルの実体 (Nixから読み込まれる)
    ├── zshrc           # Zsh設定 (エイリアス・キーバインド等)
    ├── gitconfig       # Git共通設定 (マシン固有設定は ~/.gitconfig-extras で上書き)
    ├── vimrc           # Vim設定
    ├── tmux.conf       # Tmux設定
    └── starship.toml   # Starship設定
```

### OS別パッケージ管理

`modules/core/packages.nix` で `lib.optionals` を使い、OS専用パッケージを宣言的に管理。

OSごとのパッケージ差異の例

| パッケージ | Linux | Darwin |
|---|:---:|:---:|
| buildah | ✅ | ❌ |
| その他共通パッケージ | ✅ | ✅ |

## 🛠 セットアップ手順

### 1\. Nix のインストール

[Determinate Systems](https://github.com/DeterminateSystems/nix-installer) のインストーラを使用する。

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

内容例:

```bash
# Hugging Face Token
export HUGGING_FACE_HUB_TOKEN="your_secret_token_here"

# AWS Keys
# export AWS_ACCESS_KEY_ID="path_to_key"
```

権限も変更しておく。

```bash
chmod 600 ~/.secrets
```

### 4\. 環境の適用 (Switch)

利用するプロファイル (`flake.nix` の `homeConfigurations`) は3つ。

| プロファイル | 用途 | `home.username` |
|---|---|---|
| `linux` | Linux / WSL | `t0m0h1de` |
| `work` | 業務用 macOS（このマシン） | `tomohide.sawada` |
| `darwin` | 個人用 macOS | `t0m0h1de` |

> ⚠️ `darwin` は `home.username = t0m0h1de` 前提。ユーザー名が異なるマシンでは activation に失敗するため、業務用 Mac では必ず `work` を使う。

以下のコマンドで設定を適用する。
※ 初回は `home-manager` コマンドがないため、`nix run` を経由する。
（`-b backup` で既存の設定ファイルを自動バックアップして上書きする）

```bash
# Linux / WSL
nix run home-manager/master -- switch --flake .#linux -b backup

# macOS（業務用・このマシン）
nix run home-manager/master -- switch --flake .#work -b backup

# macOS（個人用）
nix run home-manager/master -- switch --flake .#darwin -b backup
```

## 🔄 日々の運用

### 設定の変更

1.  `home.nix` や `dotfiles/` 内のファイルを編集する。
2.  新規ファイルを追加した場合は `git add` する（必須）。
3.  以下のコマンドで適用する。

```bash
# 2回目以降は home-manager コマンドが使用可能
home-manager switch --flake .#linux   # Linux/WSL
home-manager switch --flake .#work    # macOS（業務用・このマシン）
home-manager switch --flake .#darwin  # macOS（個人用）
```

> 💡 `nh`（Nix CLI ヘルパー、`modules/core/nh.nix` で導入）でも同じことができる。
> ビルド進捗の TUI 表示と、適用前後で変わるパッケージの差分表示が付く。
> `NH_FLAKE` に本リポジトリのパスが設定済みなので `--flake` は省略でき、プロファイルは `-c` で指定する。
>
> ```bash
> nh home switch -c linux    # Linux/WSL
> nh home switch -c work     # macOS（業務用・このマシン）
> nh home switch -c darwin   # macOS（個人用）
> ```
>
> ※ `nh` 自体はこのリポジトリで導入されるため、初回だけは上記 `home-manager switch`（または `nix run`）が必要。

### パッケージの更新

`flake.lock` を更新して、最新のパッケージを取得する。

```bash
nix flake update
home-manager switch --flake .#linux   # Linux/WSL
home-manager switch --flake .#work    # macOS（業務用・このマシン）
home-manager switch --flake .#darwin  # macOS（個人用）
```

> 💡 適用側は `nh home switch -c <profile>` に置き換えてもよい（`nix flake update` はそのまま）。

### 世代の掃除（GC）

古い世代を削除してディスクを空ける。`nh` を導入しているため、保持ポリシー付きで掃除できる。

```bash
# 5世代 or 直近7日を残して掃除（対話で確認あり）
nh clean all --keep 5 --keep-since 7d

# ユーザープロファイルのみ対象
nh clean user
```

> ℹ️ 定期 GC は `programs.nh.clean` で自動化済み（週1、`--keep 5 --keep-since 7d`）。
> Linux は systemd user timer、macOS は launchd agent で実行される。上記は手動で追加実行したいとき用。

### よく使う Nix コマンド

#### パッケージを探す

```bash
# キーワードで検索
nix search nixpkgs ripgrep

# 正規表現で絞り込み
nix search nixpkgs 'python3[0-9]+Packages\.wheel$'
```

> 💡 `nh search ripgrep` でも検索できる（結果がキャッシュされ 2 回目以降が速い）。

#### パッケージ情報を確認する

```bash
# パッケージの説明を確認
nix eval --raw nixpkgs#ripgrep.meta.description

# どの derivation が解決されるか確認
nix path-info nixpkgs#ripgrep
```

#### インストールせずに一時的に使う

```bash
# 一時シェルでコマンド実行
nix shell nixpkgs#ripgrep -c rg --version
```

#### Flake の出力を確認する

```bash
# このリポジトリで利用可能な出力を確認
nix flake show
```

### npm系CLIの運用方針

このリポジトリでは、自己更新前提のCLIはNix管理に含めない。

- Nix管理: OS共通で再現性を重視するツール（例: `codex`, `jq`, `git` など）
- Nix管理外: ベンダー/ npm 管理で更新するCLI（例: `codex`, `gemini-cli`, `copilot`, `jules`, `claude`, `cline`, `antigravity`）

理由:

- Nix配下（`/nix/store`）は不変
- `npm -g` や `xxx update` は実体の上書きを前提
- そのため自己更新CLIをNix管理すると権限エラーになりやすい

#### 運用例

1. `home-manager switch --flake .#linux` (または `.#darwin`) 後はシェルを再起動する
2. AI CLI は zsh alias から `npx` で起動する
3. `type -a codex` / `type -a claude` などで alias の解決先を確認する

### AI CLI alias

このリポジトリでは AI CLI を zsh alias で `npx` 起動する。
そのため Node.js / npm が利用可能であることを前提とする。

```bash
codex='npx @openai/codex'
gemini-cli='npx @google/gemini-cli'
copilot='npx @github/copilot'
jules='npx @google/jules'
claude='npx @anthropic-ai/claude-code'
```

確認例:

```bash
type -a codex
claude --version
```

### Neovim の GitHub Copilot セットアップ

このリポジトリの Neovim は `copilot.lua` + `copilot-cmp` で、Copilot を `nvim-cmp` の候補として使う構成。
`panel` / `suggestion` は意図的に無効化している。

1. Neovim 内で認証する。

```vim
:Copilot auth
```

ブラウザでデバイス認証を完了する。

2. 状態を確認する。

```vim
:Copilot status
```

必要時の操作:

```vim
:Copilot auth info
:Copilot auth signout
:Copilot auth signin
```

認証情報の保存先:

- Linux/macOS: `~/.config/github-copilot/apps.json`
- Windows: `~/AppData/Local/github-copilot/apps.json`

## ⚙️ Git設定について

  * 共通設定: `modules/core/git.nix`（`user.name` / `user.email` など）と `dotfiles/gitconfig`。
  * マシン固有・業務用の上書き: `~/.gitconfig-extras`（Git管理外）。
    `dotfiles/gitconfig` の `[include] path = ~/.gitconfig-extras` で読み込まれる。
    業務用のメールアドレス等、このリポジトリに含めたくない設定はここに記述する。

## ⚠️ 注意事項

  * ホストのShellについて: WSL/Linux側の `/bin/zsh` (または `/bin/bash`) は削除しないこと。Nix環境へのログインに必要となる。
  * Git管理: 新しい設定ファイルを追加した際は、必ず `git add` すること。Nix FlakesはGit管理外のファイルを認識しない。
  * WSL Fedora 42 以降の WSLg 警告について: `home-manager switch` 実行時に `The user systemd session is degraded` として `wslg-session.service` 失敗が出る場合がある。`/run/user/$UID/pulse` のリンク作成が `tmpfiles` と `wslg-session.service` で重複し、`ln: ... are the same file` で失敗する既知ケース。GUI を使う場合でも通常は以下で解消できる。

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
