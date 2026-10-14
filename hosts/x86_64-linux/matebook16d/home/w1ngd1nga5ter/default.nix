{
  imports = [
    ./extra-config
  ];

  machine.profiles.desktop = true;

  home.stateVersion = import ./state-version.nix;
}
