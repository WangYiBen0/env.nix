{
  lib,
  config,
  ...
}:

lib.mkIf config.machine.modules.nix-index.enable {
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;
}
