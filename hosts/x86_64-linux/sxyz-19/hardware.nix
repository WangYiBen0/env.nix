{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

# Lenovo QiTian A7400-N000: i5-6500 (Skylake-S, HD 530), 8 GiB RAM, a single
# ST1000DM003 SATA HDD (sda: Windows on 1/2, NixOS on 3/4), RTL8111 NIC and
# an RTS5229 card reader. Every choice below follows from the two constraints
# that make this machine feel slow: little RAM, and one spinning disk shared by
# the system, the swapfile and every application.
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
    kernelModules = [
      # exposes the HDD's SMART temperature as a hwmon sensor
      "drivetemp"
    ];
    extraModulePackages = [ ];
    kernelParams = [
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      # zswap only has the zsmalloc backend since z3fold/zbud were removed in
      # 6.15, so the old "zswap.zpool=z3fold" this host used to carry was
      # silently ignored. The pool default (20% of RAM) is what suits 8 GiB.
      "zswap.max_pool_percent=20"
      "zswap.shrinker_enabled=1"
    ];

    kernel.sysctl = {
      # The single most important knob on this machine. The swapfile sits on the
      # same HDD as everything else, so an anonymous page evicted here costs a
      # seek, while dropping clean page cache costs nothing. At the kernel
      # default of 60 (let alone 100, which an earlier revision of this file
      # set) the kernel evicts anon pages that are then read straight back:
      # this host reached 1.2 GiB of SwapCached and 12.9M cumulative swapins
      # with memory pressure PSI around 1%, i.e. pure disk churn. It also paged
      # out fcitx5, which is why typing after an idle period stalled on the
      # first keystroke.
      "vm.swappiness" = 20;

      # The nix store holds 180k entries and every completion, alias and
      # directory listing walks its dentries. The default 100 reclaims that
      # cache as aggressively as file pages, so the next walk pays disk seeks
      # again. Bias reclaim towards page cache and keep inode/dentry cache.
      "vm.vfs_cache_pressure" = 50;
    };
  };

  hardware = {
    # HD 530 hardware video decode/encode through iHD (VAAPI). The 32-bit copy
    # is for Steam/Proton; graphics.enable32Bit is already on in the desktop
    # profile.
    graphics = {
      extraPackages = [ pkgs.intel-media-driver ];
      extraPackages32 = [ pkgs.pkgsi686Linux.intel-media-driver ];
    };

    # Replaces the hand-written /etc/modules-load.d/i2c-dev.conf left behind
    # by the old /etc/nixos configuration, and grants access to the i2c buses
    # (monitor DDC, sensors) without root.
    i2c.enable = true;

    # Skylake needs the intel-ucode blob; the installer's scan module already
    # turns on enableRedistributableFirmware, so follow it rather than
    # hardcoding true.
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  # sda came up with an 8 MiB readahead (8192 KiB) although nothing in this
  # configuration asked for it, and NixOS has no option for readahead anyway.
  # Measured demand reads on this host average ~34 KiB, so an 8 MiB window
  # turns every small read into a sweep of unrelated blocks and evicts useful
  # page cache; that is what made operations over a large directory (the nix
  # store has 180k entries) fall off a cliff. 512 KiB is a sane window for one
  # 7200 rpm disk. The rotational test leaves an SSD alone if one is added.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/read_ahead_kb}="512"
  '';

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16 * 1024;
    }
  ];

  # An old Barracuda that carries both operating systems; smartd stays quiet
  # until SMART starts reporting problems. Its default X11 xmessage channel
  # only fits an X session, which this machine does not run.
  services.smartd = {
    enable = true;
    notifications.x11.enable = false;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking = {
    useDHCP = false;
    interfaces = {
      enp2s0 = {
        useDHCP = false;
        ipv4.addresses = [
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
