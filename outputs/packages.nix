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
    inherit (allPackages.agent) miyu deepseek-harness dsh-tui;
    inherit (allPackages.applications) dingtalk cele-mod loenn;
    inherit (pkgsFor system) niri xwayland-satellite;
  }
)
