{
  lib,
  config,
  ...
}:

lib.mkIf config.machine.modules.services.enable {
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

    btrfs.autoScrub.enable = true;
  };

  hardware.bluetooth.enable = true;

  security = {
    rtkit.enable = true;

    polkit = {
      enable = true;
      enablePkexecWrapper = true;
    };
  };

  # The firewall itself is base infrastructure; what may pass through it is a
  # per-profile decision — see modules/nixos/profiles/desktop.nix.
  networking.firewall.enable = true;

  systemd.services."kmsconvt@tty1".enable = false;
}
