pkgs: directory:
let
  allPackages = pkgs.lib.filesystem.packagesFromDirectoryRecursive {
    inherit (pkgs) callPackage;
    inherit directory;
  };
  fontPackages = allPackages.fonts or { };
in
allPackages // fontPackages
