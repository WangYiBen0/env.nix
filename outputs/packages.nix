{
  myLib,
  pkgsFor,
  forAllSystems,
  ...
}:

forAllSystems (
  system:
  let
    pkgs = pkgsFor system;
    selfPackages = myLib.packagesFromByName {
      inherit (pkgs) callPackage;
      directory = ../pkgs/by-name;
    };
  in
  selfPackages // { inherit (pkgsFor system) niri xwayland-satellite; }
)
