{
  imports = [
    ../../../../../modules/home
  ];

  machine.profiles.desktop = true;

  home.stateVersion = import ./state-version.nix;
}
