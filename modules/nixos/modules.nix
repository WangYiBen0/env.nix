{ inputs, ... }: {
  imports = with inputs; [
    home-manager.nixosModules.home-manager
    preservation.nixosModules.preservation
    nixpak.nixosModules.default
    linuxqq-wayland-fix.nixosModules.default
  ];
}
