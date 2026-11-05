{
  myLib,
  pkgsFor,
  forAllSystems,
  nixpkgs,
  ...
}:

forAllSystems (
  system:
  let
    pkgs = pkgsFor system;
    inherit (nixpkgs) lib;

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

    # The by-name tree is Linux-first (niri helpers, Wayland tools, X11-only
    # apps) and evaluating one of those on Darwin throws "unsupported system"
    # rather than being merely absent, which would poison `nix flake check`
    # and every `nix build .#<TAB>` on a Mac.  Drop what this platform cannot
    # build; `meta.platforms` is the authority, so nothing else has to know
    # about Darwin.
    buildable = lib.filterAttrs (_: p: lib.meta.availableOn pkgs.stdenv.hostPlatform p) selfPackages;

    fromNixpkgs = lib.filterAttrs (_: p: lib.meta.availableOn pkgs.stdenv.hostPlatform p) {
      inherit (pkgs)
        niri
        xwayland-satellite
        zen-browser
        zen-browser-beta
        zen-browser-twilight
        osu-lazer-bin
        ;
    };
  in
  buildable // fromNixpkgs
)
