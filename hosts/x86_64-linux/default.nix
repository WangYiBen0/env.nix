{
  nixpkgs,
  system,
  hmSharedModules,
  ...
}@args:
let
  inherit (nixpkgs) lib;
  # inputs 是 flake 传入的全部 inputs（不包含我们自己加的 system 和 hmSharedModules）
  inputs = removeAttrs args [
    "system"
    "hmSharedModules"
  ];
  myLib = import ../../lib {
    inherit lib;
    haumea = inputs.haumea.lib;
  };
  hosts = myLib.listSubDir ./.;
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
# The rescue image is a NixOS system too, just one without a host directory:
# livecd.nix is a module file next to them, so `listSubDir` above never sees
# it. Keeping it here (rather than in a separate flake output) means
# `nix flake check` understands it and `nixos-anywhere --flake .#livecd` works,
# and both artefacts hang off the config instead of a private output:
#   nix build .#nixosConfigurations.livecd.config.system.build.isoImage
#   nix build .#nixosConfigurations.livecd.config.system.build.vm
// {
  livecd = lib.nixosSystem {
    inherit system;
    # Same argument set as the hosts: the shared modules read `self`, `myLib`
    # and `inputs` (see modules/common/default.nix and modules/nixos/default.nix).
    specialArgs = (removeAttrs args [ "hmSharedModules" ]) // {
      hostname = "livecd";
      inherit myLib inputs;
    };
    modules = [ ./livecd.nix ];
  };
}
