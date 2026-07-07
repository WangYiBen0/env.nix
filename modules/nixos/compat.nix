{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.machine.profiles.desktop {
    environment.systemPackages = with pkgs; [
      patchelf
      appimage-run
      steam-run

      distrobox

      wine-staging
      winetricks

      mono
    ];

    programs.nix-ld = {
      enable = true;
      libraries =
        (pkgs.appimage-run.args.multiPkgs pkgs)
        ++ (with pkgs; [
          stdenv.cc.cc

          fuse
          icu
          libgdiplus
          gtk2-x11
        ]);
    };

    services.flatpak.enable = true;

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
  };
}
