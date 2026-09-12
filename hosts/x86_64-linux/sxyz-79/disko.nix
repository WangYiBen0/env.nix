{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = {
    disk = {
      sda = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            windows1 = {
              type = "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7";
              size = "100G";
              uuid = "1d7fe196-6775-4237-921d-fb61c0963a4d";
            };

            windows2 = {
              type = "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7";
              size = "416G";
              uuid = "7bb85316-af86-4dc7-b8b9-adb093ad9810";
            };

            ESP = {
              type = "C12A7328-F81F-11D2-BA4B-00A0C93EC93B";
              size = "4G";
              uuid = "e68cd7b2-3a29-4f46-a46b-f45df60db2aa";
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

            root = {
              type = "0FC63DAF-8483-4772-8E79-3D69D8477DE4";
              size = "100%";
              uuid = "b50b29c7-5409-4838-8ee8-947398d83900";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" ];
                  };
                  "@swap" = {
                    mountpoint = "/swap";
                    mountOptions = [ "noatime" ];
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
