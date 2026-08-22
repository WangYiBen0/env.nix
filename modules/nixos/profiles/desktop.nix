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
      dae.enable = true;
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
      hyprland.enable = true;
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
        qq
        telegram-desktop

        noctalia-shell
        fuzzel
        swaylock
        kdePackages.plasma-browser-integration
        kdePackages.partitionmanager
        gnome-tweaks
        libreoffice-qt
        inkscape
        hmcl
        olympus

        chromium
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
