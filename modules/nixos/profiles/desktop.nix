{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.machine.profiles.desktop = lib.mkEnableOption "desktop environment";

  config = lib.mkIf config.machine.profiles.desktop {
    services = {
      displayManager.plasma-login-manager.enable = true;
      desktopManager.plasma6.enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    };

    programs = {
      hyprland.enable = true;
      niri.enable = true;

      firefox.enable = true;

      steam = {
        enable = true;
        protontricks = {
          enable = true;
        };
        extest = {
          enable = true;
        };
      };

      gamescope = {
        enable = true;
      };
    };

    environment = {
      systemPackages = with pkgs; [
        noctalia-shell
        fuzzel
        swaylock
        xwayland-satellite
        kdePackages.plasma-browser-integration
        kdePackages.partitionmanager
        gnome-tweaks
        libreoffice-qt
        inkscape
        hmcl
        olympus
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
