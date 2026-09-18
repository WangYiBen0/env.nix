{ inputs, ... }: {
  imports = with inputs; [
    hyprland.homeManagerModules.default

    ../home
  ];
}
