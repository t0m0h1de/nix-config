#!/usr/bin/env bash
# DataDog/pup の最新リリースに overlays/sources/pup.json を追従させる。
# system ごとのプリビルド tarball を取得して hash を計算し直す(nix-update は 1 system 分の
# hash しか更新できないため自前で行う)。変更がなければ何もしない。
# 必要なもの: gh(GH_TOKEN), jq, nix
set -euo pipefail

cd "$(dirname "$0")/../.."
json=overlays/sources/pup.json

current=$(jq -r .version "$json")
latest=$(gh api repos/DataDog/pup/releases/latest --jq .tag_name)
latest=${latest#v}

if [ "$current" = "$latest" ]; then
  echo "pup: up to date ($current)"
  exit 0
fi

tmp=$(mktemp)
trap 'rm -f "$tmp" "$tmp.next"' EXIT
jq --arg v "$latest" '.version = $v' "$json" > "$tmp"

for system in $(jq -r '.assets | keys[]' "$json"); do
  suffix=$(jq -r --arg s "$system" '.assets[$s].suffix' "$json")
  url="https://github.com/DataDog/pup/releases/download/v${latest}/pup_${latest}_${suffix}.tar.gz"
  hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
  jq --arg s "$system" --arg h "$hash" '.assets[$s].hash = $h' "$tmp" > "$tmp.next"
  mv "$tmp.next" "$tmp"
done

cp "$tmp" "$json"
echo "pup: $current -> $latest"
