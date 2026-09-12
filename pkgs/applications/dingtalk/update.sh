#!/usr/bin/env bash
set -euo pipefail

cd pkgs/applications/dingtalk

# ---------------------------------------------------------------------------
# Determine latest version from the official download redirect.
#
# The DingTalk download page redirects to the actual .deb URL:
#   https://www.dingtalk.com/win/d/qd=linux_amd64  ->  302 to .deb
#
# The Location header contains the filename which encodes the version:
#   .../com.alibabainc.dingtalk_<version>_amd64.deb
# ---------------------------------------------------------------------------

echo ">> querying latest dingtalk version from dingtalk.com ..."

# Follow redirects; dump headers only; extract the final Location.
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Write headers to a temp file to avoid pipe buffering issues.
curl -sS -D "$tmpdir/headers" -o /dev/null 'https://www.dingtalk.com/win/d/qd=linux_amd64'

deb_url=$(
  grep -i '^location:' "$tmpdir/headers" |
    tail -1 |               # take the last Location (after all redirects)
    sed 's/^[Ll]ocation:[[:space:]]*//' |
    tr -d '\r\n'
)

if [ -z "$deb_url" ]; then
  echo "error: could not determine latest DingTalk download URL" >&2
  exit 1
fi

file=$(basename "$deb_url")
version=$(printf '%s' "$file" | sed -n 's/^com\.alibabainc\.dingtalk_\(.*\)_amd64\.deb$/\1/p')

if [ -z "$version" ]; then
  echo "error: could not parse version from URL: $deb_url" >&2
  exit 1
fi

echo ">> latest version: $version"

# Compare with current version.
current=$(sed -n 's/^  version = "\(.*\)";$/\1/p' ./package.nix)

if [ "$version" = "$current" ]; then
  echo "already at $version, nothing to do"
  exit 0
fi

echo ">> updating $current -> $version"

# Download the .deb to compute the sha256 hash.
echo ">> prefetching amd64 .deb to compute hash (this may take a moment) ..."
hash=$(
  nix store prefetch-file \
    --json \
    --name "com.alibabainc.dingtalk_${version}_amd64.deb" \
    "$deb_url" |
    jq -r '.hash'
)

if [ -z "$hash" ] || [ "$hash" = "null" ]; then
  echo "error: failed to compute hash for $deb_url" >&2
  exit 1
fi

echo ">> hash: $hash"

# Update package.nix (version + amd64 hash; keep aarch64 placeholder as-is).
# Only replace a real SRI hash (ends with '=') so the aarch64 placeholder is
# left untouched.
sed -i \
  -e "s|version = \".*\";|version = \"$version\";|" \
  -e "s|\"sha256-[^\"]*=\";|\"$hash\";|" \
  ./package.nix

echo ">> updated $current -> $version (hash: $hash)"
