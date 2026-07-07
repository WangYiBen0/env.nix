{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "usb_storage"
      "sd_mod"
      "rtsx_pci_sdmmc"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];
    kernelParams = [
      "zswap.enabled=1" # enables zswap
      "zswap.compressor=zstd" # compression algorithm
      "zswap.zpool=z3fold"
      "zswap.max_pool_percent=20" # maximum percentage of RAM that zswap is allowed to use
      "zswap.shrinker_enabled=1" # whether to shrink the pool proactively on high memory pressure
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/8460766a-baec-49ac-89ea-156c59bffd97";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "compress=zstd"
      ];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/8460766a-baec-49ac-89ea-156c59bffd97";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/D7E4-7CBE";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    "/swap" = {
      device = "/dev/disk/by-uuid/8460766a-baec-49ac-89ea-156c59bffd97";
      fsType = "btrfs";
      options = [
        "subvol=@swap"
        "noatime"
      ];
    };
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16 * 1024; # Creates an 16GB swap file
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
