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
      deepseek-harness
      dsh-tui
      nemo-with-extensions
      osu-lazer-bin
      spotify-spotx
    ];

    programs = {
      zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
      };
      opencode = {
        enable = true;
      };
      pi-coding-agent = {
        enable = true;
      };
    };

    services = {
      swaync.enable = true;
    };
  };
}
