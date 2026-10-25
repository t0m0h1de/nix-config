#!/usr/bin/env bash
# overlays/default.nix の mise を、jdx/mise の最新リリースに追従させる(nix-update)。
# 必要なもの: nix
#
# --version-regex で mise 本体のタグ(v2026.10.19 など)だけを対象にする。jdx/mise には同じ
# リポジトリの vfox クレートのタグ(vfox-v2026.10.19 など)もあり、指定しないと nix-update は
# それを最新として拾って version を "fox-v2026.10.19" にした(#29。src は tag = "v${version}"
# なので vfox-v... を取りに行く)。
#
# 正規表現を update.yml の run に直接書かないのは、run が PR 本文の echo "..." にも埋め込まれ、
# 引用符も括弧もそのままでは書けないため。
set -euo pipefail

cd "$(dirname "$0")/../.."

nix run --inputs-from . nixpkgs#nix-update -- \
  --flake \
  --override-filename overlays/default.nix \
  --version-regex '^v(\d+\.\d+\.\d+)$' \
  mise
