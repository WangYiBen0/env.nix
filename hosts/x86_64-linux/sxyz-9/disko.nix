{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00"; # ESP 类型
              size = "500M";
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

            LinuxSystemPartition = {
              type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4"; # Linux 文件系统
              size = "100%";
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
                    mountpoint = "/swap";
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
