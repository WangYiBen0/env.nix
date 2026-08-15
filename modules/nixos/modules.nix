{ inputs, ... }: {
  imports = with inputs; [
    home-manager.nixosModules.home-manager
    hyprland.nixosModules.default
    # niri.nixosModules.niri
  ];
}
