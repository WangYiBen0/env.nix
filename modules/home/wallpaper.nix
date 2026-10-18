{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.machine.modules.wallpaper;

  # niri itself draws no wallpaper: these layer-shell clients take an image
  # straight from the repository wallpapers/ directory (via the `image`
  # option) and cover every output with it.
  #
  # awww (swww's new name in nixpkgs) needs its daemon up before `awww img`
  # can talk to it, so the spawn polls the socket for a few seconds instead
  # of racing the daemon.
  spawnArgs = {
    swaybg = [
      (lib.getExe pkgs.swaybg)
      "-m"
      "fill"
      "-i"
      "${cfg.image}"
    ];
    awww = [
      "sh"
      "-c"
      "${lib.getExe' pkgs.awww "awww-daemon"} & for i in $(seq 1 50); do ${lib.getExe pkgs.awww} img -m fill ${cfg.image} && exit 0; sleep 0.1; done"
    ];
  };
in
lib.mkIf (config.machine.modules.niri.enable && cfg.enable) {
  wayland.windowManager.niri.settings._children = lib.optionals (cfg.backend != "wpaperd") [
    # A separate `spawn-at-startup` node so it merges with the existing one.
    { spawn-at-startup._args = spawnArgs.${cfg.backend}; }
  ];

  # wpaperd is the odd one out: it ships a systemd user service that
  # home-manager wires to graphical-session.target (niri.service binds to
  # that target), so it needs no spawn line and restarts on config changes.
  services.wpaperd = lib.mkIf (cfg.backend == "wpaperd") {
    enable = true;
    settings.default.path = "${cfg.image}";
  };
}
