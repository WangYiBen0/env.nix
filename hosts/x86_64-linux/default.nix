{
  nixpkgs,
  system,
  hmSharedModules,
  ...
}@args:
let
  inherit (nixpkgs) lib;
  myLib = import ../../lib nixpkgs.lib;
  hosts = myLib.listSubDir ./.;
  # inputs 是 flake 传入的全部 inputs（不包含我们自己加的 system 和 hmSharedModules）
  inputs = removeAttrs args [
    "system"
    "hmSharedModules"
  ];
in
lib.genAttrs hosts (
  hostname:
  lib.nixosSystem {
    inherit system;
    specialArgs = (removeAttrs args [ "hmSharedModules" ]) // {
      inherit hostname myLib inputs;
    };
    modules = [
      ./${hostname}
      ../../modules/common
      ../../modules/nixos
      ../../profiles
      # Inject the shared Home Manager stack (defined in hosts/default.nix)
      # into every user of every host.
      { home-manager.sharedModules = hmSharedModules; }
    ];
  }
)
