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

      wineWow64Packages.waylandFull
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
          # No gtk2/gtk2-x11: upstream marks GTK 2 broken and drops it in
          # NixOS 27.05, and nix-ld's job here is running current AppImages --
          # a title still linking libgtk-x11-2.0 is not worth pinning a
          # removed library into every system closure for.
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
