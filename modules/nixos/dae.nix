{
  inputs,
  config,
  lib,
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
        openFirewall = {
          enable = true;
          port = 12345;
        };
      };
    };
  };
}
