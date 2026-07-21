# Merge all overlay files in this directory into a single overlay function.
# Usage: import ../overlays inputs → (final: prev: mergedAttrs)
inputs:
let
  lib = inputs.nixpkgs.lib;
  overlayFiles = builtins.attrNames (
    lib.attrsets.filterAttrs (
      name: type: (type == "regular") && (lib.strings.hasSuffix ".nix" name) && (name != "default.nix")
    ) (builtins.readDir ./.)
  );
  overlayList = map (f: import (./. + "/${f}") inputs) overlayFiles;
in
final: prev: builtins.foldl' (acc: o: acc // (o final prev)) { } overlayList
