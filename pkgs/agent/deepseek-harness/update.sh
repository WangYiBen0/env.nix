#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ $# -gt 1 ]; then
  echo "usage: $0 [version]" >&2
  exit 1
fi

if [ $# -eq 1 ]; then
  version="$1"
else
  echo ">> fetching latest version from npm"
  version="$(
    curl -sfL https://registry.npmjs.org/@deepseek-ai%2Fdsh/latest |
      grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' |
      head -1 |
      sed 's/.*"\([^"]*\)"$/\1/'
  )"
  if [ -z "$version" ]; then
    echo "failed to determine latest version" >&2
    exit 1
  fi
fi

current="$(sed -n 's/^  version = "\(.*\)";$/\1/p' ./package.nix)"
if [ "$version" = "$current" ]; then
  echo "already at $version, nothing to do"
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat >"$tmp/package.json" <<EOF
{
  "name": "dsh-wrapper",
  "version": "0.0.0",
  "private": true,
  "dependencies": {
    "@deepseek-ai/dsh": "$version"
  }
}
EOF

echo ">> generating package-lock.json for $version"
(
  cd "$tmp"
  nix shell nixpkgs#nodejs -c \
    npm install --package-lock-only --ignore-scripts --no-audit --no-fund >/dev/null
)
cp "$tmp/package-lock.json" ./package-lock.json

echo ">> fetching tarball"
curl -sfL -o "$tmp/dsh.tgz" "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-$version.tgz"
mkdir -p "$tmp/src"
tar -xzf "$tmp/dsh.tgz" -C "$tmp/src" --strip-components=1
src_hash="$(nix hash path --sri "$tmp/src")"

echo ">> prefetching npm deps"
nix shell nixpkgs#prefetch-npm-deps -c prefetch-npm-deps ./package-lock.json >"$tmp/deps-hash"
deps_hash="$(tail -1 "$tmp/deps-hash")"

sed -i \
  -e "s|version = \".*\";|version = \"$version\";|" \
  -e "s|hash = \"sha256-[^\"]*\";|hash = \"$src_hash\";|" \
  -e "s|npmDepsHash = \"sha256-[^\"]*\";|npmDepsHash = \"$deps_hash\";|" \
  ./package.nix

echo ">> updated $current -> $version (src: $src_hash, deps: $deps_hash)"
