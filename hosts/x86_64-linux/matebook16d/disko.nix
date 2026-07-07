{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-WD_PC_SN740_SDDPNQD-1T00-1127_2409EN403992";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00"; # ESP 类型
              content = {
                type = "filesystem";
                format = "vfat";
                device = "/dev/disk/by-uuid/F33D-19C4";
                mountpoint = "/efi";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };

            MSR = {
              type = "E3C9E316-0B5C-4DB8-817D-F92DF00215AE"; # MSR 专用类型
            };

            Windows = {
              type = "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"; # 基本数据分区
            };

            LinuxSystemPartition = {
              type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4"; # Linux 文件系统
              content = {
                type = "btrfs";
                device = "/dev/disk/by-uuid/76ff1ed4-5cca-473e-8707-7ec3ef6c3c4a";
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
                    mountpoint = "/swap";
                    mountOptions = [
                      "noatime"
                      "nodatacow"
                    ];
                  };
                };
              };
            };

            XBOOTLDR = {
              type = "EA00"; # XBOOTLDR 类型
              content = {
                type = "filesystem";
                format = "vfat";
                device = "/dev/disk/by-uuid/B380-E5B9";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
          };
        };
      };
    };
  };
}
