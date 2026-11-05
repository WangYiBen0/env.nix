{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.machine.modules.nixpak;

  # Baseline every sandboxed app gets: the pieces a desktop app needs to be
  # usable — Wayland (plus Xwayland for the X11-only ones), audio, GPU, fonts,
  # locale, TLS roots — and the narrow D-Bus surface that notifications, file
  # pickers, the tray and the fcitx IME go through. Note what is absent: the
  # app cannot see the real home directory, the session bus beyond these
  # policies, or any host configuration.
  desktopSandbox = _: {
    gpu = {
      enable = true;
      provider = "nixos";
    };
    fonts.enable = true;
    locale.enable = true;
    timeZone.enable = true;
    etc.sslCertificates.enable = true;

    bubblewrap = {
      network = true;
      sockets = {
        wayland = true;
        x11 = true;
        pipewire = true;
        pulse = true;
      };
    };

    dbus.policies = {
      "org.freedesktop.DBus" = "talk";
      "org.freedesktop.Notifications" = "talk";
      "org.freedesktop.portal.Desktop" = "talk";
      "org.freedesktop.portal.Documents" = "talk";
      "org.freedesktop.portal.Fcitx" = "talk";
      "org.fcitx.Fcitx5" = "talk";
      "org.kde.StatusNotifierWatcher" = "talk";
      "ca.desrt.dconf" = "talk";
      "org.gtk.vfs" = "talk";
      "org.gtk.vfs.*" = "talk";
    };
  };

  # The sandboxed app gets a private home instead of the real one: it is
  # closed source and freely rummages through `$HOME`, so the sandbox hands
  # it a dedicated directory that survives rebuilds. The real `~/Downloads`
  # stays writable so received files land where the user expects them.
  privateHome = sloth: app: [
    [
      (sloth.mkdir (sloth.concat' sloth.homeDir "/.local/share/nixpak/${app}"))
      sloth.homeDir
    ]
    (sloth.mkdir sloth.xdgDownloadDir)
  ];
in
{
  config = lib.mkIf cfg.enable {
    security.nixpak = {
      enable = true;
      defaults = desktopSandbox;

      apps = {
        dingtalk.configuration =
          { sloth, ... }:
          {
            app.package = pkgs.dingtalk;
            flatpak.appId = "com.alibabainc.dingtalk";
            bubblewrap.bind.rw = privateHome sloth "dingtalk-home";
          };
      };
    };
  };
}
