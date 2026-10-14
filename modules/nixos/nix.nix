{
  lib,
  config,
  ...
}:

lib.mkIf config.machine.modules.nix.enable {
  nix.channel.enable = false;
}
