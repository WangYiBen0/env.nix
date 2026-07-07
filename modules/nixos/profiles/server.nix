{ lib, ... }:
{
  options.machine.profiles.server = lib.mkEnableOption "server profile";
}
