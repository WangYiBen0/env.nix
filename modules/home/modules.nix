{ inputs, ... }: {
  imports = with inputs; [
    catppuccin.homeModules.catppuccin
    nix-index-database.homeModules.nix-index
    nixvim.homeModules.nixvim
    zen-browser.homeModules.beta
  ];
}
