{
  imports = [
    ../../../../../modules/common/options.nix
    ../../../../../modules/home
    ./extra-config
  ];

  machine.profiles.desktop = true;

  home.stateVersion = import ./state-version.nix;
}
