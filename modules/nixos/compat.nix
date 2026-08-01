{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.machine.modules.compat.enable {
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

          faudio
          fna3d
          fuse
          gtk2
          gtk2-x11
          gtk3
          gtk3-x11
          gtk4
          icu
          libgdiplus
          sdl3
          SDL2
        ]);
    };

    services.flatpak.enable = true;

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;
    };
  };
}
