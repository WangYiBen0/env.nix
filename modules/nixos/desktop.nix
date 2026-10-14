{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf config.machine.modules.desktop.enable {
  services = {
    displayManager = {
      plasma-login-manager.enable = true;
      defaultSession = "niri";
    };
    desktopManager.plasma6.enable = true;
  };

  programs = {
    firefox.enable = true;
    niri.enable = true;

    steam = {
      enable = true;
      protontricks.enable = true;
      extest.enable = true;
    };

    vscode.enable = true;
    gamescope.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      linuxqq
      dingtalk
      telegram-desktop

      fuzzel
      swaylock
      kdePackages.plasma-browser-integration
      kdePackages.partitionmanager
      gnome-tweaks
      libreoffice-qt
      inkscape

      chromium
    ];

    plasma6.excludePackages = with pkgs.kdePackages; [
      dolphin
      konsole
      kate
    ];

    variables = {
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
      GLFW_IM_MODULE = "ibus";
      INPUT_METHOD = "fcitx";
    };
  };

  # What may pass the firewall is a desktop decision, not base
  # infrastructure (modules/nixos/services.nix only turns the firewall on):
  # the proxy TUN interface and the Minecraft port.
  networking.firewall = {
    allowedTCPPorts = [ 25565 ];
    allowedUDPPorts = [ 25565 ];

    trustedInterfaces = [ "Mihomo" ];

    extraReversePathFilterRules = ''
      iifname "Mihomo" accept
    '';
  };
}
