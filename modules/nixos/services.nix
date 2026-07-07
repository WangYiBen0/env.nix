{
  services = {
    printing.enable = true;

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    openssh.enable = true;

    blueman.enable = true;

    kmscon.enable = true;

    btrfs.autoScrub = {
      enable = true;
    };
  };

  hardware.bluetooth.enable = true;

  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 25565 ];
      allowedUDPPorts = [ 25565 ];

      trustedInterfaces = [ "Mihomo" ];
      extraReversePathFilterRules = ''
        iifname "Mihomo" accept
      '';
    };
  };

  systemd.services."kmsconvt@tty1".enable = false;
}
