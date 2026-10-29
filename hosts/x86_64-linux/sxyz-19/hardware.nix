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
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.zpool=z3fold"
      "zswap.max_pool_percent=20"
      "zswap.shrinker_enabled=1"
    ];
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  networking = {
    useDHCP = false;
    interfaces = {
      enp2s0 = {
        useDHCP = false;
        ip4 = [
          {
            address = "10.176.20.17";
            prefixLength = 24;
          }
        ];
      };
    };
    defaultGateway = "10.176.20.1";
    nameservers = [
      "8.8.8.8"
      "114.114.115.115"
    ];
  };
}
