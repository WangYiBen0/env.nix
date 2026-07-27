{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.machine.modules.theme.enable {
  home.pointerCursor = {
    enable = true;
    name = "WhiteSur-cursors";
    package = pkgs.whitesur-cursors;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";

    kvantum = {
      enable = true;
      settings.General.theme = "WhiteSurDark";
      themes = with pkgs; [
        whitesur-kde
        whitesur-icon-theme
      ];
    };

    qt5ctSettings = {
      Appearance = {
        icons_theme = "WhiteSur-dark";
        style = "kvantum-dark";
      };
    };
    qt6ctSettings = {
      Appearance = {
        icons_theme = "WhiteSur-dark";
        style = "kvantum-dark";
      };
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };
    iconTheme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };

    gtk4 = {
      theme = config.gtk.theme;
    };
  };

  catppuccin = {
    enable = true;
    autoEnable = true;

    fcitx5 = {
      enableRounded = true;
    };

    cursors.enable = false;
    gtk.icon.enable = false;
    kvantum.enable = false;
  };
}
