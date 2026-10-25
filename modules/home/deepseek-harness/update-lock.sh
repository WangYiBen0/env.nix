#!/usr/bin/env bash
# Regenerate dsh-plugins.lock.json from the declarations in plugins.nix.
#
# Every entry in plugins.nix states an npm name and a version; the hashes are
# what this script computes. Run it after changing a version:
#
#   ./update-lock.sh           # refresh the lock
#   ./update-lock.sh --check   # report what would change, exit 1 if anything
#
# A registry tarball hash is one `nix store prefetch-file`. A dependency-store
# hash (`npmDepsHash`) is not, because it only exists as the answer to a failed
# build — so this asks Nix to build the plugin with a placeholder and reads the
# "got:" line back. That is the same two-step Nix itself documents; it just no
# longer has to be done by hand per plugin.
set -euo pipefail

cd "$(dirname "$0")"
REPO=$(git rev-parse --show-toplevel)

LOCK=dsh-plugins.lock.json
CHECK=0
[ "${1:-}" = "--check" ] && CHECK=1

NIX=${NIX:-nix}
export NIX_CONFIG=${NIX_CONFIG:-$'eval-cache = false\nconnect-timeout = 30\nstalled-download-timeout = 60'}
: "${XDG_CACHE_HOME:=/tmp/nixcache}"
export XDG_CACHE_HOME

# Declarations, straight out of plugins.nix so there is one source of truth.
# Each line: <lock key>\t<npm name>\t<version>\t<has-npm-lockfile>
read_declarations() {
  python3 - <<'PY'
import re, sys
s = open('plugins.nix').read()
# fromNpm "<key>" "<name>" "<version>" { ...npmLockfile... }
for m in re.finditer(r'fromNpm\s+"([^"]+)"\s+"([^"]+)"\s+"([^"]+)"\s*(?:\{(.*?)\}|;)',
                     s, re.S):
    key, name, version, body = m.group(1), m.group(2), m.group(3), m.group(4) or ''
    print('\t'.join([key, name, version, 'yes' if 'npmLockfile' in body else 'no']))
PY
}

# The registry tarball hash. npm's own metadata is authoritative for the
# tarball URL, which is why it is queried rather than derived.
tarball_hash() {
  local name="$1" version="$2"
  local url
  url=$($NIX --extra-experimental-features 'nix-command flakes' eval --impure --raw --expr \
    "let lib = (builtins.getFlake \"path:$REPO\").inputs.nixpkgs.lib; in
     lib.replaceStrings [\"/\"] [\"%2f\"] \"$name\" + \"/-/\"
     + lib.last (lib.splitString \"/\" (lib.removePrefix \"@\" \"$name\"))
     + \"-$version.tgz\"" 2>/dev/null) || return 1
  local full="https://registry.npmjs.org/$url"
  local out
  # The store name is cosmetic, but it must be a legal store name: the npm
  # scope's `@` is not, so it is stripped from the basename only.
  local base=${name##*/}
  out=$($NIX --extra-experimental-features 'nix-command flakes' \
        store prefetch-file --json --name "$base-$version.tgz" "$full" 2>/dev/null) || {
    echo "  ! could not fetch $full" >&2
    return 1
  }
  printf '%s' "$out" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hash"])'
}

# The dependency-store hash, learned from a failed build. The plugin's own
# derivation is built with a deliberately wrong hash; Nix prints the real one.
deps_hash() {
  local key="$1" tarball="$2"
  local expr m
  m=$(python3 - "$key" <<'PY'
import re, sys
key = sys.argv[1]
s = open('plugins.nix').read()
mm = re.search(r'fromNpm\s+"%s"\s+"([^"]+)"\s+"([^"]+)"\s*\{(.*?)\}' % re.escape(key), s, re.S)
if not mm:
    sys.exit(1)
name, version, body = mm.group(1), mm.group(2), mm.group(3)
lock = re.search(r'npmLockfile = \./(npm-locks/[^;]+);', body)
print('\t'.join([name, version, lock.group(1) if lock else '']))
PY
)
  local name version lockfile
  IFS=$'\t' read -r name version lockfile <<<"$m"

  # The dependency hash only exists as the answer to a failed build, so the
  # plugin is rebuilt with a deliberately wrong one and Nix is asked for the
  # value it expected instead. `overrideAttrs` is not enough: `npmDepsHash` is
  # read by the fetcher, so it goes through a plain rebuild of the plugin with
  # the lock's entry replaced.
  ( $NIX --extra-experimental-features 'nix-command flakes' build --impure --no-link --expr "
    let
      flake = builtins.getFlake \"path:$REPO\";
      pkgs = flake.inputs.nixpkgs.legacyPackages.\${builtins.currentSystem};
      # A stub lock: every hash wrong, so every fetcher reports the real one.
      stubLock = (pkgs.writeText \"stub-lock.json\" (builtins.toJSON {
        version = 1;
        plugins = { \"$key\" = {
          # The tarball hash is already known, so only the dependency store is
          # wrong and the fetcher that fails is the one this function wants.
          hash = \"$tarball\";
          npmDepsHash = \"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\";
        }; };
      }));
      plugins = import ./plugins.nix {
        inherit pkgs;
        deepseek-harnix = flake.inputs.deepseek-harnix;
        lockPath = stubLock;
      };
    in plugins.\"$key\"" 2>&1 || true) |
    # The failure chain reports the tarball hash first and the dependency-store
    # hash for the build that consumed it second; the last one is `npmDepsHash`.
    sed -n 's/^ *got: *\(sha256-[A-Za-z0-9+/=]*\).*/\1/p' | tail -1
}

