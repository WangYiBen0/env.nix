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

  # On this host the swapfile shares one spinning disk with everything else, so
  # an evicted page is a seek. Measured: fcitx5 held 26 MiB in swap against
  # 15 MiB resident, and rime_ice.table.bin alone is 58 MiB that must be read
  # back on the first keystroke after the IME starts — that is the "cold input"
  # stall. The IME is small and needed on every keystroke, so forbid swapping it
  # out and let the kernel always keep it resident. MemoryMax stays unset so it
  # can never be OOM-killed; only its swap is pinned.
  systemd.user.services.fcitx5-daemon.Service.MemorySwapMax = "0";
}
