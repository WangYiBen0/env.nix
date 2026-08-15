{ inputs, ... }: {
  imports = with inputs; [
    # niri.homeModules.niri
    hyprland.homeManagerModules.default

    ../home
  ];
}
