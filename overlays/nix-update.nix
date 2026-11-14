_inputs: _final: prev:
let
  # nix-update evaluates a local flake by asking `nix flake metadata --json` for
  # the source store path (`get_flake_store_path` in nix_update/options.py) and
  # then hands that path to `builtins.getFlake`. Up to Nix 2.34 that path was
  # materialised as a side effect of the metadata call; Nix 2.35 dropped the
  # copy (NixOS/nix#15711), so the path is reported but never written and every
  # eval dies with:
  #
  #   error: opening file "/nix/store/...-source": No such file or directory
  #
  # In this repository that is what broke `Update pkgs`: the update script
  # nix-update builds for a package (`nix-update --flake`) is itself a
  # nix-update invocation, and that inner run rewrites the tree first and then
  # re-evaluates — on a path that no longer exists.
  #
  # Upstream master has the same code and 1.16.0 is the newest release, so
  # patch it here. The guard keys off the known-buggy version: when nixpkgs
  # bumps nix-update, re-check `get_flake_store_path` in options.py — if it
  # still returns the metadata path unchecked, move the patch to the new
  # version, otherwise this block can be deleted.
  nix-update =
    if prev.nix-update.version == "1.16.0" then
      prev.nix-update.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./nix-update-lazy-source.patch ];
      })
    else
      prev.nix-update;
in
{
  inherit nix-update;
}
