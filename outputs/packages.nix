{
  nixpkgs,
  pkgsFor,
  forAllSystems,
  ...
}:

forAllSystems (
  system:
  let
    pkgs = pkgsFor system;
    allPackages = nixpkgs.lib.filesystem.packagesFromDirectoryRecursive {
      inherit (pkgs) callPackage;
      directory = ../pkgs;
    };
  in
  allPackages
  // {
    inherit (allPackages.fonts) lxgw-neozhisong lxgw-zhenkai zhuque-fangsong;
    inherit (allPackages.agent) miyu;
  }
)
