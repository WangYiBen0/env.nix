{
  lib,
  config,
  ...
}:

lib.mkIf config.machine.profiles.desktop {
  machine.modules = {
    # Feature bundles
    desktop.enable = true;
    compat.enable = true;
    honk.enable = true;

    # NixOS base
    system.enable = true;
    services.enable = true;
    packages.enable = true;
    nix.enable = true;

    # Home base
    shell.enable = true;
    starship.enable = true;
    git.enable = true;
    editor.enable = true;
    yazi.enable = true;
    nix-index.enable = true;

    # Desktop modules
    niri.enable = true;
    kitty.enable = true;
    font.enable = true;
    ime.enable = true;
    launcher.enable = true;
    theme.enable = true;
    wallpaper.enable = true;
    directory.enable = true;
    variable.enable = true;
    deepseek-harness.enable = true;
  };
}
