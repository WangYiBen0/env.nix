{ inputs, ... }: {
  imports = with inputs; [
    niri.homeModules.niri

    ../home
  ];
}
