{ lib, ... }:
{
  options.machine = {
    profiles = {
      desktop = lib.mkEnableOption "desktop environment";
      server = lib.mkEnableOption "server profile";
    };

    modules = {
      desktop.enable = lib.mkEnableOption "desktop environment bundle (plasma, niri session, desktop apps)";
      niri.enable = lib.mkEnableOption "niri window manager";
      kitty.enable = lib.mkEnableOption "kitty terminal";
      font.enable = lib.mkEnableOption "font configuration";
      ime.enable = lib.mkEnableOption "input method (fcitx5)";
      launcher.enable = lib.mkEnableOption "application launcher (fuzzel)";
      theme.enable = lib.mkEnableOption "desktop theme (GTK/Qt/catppuccin)";
      wallpaper = {
        enable = lib.mkEnableOption "static wallpaper for the niri session";
        backend = lib.mkOption {
          type = lib.types.enum [
            "wpaperd"
            "swaybg"
            "awww"
          ];
          default = "wpaperd";
          description = "lightweight wallpaper backend to start with the niri session";
        };
        image = lib.mkOption {
          type = lib.types.path;
          default = ../../wallpapers/scarlet-forest.png;
          description = "static wallpaper image; defaults to the repository wallpapers/ directory";
        };
      };
      directory.enable = lib.mkEnableOption "XDG user directories";
      variable.enable = lib.mkEnableOption "desktop environment variables";
      compat.enable = lib.mkEnableOption "compatibility tools (nix-ld, flatpak, etc.)";
      honk.enable = lib.mkEnableOption "honk network proxy";
      deepseek-harness.enable = lib.mkEnableOption "deepseek-harness web UI service";
      system.enable = lib.mkEnableOption "base system settings (kernel, timezone, locale, boot)";
      services.enable = lib.mkEnableOption "base system services (audio, SSH, bluetooth, printing)";
      packages.enable = lib.mkEnableOption "system and user packages";
      nix.enable = lib.mkEnableOption "nix settings, caches and garbage collection";
      shell.enable = lib.mkEnableOption "shell configuration (bash, fish, bat, eza, zellij)";
      starship.enable = lib.mkEnableOption "starship prompt";
      git.enable = lib.mkEnableOption "git configuration";
      editor.enable = lib.mkEnableOption "nixvim editor";
      yazi.enable = lib.mkEnableOption "yazi file manager";
      nix-index.enable = lib.mkEnableOption "nix-index with comma";
      nixpak.enable = lib.mkEnableOption "NixPak sandbox for the closed-source dingtalk client";
      impermanence.enable = lib.mkEnableOption "preservation of state onto the /persist subvolume (needs it to exist)";
    };
  };
}
