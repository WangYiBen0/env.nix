{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf config.machine.modules.packages.enable {
  home.packages = with pkgs; [
    progress
    qrtool
    cloudflared
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

  # The graphical-session polkit agent lives in the desktop profile
  # (modules/home/profiles/desktop.nix) — it is a desktop feature, not base tooling.
}
