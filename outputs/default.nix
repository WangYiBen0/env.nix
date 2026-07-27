{
  self,
  nixpkgs,
  git-hooks,
  ...
}@inputs:
let
  myLib = import ../lib/default.nix nixpkgs.lib;
  allSystems = myLib.listSubDir ./.;
  forAllSystems = func: (nixpkgs.lib.genAttrs allSystems func);

  pkgsFor =
    system:
    import nixpkgs {
      inherit system;
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
