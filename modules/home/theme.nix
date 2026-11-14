{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.machine.modules.theme;

  # GTK 4 and libadwaita read the colour scheme, not the theme name, so the same
  # palettes that the Qt/Kvantum side switches between are expressed as dconf keys
  # here. `org.gnome.desktop.interface` is served to every GTK 3 app by
  # `gdk_wayland_screen_get_setting` (gtk-3.24.52/gdk/wayland/gdkscreen-wayland.c:526)
  # and to GTK 4 through the `org.freedesktop.appearance` portal settings that the
  # GDK Wayland backend subscribes to (gdk/wayland/gdksettings-wayland.c:309), so
  # one write covers both toolkits.
  lightDarkScript = pkgs.writeShellScript "darkman-theme" ''
    set -eu

    mode="$1"
    case "$mode" in
      dark)
        gtk_theme="WhiteSur-Dark"
        icon_theme="WhiteSur-dark"
        color_scheme="prefer-dark"
        kvantum_theme="WhiteSurDark"
        ;;
      light)
        gtk_theme="WhiteSur-Light"
        icon_theme="WhiteSur-light"
        color_scheme="prefer-light"
        kvantum_theme="WhiteSur"
        ;;
      *)
        echo "darkman-theme: unknown mode '$mode'" >&2
        exit 1
        ;;
    esac

    ${lib.getExe pkgs.dconf} write /org/gnome/desktop/interface/color-scheme "'$color_scheme'"
    ${lib.getExe pkgs.dconf} write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'"
    ${lib.getExe pkgs.dconf} write /org/gnome/desktop/interface/icon-theme "'$icon_theme'"

    # Home Manager installs kvantum.kvconfig as a store symlink, so it cannot be
    # edited in place: write a real file next to it instead. Running applications
    # only read it at start-up, and the next `home-manager switch` restores the
    # symlink, after which the following transition rewrites it again.
    kvconfig="''${XDG_CONFIG_HOME:-$HOME/.config}/Kvantum/kvantum.kvconfig"
    if [ -f "$kvconfig" ]; then
      tmp="$(mktemp "$kvconfig.XXXXXX")"
      sed "s/^theme=.*/theme=$kvantum_theme/" "$kvconfig" > "$tmp"
      if ! grep -q "^theme=$kvantum_theme$" "$tmp"; then
        echo "darkman-theme: no theme= line in $kvconfig; Qt apps keep their current style" >&2
      fi
      mv -f "$tmp" "$kvconfig"
    else
      echo "darkman-theme: $kvconfig is missing; Qt apps keep their current style" >&2
    fi
  '';
in
lib.mkIf cfg.enable {
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
      # Only the initial value: the light/dark script below rewrites it at runtime.
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

    gtk3 = {
      extraConfig = {
        gtk-file-chooser-backend = "nemo";
      };
    };
    gtk4 = {
      # `gtk.gtk4.theme` is deprecated as of Home Manager 26.05 and would make it
      # write a `gtk.css` that imports one frozen variant, which fights the media
      # queries below. Set the theme name by hand instead: native GTK 4 apps still
      # honour it, libadwaita apps ignore it either way.
      #
      # Null is set explicitly rather than left to the default: hosts whose
      # `home.stateVersion` predates 26.05 still fall back to the legacy default
      # `config.gtk.theme`, which would put the frozen dark sheet above the
      # media-query one and leak dark colours into light mode on those hosts.
      theme = null;
      extraConfig = {
        gtk-theme-name = "WhiteSur-Dark";
        gtk-file-chooser-backend = "nemo";
      };

      # libadwaita ignores `gtk-theme-name` and only reads the user stylesheet, so
      # this is the only way in. `whitesur-libadwaita` ships the light and dark
      # palettes plus the assets they reference, and a `gtk.css` that selects one
      # with `@media (prefers-color-scheme: ...)`; GTK re-parses the sheet whenever
      # the colour scheme changes, so no file has to be rewritten at runtime.
      extraCss = ''
        @import url("file://${pkgs.whitesur-libadwaita}/share/whitesur-libadwaita/gtk.css");
      '';
    };
  };

  services.darkman = lib.mkIf cfg.lightDark.enable {
    enable = true;
    settings = {
      # Explicit coordinates instead of geoclue: geoclue would need its own
      # service and a permission prompt before the first transition.
      lat = cfg.lightDark.latitude;
      lng = cfg.lightDark.longitude;
      usegeoclue = false;
    };
    scripts.theme = lightDarkScript;
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
