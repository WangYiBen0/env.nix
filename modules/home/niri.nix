{ config, lib, ... }:

lib.mkIf config.machine.profiles.desktop {
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
}
