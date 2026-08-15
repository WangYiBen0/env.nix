_: {
  imports = [
    ./users
    ./bootloader.nix
    ./disko.nix
    ./hardware.nix
    ./home.nix
  ];

  machine.profiles.desktop = true;

  networking.hostName = import ./hostname.nix;
  system.stateVersion = import ./state-version.nix;
}
