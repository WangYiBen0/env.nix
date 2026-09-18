{ inputs, ... }: {
  imports = with inputs; [
    home-manager.nixosModules.home-manager
    daeuniverse.nixosModules.daed
  ];
}
