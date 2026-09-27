{ pkgs, ... }: {
  home.packages = with pkgs; [
    progress
  ];

  programs = {
    btop.enable = true;
    cava.enable = true;
    delta.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fd.enable = true;
    fzf.enable = true;
    gh.enable = true;
    jq.enable = true;
    nh.enable = true;

    nix-your-shell = {
      enable = true;
      nix-output-monitor.enable = true;
    };

    ripgrep.enable = true;
    ripgrep-all.enable = true;
    uv.enable = true;
  };

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
