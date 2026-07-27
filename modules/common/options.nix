{ lib, ... }:
{
  options.machine = {
    profiles = {
      desktop = lib.mkEnableOption "desktop environment";
      server = lib.mkEnableOption "server profile";
    };

    modules = {
      niri.enable = lib.mkEnableOption "niri window manager";
      kitty.enable = lib.mkEnableOption "kitty terminal";
      font.enable = lib.mkEnableOption "font configuration";
      ime.enable = lib.mkEnableOption "input method (fcitx5)";
      launcher.enable = lib.mkEnableOption "application launcher (fuzzel)";
      theme.enable = lib.mkEnableOption "desktop theme (GTK/Qt/catppuccin)";
      directory.enable = lib.mkEnableOption "XDG user directories";
      variable.enable = lib.mkEnableOption "desktop environment variables";
      compat.enable = lib.mkEnableOption "compatibility tools (nix-ld, flatpak, etc.)";
      dae.enable = lib.mkEnableOption "dae network proxy";
    };
  };
}
