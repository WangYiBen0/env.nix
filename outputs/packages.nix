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
  {
    inherit (allPackages.fonts) lxgw-neozhisong lxgw-zhenkai zhuque-fangsong;
    inherit (allPackages.agent) miyu;
    inherit (pkgsFor system) hyprland niri xwayland-satellite;
  }
)
