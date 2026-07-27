{
  nixpkgs,
  pkgsFor,
  forAllSystems,
  ...
}:

forAllSystems (
  system:
  nixpkgs.lib.filesystem.packagesFromDirectoryRecursive {
    inherit (pkgsFor system) callPackage;
    directory = ../pkgs;
  }
)
