{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.machine.modules.dae.enable {
    services = {
      daed = {
        enable = true;
        package = pkgs.daed;
        openFirewall = {
          enable = true;
          port = 12345;
        };
      };
    };
  };
}
