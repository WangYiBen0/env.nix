{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:

lib.mkIf config.machine.modules.desktop.enable {
  home.packages =
    (with pkgs; [
      bluetui
      libreoffice-qt
      miyu
      dsh-tui
      nemo-with-extensions
      osu-lazer-bin
      spotify-spotx
      cele-mod
    ])
    ++ [
      # nixpkgs' ironbar (0.19.1) does not build: its cargo build sets
      # LIBGIT2_NO_VENDOR but the derivation has no libgit2 in its buildInputs,
      # so libgit2-sys aborts with "no compatible system libgit2 could be
      # found". Upstream's own flake builds fine, so take the package from
      # there instead of waiting for the nixpkgs fix.
      inputs.ironbar.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  programs = {
    bun.enable = true;
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
