_inputs: _final: prev:
let
  allPackages = prev.lib.filesystem.packagesFromDirectoryRecursive {
    inherit (prev) callPackage;
    directory = ../pkgs;
  };
  fontPackages = allPackages.fonts or { };
in
allPackages // fontPackages
