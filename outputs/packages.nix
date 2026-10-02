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
    inherit (allPackages.agents) deepseek-harness dsh-tui miyu;
    inherit (allPackages.applications)
      cele-mod
      dingtalk
      linuxqq
      loenn
      ;
    inherit (pkgsFor system) niri xwayland-satellite;
  }
)
