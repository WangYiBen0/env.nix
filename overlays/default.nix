# execute and import all overlay files in the current directory with the given args
args:
let
  lib = args.nixpkgs.lib;
in
map (f: (import (./. + "/${f}") args)) # execute and import the overlay file
  (
    builtins.attrNames (
      lib.attrsets.filterAttrs # find all overlay files in the current directory
        (name: type: (type == "regular") && (lib.strings.hasSuffix ".nix" name) && (name != "default.nix"))
        (builtins.readDir ./.)
    )
  )
