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
    # Packages auto-update through nix-update, whose updateScript re-invokes
    # nix-update without --flake — and that inner call cannot eval this
    # repository (the root default.nix is a flake-compat shim, not a callable
    # pkgs set). Inject the flag here instead of repeating it in every
    # package's updateScript.
    selfPkgs = pkgs.extend (
      _final: prev: {
        nix-update-script =
          args@{
            extraArgs ? [ ],
            ...
          }:
          prev.nix-update-script (
            args // { extraArgs = [ "--flake" ] ++ builtins.filter (arg: arg != "--flake") extraArgs; }
          );
      }
    );

    selfPackages = myLib.packagesFromByName {
      inherit (selfPkgs) callPackage;
      directory = ../pkgs/by-name;
    };
  in
  selfPackages
  // {
    inherit (pkgsFor system)
      niri
      xwayland-satellite
      zen-browser
      zen-browser-beta
      zen-browser-twilight
      osu-lazer-bin
      ;
  }
)
