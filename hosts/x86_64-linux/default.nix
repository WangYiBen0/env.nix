{ nixpkgs, system, ... }@args:
let
  inherit (nixpkgs) lib;
  myLib = import ../../lib nixpkgs.lib;
  hosts = myLib.listSubDir ./.;
  # inputs 是 flake 传入的全部 inputs（不包含我们自己加的 system）
  inputs = removeAttrs args [ "system" ];
in
lib.genAttrs hosts (
  hostname:
  lib.nixosSystem {
    inherit system;
    specialArgs = args // {
      inherit hostname myLib inputs;
    };
    modules = [
      (./. + "/${hostname}")
      ../../modules/common
      ../../modules/nixos
    ];
  }
)
