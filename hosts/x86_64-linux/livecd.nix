{
  modulesPath,
  lib,
  pkgs,
  ...
}:
# The rescue/live image, exposed as `nixosConfigurations.livecd` (minted in
# default.nix next to the host directories). A module file rather than a host
# directory because it is a system, not a machine: nothing ever switches to it.
#
#   nix build .#nixosConfigurations.livecd.config.system.build.isoImage
#   nix build .#nixosConfigurations.livecd.config.system.build.vm
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  # Minimal installer plus the tools this fleet's repair jobs need: btrfs and
  # disko to create and seed the /persist subvolume, lsof to find what still
  # holds a mount, rsync to move state off a running system, smart/nvme to see
  # whether the disk is the reason the machine is broken. No desktop — the
  # image is booted to fix a machine, and everything here still fits in RAM.
  environment.systemPackages = with pkgs; [
    btrfs-progs
    disko
    gptfdisk
    parted
    dosfstools
    e2fsprogs
    zstd
    rsync
    pv

    lsof
    tmux
    htop

    jq
    ripgrep
    fd
    file

    smartmontools
    nvme-cli
    usbutils
    pciutils
    ethtool
  ];

  # The CD profile already logs root in on the console with no password, so ssh
  # only matters when the machine has no usable console. Key-only, root-only.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDA6dYfSsjK76zMXmIHrPhI+DBc1n4HkGQAsdb9ekTMw w1ngd1nga5ter@nixos-matebook16d"
  ];

  # Repairing a machine is a flake operation, and this is where it happens.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Shown by the boot menu and by ssh, so it is obvious which system answered.
  networking.hostName = lib.mkDefault "livecd";
  isoImage.edition = lib.mkForce "livecd";

  # The same system booted as a throwaway VM, which is the cheap way to poke at
  # the rescue environment without writing a USB stick. The knobs belong under
  # vmVariant: qemu-vm.nix is only imported into that deferred module (see
  # nixos/modules/virtualisation/build-vm.nix, which aliases system.build.vm to
  # the variant), so `virtualisation.graphics` does not exist in this config.
  virtualisation.vmVariant = {
    virtualisation = {
      graphics = false;
      memorySize = 2048;
      diskSize = 4096;
    };
    boot.kernelParams = [ "console=ttyS0,115200" ];
  };
}
