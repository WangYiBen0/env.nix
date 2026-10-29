{ lib, ... }: {
  imports = [
    ./bootloader.nix
    ./disko.nix
    ./hardware.nix
    ./users
    ./home.nix
  ];

  machine = {
    profiles.desktop = true;
  };
  systemd.services.honk-core.wantedBy = lib.mkForce [ ];

  networking.hostName = import ./hostname.nix;
  system.stateVersion = import ./state-version.nix;
}
