inputs: _final: prev:
let
  myLib = import ../lib/default.nix {
    inherit (inputs.nixpkgs) lib;
  };
in
myLib.packagesFromByName {
  inherit (prev) callPackage;
  directory = ../pkgs/by-name;
}
