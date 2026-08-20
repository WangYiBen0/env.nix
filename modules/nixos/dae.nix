{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.daeuniverse.nixosModules.daed
  ];

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
