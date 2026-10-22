_: {
  imports = [
    ./users
    ./bootloader.nix
    ./disko.nix
    ./hardware.nix
    ./home.nix
  ];

  machine.profiles.desktop = true;

  # Guinea pig for the ephemeral-root setup. The state list lives in
  # modules/nixos/preservation.nix; the mount comes from disko. Create the
  # subvolume and seed it before the first switch (see modules/README.md).
  machine.modules.impermanence.enable = true;

  networking.hostName = import ./hostname.nix;
  system.stateVersion = import ./state-version.nix;
}
