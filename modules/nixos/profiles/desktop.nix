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
      font.enable = true;
      compat.enable = true;
      honk.enable = true;
    };

    services = {
      displayManager = {
        plasma-login-manager.enable = true;
        defaultSession = "niri";
      };
      desktopManager.plasma6.enable = true;
    };

    programs = {
      firefox.enable = true;
      niri.enable = true;

      steam = {
        enable = true;
        protontricks.enable = true;
        extest.enable = true;
      };

      vscode.enable = true;
      gamescope.enable = true;
    };

    environment = {
      systemPackages = with pkgs; [
        linuxqq
        dingtalk
        telegram-desktop

        fuzzel
        swaylock
        kdePackages.plasma-browser-integration
        kdePackages.partitionmanager
        gnome-tweaks
        libreoffice-qt
        inkscape

        chromium
      ];

      plasma6.excludePackages = with pkgs.kdePackages; [
        dolphin
        konsole
        kate
      ];

      variables = {
        XMODIFIERS = "@im=fcitx";
        SDL_IM_MODULE = "fcitx";
        GLFW_IM_MODULE = "ibus";
        INPUT_METHOD = "fcitx";
      };
    };
  };
}
