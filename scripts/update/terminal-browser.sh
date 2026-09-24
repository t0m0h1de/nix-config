#!/usr/bin/env bash
# terminal-browser の公式インストーラが指す最新版に overlays/sources/terminal-browser.json を追従させる。
# GitHub Releases には成果物が無いため、インストーラ先頭の VERSION と PLATFORMS 表
# (`<target> <url> <sha256(hex)> <size>` の行)を読む。変更がなければ何もしない。
# 必要なもの: curl, jq, nix
set -euo pipefail

cd "$(dirname "$0")/../.."
json=overlays/sources/terminal-browser.json
target=darwin-arm64

installer=$(curl -fsSL https://terminal-browser.sh/install)

latest=$(printf '%s\n' "$installer" | sed -n 's/^VERSION="v\{0,1\}\([^"]*\)"$/\1/p')
# PLATFORMS 表の1行目は `PLATFORMS="darwin-arm64 ...` と代入に続くので、引用符を外し `=` で区切る。
row=$(printf '%s\n' "$installer" | tr -d '"' | sed 's/^PLATFORMS=//' | awk -v t="$target" '$1 == t && NF == 4')
url=$(printf '%s\n' "$row" | awk '{ print $2 }')
sha256=$(printf '%s\n' "$row" | awk '{ print $3 }')

if [ -z "$latest" ] || [ -z "$url" ] || [ -z "$sha256" ]; then
  echo "terminal-browser: failed to parse the installer (format changed?)" >&2
  exit 1
fi

# overlay は URL を version から組み立てているので、インストーラの URL と一致することを確かめる。
expected="https://terminal-browser.sh/install/dl/stable/v${latest}/terminal-browser-${target}.tar.gz"
if [ "$url" != "$expected" ]; then
  echo "terminal-browser: unexpected download URL: $url (expected $expected)" >&2
  exit 1
fi

current=$(jq -r .version "$json")
if [ "$current" = "$latest" ]; then
  echo "terminal-browser: up to date ($current)"
  exit 0
fi

hash=$(nix hash convert --hash-algo sha256 --to sri "$sha256")
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
jq --arg v "$latest" --arg h "$hash" '.version = $v | .hash = $h' "$json" > "$tmp"
cp "$tmp" "$json"
echo "terminal-browser: $current -> $latest"
