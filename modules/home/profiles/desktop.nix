{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.machine.profiles.desktop {
    machine.modules = {
      niri.enable = true;
      kitty.enable = true;
      font.enable = true;
      ime.enable = true;
      launcher.enable = true;
      theme.enable = true;
      directory.enable = true;
      variable.enable = true;
    };

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
    };
  };
}
