# Agent Guide

Home Manager の Flake 構成(プロファイルは `flake.nix` の `homeConfigurations`)。構成・コマンドは README とコードを参照し、ここにはコードから読み取れない約束事だけを書く。

## 約束事

- **秘匿情報は `~/.secrets` に置き、Git 管理しない**(`.zshrc` が読み込む)。リポジトリに書かないこと。
- **自己更新する CLI(`claude`, `codex` など)は Nix で入れない**。npm / ベンダー配布のまま使う。Nix で入れると自己更新が read-only のストアに書けず壊れるため。
- **AI ツールの設定ファイルは symlink にせず、activation でマージする**(`modules/core/{claude,codex,antigravity}.nix`)。`~/.claude/settings.json` や `~/.codex/config.toml` にはツール自身も書き込むので、`xdg.configFile` 等で read-only にすると壊れる。共有したい値は `dotfiles/<tool>/` のベースに書く。
- **overlay に自前パッケージを足したら、`.github/workflows/update.yml` の `plan` の targets にも更新方法と cron を足す**(同じ cron を `on.schedule` と `workflow_dispatch` の選択肢にも)。足さないと bump されずに放置される。nixpkgs に同じものが入ったら overlay は消す。

## 検証

- 新規ファイルは `git add` するまで flake から見えない(評価エラーになる)。
- switch せずに確認するなら `nix build .#homeConfigurations.<profile>.activationPackage`(他 OS のプロファイルは `nix eval ...drvPath` で評価だけ)。overlay のパッケージ単体は `nix build .#<name>`。
- 整形は `nixpkgs-fmt`。CI(`.github/workflows/ci.yml`)が `nixpkgs-fmt --check .` と全プロファイルのビルドを行う。
