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
    inherit (pkgsFor system)
      aquamarine
      hyprland
      hyprlang
      hyprcursor
      hyprgraphics
      hyprland-protocols
      hyprutils
      hyprwayland-scanner
      hyprwire
      udis86-hyprland
      xdg-desktop-portal-hyprland
      niri
      xwayland-satellite
      ;
  }
)
