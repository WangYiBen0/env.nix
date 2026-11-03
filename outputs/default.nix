{
  self,
  nixpkgs,
  git-hooks,
  ...
}@inputs:
let
  myLib = import ../lib/default.nix {
    inherit (nixpkgs) lib;
  };
  allSystems = myLib.listSubDir ./.;
  forAllSystems = func: (nixpkgs.lib.genAttrs allSystems func);

  pkgsFor =
    system:
    import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        # `gtk+` (gtk2) is marked broken upstream — its last release was
        # December 2020 and NixOS 27.05 drops it — and `dingtalk` still links
        # against it. At the default setting, evaluating that package is
        # refused outright, which kills both the flake outputs and the update
        # bot. Downgrade that one problem to a warning; every other broken
        # package still fails loudly.
        problems.handlers."gtk+".broken = "warn";
      };
      overlays = [ (import ../overlays inputs) ];
    };

  hosts = import ../hosts inputs;

  args = {
    inherit
      self
      nixpkgs
      git-hooks
      inputs
      myLib
      allSystems
      forAllSystems
      pkgsFor
      hosts
      ;
  };
in
{
  formatter = import ./formatter.nix args;
  checks = import ./checks.nix args;
  devShells = import ./devShells.nix args;
  packages = import ./packages.nix args;

  lib = myLib;
  overlays.default = import ../overlays inputs;
  inherit (hosts) nixosConfigurations homeConfigurations;
}
