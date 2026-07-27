{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.machine.profiles.desktop = lib.mkEnableOption "desktop environment";

  config = lib.mkIf config.machine.profiles.desktop {
    home.packages = with pkgs; [
      bluetui
      ironbar
      libreoffice-qt6-fresh
      miyu
      nemo-with-extensions
      osu-lazer-bin
      opencode
    ];

    programs = {
      zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
      };
    };

    services = {
      swaync.enable = true;
      polkit-gnome.enable = true;
    };
  };
}
