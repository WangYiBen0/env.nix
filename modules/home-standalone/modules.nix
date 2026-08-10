{ inputs, ... }: {
  imports = with inputs; [
    niri.homeModules.niri
    hyprland.homeModules.default

    ../home
  ];
}
