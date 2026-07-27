{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.machine.modules.ime.enable {
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5 = {
      addons = with pkgs; [
        fcitx5-gtk
        libsForQt5.fcitx5-qt
        kdePackages.fcitx5-qt
        (fcitx5-rime.override {
          rimeDataPkgs = with pkgs; [
            rime-ice
          ];
        })
        qt6Packages.fcitx5-configtool
        catppuccin-fcitx5
      ];
      waylandFrontend = true;
    };
  };

  home.file."./.local/share/fcitx5/rime/default.custom.yaml".text = ''
    patch:
      __include: rime_ice_suggestion:/
  '';
}
