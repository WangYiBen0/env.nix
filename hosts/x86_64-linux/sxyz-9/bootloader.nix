{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        xbootldrMountPoint = "/boot";
        configurationLimit = 20;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/efi";
      };
    };
  };
}
