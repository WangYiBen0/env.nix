{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 20;
      memtest86.enable = true;
      netbootxyz.enable = true;
    };
    efi = {
      canTouchEfiVariables = true;
    };
  };
}
