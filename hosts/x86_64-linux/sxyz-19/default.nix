_: {
  imports = [
    ./bootloader.nix
    ./disko.nix
    ./hardware.nix
    ./users
    ./home.nix
  ];

  machine.profiles.desktop = true;

  networking.hostName = import ./hostname.nix;
  system.stateVersion = import ./state-version.nix;
}
