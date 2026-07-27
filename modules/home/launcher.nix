{ config, lib, ... }:
lib.mkIf config.machine.modules.launcher.enable {
  programs.fuzzel = {
    enable = true;
  };
}
