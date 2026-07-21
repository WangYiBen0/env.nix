{ config, lib, ... }:
lib.mkIf config.machine.profiles.desktop {
  programs.fuzzel = {
    enable = true;
  };
}
