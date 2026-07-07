{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = {
    disk = {
      ata-ST1000DM003-1SB102_Z9A9TC2K = {
        type = "disk";
        device = "/dev/disk/by-id/wwn-0x5000c500a1c2787e";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00"; # ESP 类型
              size = "500M";
              label = "EFI system partition";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/efi";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };

            XBOOTLDR = {
              type = "EA00"; # XBOOTLDR 类型
              size = "8G";
              label = "extended boot loader partition";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };

            ZramWriteback = {
              type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4"; # Linux 文件系统
              size = "16G";
              label = "zramWriteback";
            };

            LinuxSystemPartition = {
              type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4"; # Linux 文件系统
              size = "100%";
              label = "Linux system partition";
              content = {
                type = "btrfs";
                subvolumes = {
                  "nixos/@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "nixos/@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "nixos/@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "nixos/@swap" = {
                    mountpoint = "/var/lib/swap";
                    mountOptions = [
                      "noatime"
                      "nodatacow"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
