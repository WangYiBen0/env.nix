_: {
  imports = [
    ./bootloader.nix
    ./hardware-configuration.nix
    ./home.nix
  ];

  machine.profiles.desktop = true;

  networking.hostName = import ./hostname.nix;
  system.stateVersion = import ./state-version.nix;
}
