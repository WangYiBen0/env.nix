{
  lib,
  config,
  ...
}:

lib.mkIf config.machine.modules.nix.enable {
  programs.home-manager.enable = true;
}
