{ self, ... }:
{
  imports = [
    self.inputs.catppuccin.homeModules.catppuccin
    self.inputs.nix-index-database.homeModules.nix-index
    self.inputs.nixvim.homeModules.nixvim
    self.inputs.zen-browser.homeModules.beta
  ]
  ++ (self.lib.scanNixFiles ./.);
}
