{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf config.machine.modules.desktop.enable {
  home.packages = with pkgs; [
    bluetui
    ironbar
    libreoffice-qt
    miyu
    # deepseek-harness comes in through programs.dsh.package
    # (modules/home/deepseek-harness/); listing it here too would put two
    # versions in home-manager-path and buildEnv refuses conflicting bin/dsh.
    dsh-tui
    nemo-with-extensions
    osu-lazer-bin
    spotify-spotx
    hmcl
    cele-mod
  ];

  programs = {
    zen-browser = {
      enable = true;
      setAsDefaultBrowser = true;
    };
    opencode.enable = true;
  };

  services.swaync.enable = true;

  # Graphical-session polkit agent (moved out of modules/home/packages.nix).
  systemd.user.services.polkit-kde-authentication-agent-1 = {
    Unit = {
      Description = "polkit-kde-authentication-agent-1";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
