# The third-party dsh plugins of the `web` profile, packaged by
# deepseek-harnix's `mkDshPlugin`.
#
# This file declares *what* the plugins are — npm name, version, and where the
# source comes from. The hashes are in `dsh-plugins.lock.json`, next to it,
# because they are machine-generated: bumping a version means regenerating
# them, not hand-editing this file.
#
#   nix run .#dsh-plugin-lock        # or ./update-lock.sh
#
# The generator resolves every entry below, reports any hash that changed or
# appeared, and rewrites the lock. A version bump without a lock refresh fails
# loudly at build time with the hash Nix expected, which is the intended
# workflow: change the version here, run the tool, commit both.
#
# Every plugin here ships its compiled `lib/` in the published tarball, so the
# registry hash is the only fetch input. The ones that declare runtime
# dependencies also carry a lockfile from `npm-locks/`, which is what lets the
# Nix build resolve the dependency tree offline.
{
  deepseek-harnix,
  pkgs,
  lib ? pkgs.lib,
  lockPath ? ./dsh-plugins.lock.json,
}:

let
  # deepseek-harnix exposes the builder as `lib.mkDshPlugin`, bound to the
  # evaluating system.
  mk = args: deepseek-harnix.lib.mkDshPlugin args;

  # `lockPath` is overridable so the lock generator can rebuild an entry
  # against a stub lock and read the hash Nix reports.
  lock = builtins.fromJSON (builtins.readFile lockPath);

  # A missing lock entry is a configuration error with a fix, not a build
  # failure somewhere deep in a fetch.
  forPlugin =
    key:
    lock.plugins.${key} or (throw ''
      dsh-plugins.lock.json has no entry for "${key}";
      run ./update-lock.sh to generate it'');

  # npm-published plugin: name + version here, hashes from the lock. A plugin
  # that resolves dependencies offline adds its npm lockfile, which supplies
  # `npmDepsHash` alongside.
  fromNpm =
    key: npmName: npmVersion: extra:
    let
      entry = forPlugin key;
    in
    mk (
      {
        inherit npmName npmVersion;
        inherit (entry) hash;
      }
      // lib.optionalAttrs (extra ? npmLockfile) {
        inherit (entry) npmDepsHash;
      }
      // extra
    );

  tuiPinned = forPlugin "tui";
in
{
  archive-manager = fromNpm "archive-manager" "@michengai/dsh-archive-manager" "1.1.6" { };

  opencode2dsh = fromNpm "opencode2dsh" "@opencode2dsh/dsh-plugin" "0.3.13" {
    npmLockfile = ./npm-locks/opencode2dsh.package-lock.json;
  };

  dsh-im = fromNpm "dsh-im" "@xmanrui/dsh-im" "5.6.0" {
    npmLockfile = ./npm-locks/xmanrui-dsh-im.package-lock.json;
  };

  background-by-model = fromNpm "background-by-model" "dsh-background-by-model" "0.7.5" {
    npmLockfile = ./npm-locks/dsh-background-by-model.package-lock.json;
  };

  chat-import = fromNpm "chat-import" "dsh-chat-import" "0.26.1" {
    npmLockfile = ./npm-locks/dsh-chat-import.package-lock.json;
  };

  free-search = fromNpm "free-search" "dsh-free-search" "0.9.6" {
    npmLockfile = ./npm-locks/dsh-free-search.package-lock.json;
  };

  pocket = fromNpm "pocket" "dsh-pocket" "2.12.0" {
    npmLockfile = ./npm-locks/dsh-pocket.package-lock.json;
  };

  market = fromNpm "market" "dshmarket" "1.66.42" {
    npmLockfile = ./npm-locks/dshmarket.package-lock.json;
  };

  # No runtime dependencies: nothing to resolve, so no npm lockfile.
  ops = fromNpm "ops" "dsh-ops" "0.3.2" { };
  tool-normalizer = fromNpm "tool-normalizer" "dsh-tool-normalizer" "0.5.2" { };
  whale-widget = fromNpm "whale-widget" "dsh-whale-widget" "0.4.2" { };

  # dsh-tui is the only plugin built from source: upstream publishes no
  # tarball of the compiled package, only the repository. It is a pnpm
  # workspace whose build also installs `vendor/dsh-std` (a git submodule with
  # its own lockfile), hence the nested store; `compile` rather than `build`,
  # because `build` ends in a verification harness that expects a live dsh
  # installation.
  #
  # Fetched by commit: the submodule requirement rules out `fetchzip`, and a
  # moving branch would defeat the point of pinning.
  tui =
    let
      source = pkgs.fetchgit {
        url = "https://github.com/ccch1mneyyy/dsh-TUI.git";
        rev = "1056facc4e9bb572565a7e42fa5046e11d6eadb7";
        fetchSubmodules = true;
        hash = tuiPinned.sourceHash;
      };
    in
    mk {
      inherit source;
      inherit (tuiPinned) pnpmDepsHash;
      nestedPnpmDeps = pkgs.fetchPnpmDeps {
        pname = "dsh-tui-nested-store";
        version = "0";
        src = source;
        pnpm = pkgs.pnpm_11;
        fetcherVersion = 4;
        hash = tuiPinned.nestedPnpmDepsHash;
      };
      nestedPnpmDir = "vendor/dsh-std";
      autoInstallPeers = true;
      npmBuildScript = "compile";
    };
}