work=$(mktemp)
trap 'rm -f "$work"' EXIT
changed=0
stale=0

printf '{\n  "version": 1,\n  "plugins": {\n' >"$work"
first=1
while IFS=$'\t' read -r key name version has_lock; do
  [ -n "$key" ] || continue
  printf '  %s "%s": {\n' "$([ $first -eq 1 ] && echo '' || echo ',')" "$key" >>"$work"
  first=0
  # The tarball hash is cheap to recompute, so `--check` compares it. The
  # dependency-store hash costs a full Nix build per plugin, so `--check` only
  # verifies it is present (a version bump without a refresh shows up as a
  # stale `hash` here, or as a build failure naming the expected value).
  h=$(tarball_hash "$name" "$version") || { echo "failed: $key" >&2; exit 1; }
  if [ "$CHECK" -eq 1 ]; then
    recorded=$(python3 -c "
import json,sys
print(json.load(open('$LOCK'))['plugins'].get('$key', {}).get('hash', ''))" )
    if [ "$recorded" != "$h" ]; then
      printf '  %-22s tarball hash is stale\n    recorded: %s\n    expected: %s\n' \
        "$key" "${recorded:-<missing>}" "$h" >&2
      stale=$((stale + 1))
    fi
    if [ "$has_lock" = yes ]; then
      dep=$(python3 -c "
import json
print(json.load(open('$LOCK'))['plugins'].get('$key', {}).get('npmDepsHash', ''))" )
      if [ -z "$dep" ]; then
        printf '  %-22s npmDepsHash missing; run update-lock.sh\n' "$key" >&2
        stale=$((stale + 1))
      fi
    fi
    continue
  fi
  printf '    "hash": "%s"' "$h" >>"$work"
  if [ "$has_lock" = yes ]; then
    printf ',\n' >>"$work"
    d=$(deps_hash "$key" "$h") || { echo "failed deps: $key" >&2; exit 1; }
    printf '    "npmDepsHash": "%s"' "$d" >>"$work"
  fi
  printf '\n  }' >>"$work"
done < <(read_declarations)

printf '\n  }\n}\n' >>"$work"

if [ "$CHECK" -eq 1 ]; then
  if [ "$stale" -ne 0 ]; then
    printf '\n%d lock entr%s out of date; run ./update-lock.sh\n' \
      "$stale" "$([ "$stale" -eq 1 ] && echo y || echo ies)" >&2
    exit 1
  fi
  echo "lock is up to date"
  exit 0
fi

# tui is source-based, not npm-based; its hashes are not recomputed here
# because they only change when the pinned commit does (edit them in the lock
# when you change `rev` in plugins.nix).
python3 - "$work" "$LOCK" <<'PY'
import json, sys
new = json.load(open(sys.argv[1]))
old = json.load(open(sys.argv[2]))
tui = old['plugins'].get('tui')
if tui:
    new['plugins']['tui'] = tui
with open(sys.argv[2], 'w') as f:
    json.dump(new, f, indent=2)
    f.write('\n')
print("wrote", sys.argv[2], "with", len(new['plugins']), "entries")
PY
